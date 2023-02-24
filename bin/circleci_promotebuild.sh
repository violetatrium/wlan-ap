#!/bin/bash -x
# Edited this script from the violetatrium/embedded-tools repo. Removed any non-required logic.
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

DEVICE=$1
DEFAULT_BRANCH=$2

VERSION=$(cat ./version)
eval $(grep CONFIG_VERSION_PRODUCT= ${DEVICE}_config/openwrt/.config)
WLANAP_SHA=$(git rev-parse --verify HEAD)
AGENT_SHA=$(grep PKG_SOURCE_VERSION ${DEVICE}_config/openwrt/feeds/minim/unum/Makefile | cut -d '=' -f 2);
HARDWARE_ID="${CONFIG_VERSION_PRODUCT}_firmware"
FIRMWARE_VERSION="v$VERSION"
UPGRADE_FILE=$DEVICE/$DEVICE-sysupgrade-$VERSION.bin
RELEASE_PROP=$DEVICE/release_properties.json
PROVISION_FILE=$DEVICE/$DEVICE-factory-$VERSION.bin
REVISIONS=wlan-ap:${WLANAP_SHA:0:8}/unum-sdk:${AGENT_SHA:0:8}

# RELEASES_PASSWORD is pulled from the circleci context.
echo $HARDWARE_ID
echo $FIRMWARE_VERSION
echo $UPGRADE_FILE
echo $RELEASE_PROP
echo $PROVISION_FILE
echo $REVISIONS

username="circleci-build"
author="circleci"

server="releases.minim.co"
# make it use the server on staging if the branch is not whichever branch is "master"
# Change the grep command if we want to set a different branch as "master"
if [ ! $(git rev-parse --abbrev-ref HEAD | grep -q $DEFAULT_BRANCH) ]; then
  server="releases.stg-kcmh-a-1.minim.co"
fi 

SYSUPGRADE=
if [ -f $UPGRADE_FILE ]; then
SYSUPGRADE="--form release[sysupgrade_image]=@$UPGRADE_FILE"
fi

RELEASE_PROPS=
if [ -f "$RELEASE_PROP" ]; then
  RELEASE_PROPS="--form release[properties]=@$RELEASE_PROP"
fi

file_path="$PROVISION_FILE"
git_sha="${REVISIONS-nosha}"
if [ ! -f "$file_path" ]; then
  echo "No factory firmware file <$file_path>"
  exit 2
fi

endpoint="https://$server/release_server/releases"
# Temporarily turn off shell history here for password security
set +o history
curl --retry 5 --retry-delay 10 -v --url "$endpoint" --fail --user "$username:$RELEASES_PASSWORD" $SYSUPGRADE $RELEASE_PROPS --form "release[factory_image]=@$file_path" --form "release[version_string]=$FIRMWARE_VERSION" --form "release[author]=$author" --form "release[git_sha]=$git_sha" --form "release[kind]=$HARDWARE_ID"
set -o history