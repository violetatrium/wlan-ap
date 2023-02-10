FROM docker.io/cimg/base:2023.02 AS base
# Switch to root so we can do installs
USER root
RUN apt-get update && apt install --no-install-recommends build-essential clang flex bison g++ gawk gcc-multilib gettext git libncurses5-dev libssl-dev python3-distutils rsync unzip zlib1g-dev file wget python3-setuptools python3-pip && apt-get clean
RUN pip3 install pyyaml
USER 1001
RUN git config --global user.email "git@minim.com"
RUN git config --global user.name "Minim"