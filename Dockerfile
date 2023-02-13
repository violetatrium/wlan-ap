FROM docker.io/ubuntu:20.04 AS base
# Switch to root so we can do installs
RUN sudo apt-get update && sudo apt install --no-install-recommends build-essential ccache ecj fastjar file g++ gawk gettext git java-propose-classpath libelf-dev libncurses5-dev libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget python3-distutils python3-setuptools python3-dev rsync subversion swig time xsltproc zlib1g-dev clang python3-pip && sudo apt-get clean
RUN pip3 install pyyaml
RUN git config --global user.email "git@minim.com"
RUN git config --global user.name "Minim"