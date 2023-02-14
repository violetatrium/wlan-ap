FROM docker.io/ubuntu:20.04 AS base
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt install --no-install-recommends -y build-essential ccache ecj fastjar file g++ gawk gettext git java-propose-classpath libelf-dev libncurses5-dev libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget python3-distutils python3-setuptools python3-dev rsync subversion swig time xsltproc zlib1g-dev clang python3-pip
RUN apt-get clean
RUN pip3 install pyyaml
RUN git config --global user.email "git@minim.com"
RUN git config --global user.name "Minim"

# Change to a non-root user.
ARG user=cibuild
ARG group=builders
ARG uid=1000
ARG gid=1000
RUN groupadd -g ${gid} ${group}
RUN useradd -u ${uid} -g ${group} -s /bin/sh -m ${user}
USER ${uid}:${gid}
