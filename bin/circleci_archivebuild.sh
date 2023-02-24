#!/bin/bash
# Copied this build logic directly from the original Jenkins logic.
# This script gathers all the build outputs and stuffs them into
# the folder specified by DEVICE (first script parameter)
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

DEVICE=$1
GIT_REVISION="${CIRCLE_SHA1:-$(git rev-parse HEAD)}"
BUILD_NUM="${CIRCLE_BUILD_NUM}"

VERSION=$(cat ./version)
eval $(grep CONFIG_TARGET_BOARD= openwrt/.config)
echo "Config target board = $CONFIG_TARGET_BOARD"
eval $(grep CONFIG_TARGET_SUBTARGET= openwrt/.config)
echo "Config target subtarget = $CONFIG_TARGET_SUBTARGET"
eval $(grep CONFIG_ARCH= openwrt/.config)
echo "Config architecture = $CONFIG_ARCH"
eval $(grep CONFIG_CPU_TYPE= openwrt/.config)
echo "Config CPU type = $CONFIG_CPU_TYPE"
eval $(grep CONFIG_LIBC= openwrt/.config)
echo "Config libc = $CONFIG_LIBC"
TARGET_BIN_DIR=openwrt/bin/targets/${CONFIG_TARGET_BOARD}/${CONFIG_TARGET_SUBTARGET}
TARGET_ROOT_DIR=openwrt/build_dir/target-${CONFIG_ARCH}_${CONFIG_CPU_TYPE}_${CONFIG_LIBC}*/root-${CONFIG_TARGET_BOARD}
cp $TARGET_BIN_DIR/*factory* $DEVICE/$DEVICE-factory-$VERSION.bin || cp $TARGET_BIN_DIR/*sysupgrade* $DEVICE/$DEVICE-factory-$VERSION.bin
cp $TARGET_BIN_DIR/*sysupgrade* $DEVICE/$DEVICE-sysupgrade-$VERSION.bin
cp $TARGET_BIN_DIR/*.manifest $DEVICE/$DEVICE-$VERSION.manifest
cp $TARGET_BIN_DIR/*.buildinfo $DEVICE
cp $TARGET_BIN_DIR/sha256sums $DEVICE
cp $TARGET_ROOT_DIR/etc/unum/release_properties.json $DEVICE