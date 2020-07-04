#!/bin/bash

PLATFORM=$1
DISTRO=$2


if [[ "${PLATFORM}" == "pi" ]]; then
    OS="raspbian"
    ARCH="arm"
    PACKAGE_ARCH="armhf"
fi

apt -y install libusb-1.0-0-dev libjpeg8-dev

PACKAGE_NAME=flirone-driver

TMPDIR=/tmp/${PACKAGE_NAME}-installdir

rm -rf ${TMPDIR}/*

mkdir -p ${TMPDIR}/usr/local/bin || exit 1
mkdir -p ${TMPDIR}/usr/local/share/flirone-driver || exit 1


pushd flir8p1-gpl
make clean || exit 1
make || exit 1
chmod +x flir8p1 || exit 1
cp -a flir8p1 ${TMPDIR}/usr/local/bin/ || exit 1
cp -a *.raw ${TMPDIR}/usr/local/share/flirone-driver/ || exit 1
popd

VERSION=$(git describe)

rm ${PACKAGE_NAME}_${VERSION//v}_${PACKAGE_ARCH}.deb > /dev/null 2>&1

fpm -a ${PACKAGE_ARCH} -s dir -t deb -n ${PACKAGE_NAME} -v ${VERSION//v} -C ${TMPDIR} \
  -p ${PACKAGE_NAME}_VERSION_ARCH.deb \
  -d "libusb-1.0-0 >= 1.0" || exit 1


#
# Only push to cloudsmith for tags. If you don't want something to be pushed to the repo, 
# don't create a tag. You can build packages and test them locally without tagging.
#
git describe --exact-match HEAD > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
    echo "Pushing package to OpenHD repository"
    cloudsmith push deb openhd/openhd/${OS}/${DISTRO} ${PACKAGE_NAME}_${VERSION//v}_${PACKAGE_ARCH}.deb
else
    echo "Not a tagged release, skipping push to OpenHD repository"
fi
