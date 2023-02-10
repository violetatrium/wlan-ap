#!/bin/bash
# Copied/edited from RetroElk
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

AWS_REPOSITORY_BASE="674914898519.dkr.ecr.us-east-1.amazonaws.com"
REPOSITORY_NAME="violetatrium/wlan-ap"

GIT_REVISION="${CIRCLE_SHA1:-$(git rev-parse HEAD)}"

# These are populated by the authenticate_ecr() method and are required for the
# tag checks
AWS_REPOSITORY_USER=""
AWS_REPOSITORY_PASS=""

function error_handler() {
  echo "Error occurred in ${3} executing line ${1} with status code ${2}"
  echo "The pipe status values were: ${4}"
}

trap 'error_handler ${LINENO} $? "$(basename ${BASH_SOURCE[0]})" "${PIPESTATUS[*]}"' ERR

function podman_available() {
  if which podman &> /dev/null; then
    return 0;
  else
    return 1;
  fi
}

function authenticate_ecr() {
  local login_cmd=$(aws ecr get-login --region us-east-1 --no-include-email)

  login_cmd=$(echo $login_cmd | docker)

  AWS_REPOSITORY_USER="$(echo $login_cmd | cut -d ' ' -f 4)"
  AWS_REPOSITORY_PASS="$(echo $login_cmd | cut -d ' ' -f 6)"

  eval $login_cmd &> /dev/null
}

function calculate_content_hash() {
  # The spec_integration/factories is actually a symlink to a directory, which
  # can't be hashed and thus is filtered out.
  git ls-files \
    | grep -v 'spec_integration/factories' \
    | sort \
    | xargs sha1sum \
    | sha1sum \
    | awk '{ print $1 }'
}

function tag_exists() {
  local tag="$1"

  curl -sS --head --fail -u "${AWS_REPOSITORY_USER}:${AWS_REPOSITORY_PASS}" https://${AWS_REPOSITORY_BASE}/v2/${REPOSITORY_NAME}/manifests/${tag} &> /dev/null
}

if podman_available; then
  alias docker=podman
fi

echo 'Authenticating to ECR...'
authenticate_ecr

echo 'Check for production version...'
if tag_exists prod-${GIT_REVISION}; then
  echo "Current git revision '${GIT_REVISION}' exists as a fully tested image, tests aren't needed."
  echo "true" > tested
  exit 0
fi

GIT_REVISION_NAME="${AWS_REPOSITORY_BASE}/${REPOSITORY_NAME}:ci-rev-${GIT_REVISION}"

echo 'Checking for git revision tag...'
if tag_exists ci-rev-${GIT_REVISION}; then
  echo "Current git revision '${GIT_REVISION}' exists as a temporary CI image"

  docker pull ${GIT_REVISION_NAME}
  DATA_CONTAINER=$(docker create ${GIT_REVISION_NAME})
  docker cp ${DATA_CONTAINER}:/usr/src/app/tested ./tested || true
  
  exit 0
fi

echo 'Calculating content hash...'
content_hash=$(calculate_content_hash)
echo "Repository checkout currently has a content hash of: '${content_hash}'"

CONTENT_REVISION_NAME="${AWS_REPOSITORY_BASE}/${REPOSITORY_NAME}:ci-sha-${content_hash}"

echo 'Check for content hash tag...'
if tag_exists ci-sha-${content_hash}; then
  echo "Found a matching content hash in repository..."
  echo "Retagging content hash with new git revision..."

  docker pull ${CONTENT_REVISION_NAME}
  docker tag ${CONTENT_REVISION_NAME} ${GIT_REVISION_NAME}
  docker push ${GIT_REVISION_NAME}

  exit 0
fi

echo 'Unable to find existing tagged image, building a new one...'

# The image doesn't exist anywhere, build it from scratch and push the appropriate tags

docker build -t ${CONTENT_REVISION_NAME} -f Dockerfile . --build-arg MAXMIND_LICENSE_KEY=$MAXMIND_LICENSE_KEY

echo 'Pushing image and content tag...'
docker push ${CONTENT_REVISION_NAME}

echo 'Pushing git revision tag...'
docker tag ${CONTENT_REVISION_NAME} ${GIT_REVISION_NAME}
docker push ${GIT_REVISION_NAME}
  
echo 'New image pushed'
