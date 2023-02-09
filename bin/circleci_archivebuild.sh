#!/bin/bash
set -o errexit
set -o errtrace
set -o pipefail
set -o nounset

DEVICE=$1
GIT_REVISION="${CIRCLE_SHA1:-$(git rev-parse HEAD)}"

VERSION=$(cat base_version)-$GIT_REVISION
eval $(grep CONFIG_TARGET_BOARD= openwrt/.config)
eval $(grep CONFIG_TARGET_SUBTARGET= openwrt/.config)
eval $(grep CONFIG_ARCH= openwrt/.config)
eval $(grep CONFIG_CPU_TYPE= openwrt/.config)
eval $(grep CONFIG_LIBC= openwrt/.config)
TARGET_BIN_DIR=openwrt/bin/targets/$CONFIG_TARGET_BOARD/$CONFIG_TARGET_SUBTARGET
TARGET_ROOT_DIR=openwrt/build_dir/target-$CONFIG_ARCH_$CONFIG_CPU_TYPE_$CONFIG_LIBC*/root-$CONFIG_TARGET_BOARD
cp $TARGET_BIN_DIR/*factory* $DEVICE/$DEVICE-factory-$VERSION.bin || cp $TARGET_BIN_DIR/*sysupgrade* $DEVICE/$DEVICE-factory-$VERSION.bin
cp $TARGET_BIN_DIR/*sysupgrade* $DEVICE/$DEVICE-sysupgrade-$VERSION.bin
cp $TARGET_BIN_DIR/*.manifest $DEVICE/$DEVICE-$VERSION.manifest
cp $TARGET_BIN_DIR/*.buildinfo $DEVICE
cp $TARGET_BIN_DIR/sha256sums $DEVICE
cp $TARGET_ROOT_DIR/etc/unum/release_properties.json $DEVICE