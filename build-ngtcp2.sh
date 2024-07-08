#!/bin/bash

. common.sh

v=1.5.0-2
nghttp3_v=1.3.0-2
oxen='~oxen1'

check_already_in_repo libngtcp2-dev $v $codename $oxen

# If we have dependency backport debs sitting here from previous steps then install them first
installdebs {libhogweed6,libnettle8,nettle-dev,libgnutls28-dev,libgnutls30,libgnutls-dane0,libgnutls-openssl27}_*_$arch.deb

rebuildpackage nghttp3 $nghttp3_v $codename $oxen

installdebs libnghttp3{-dev,-9}_$nghttp3_v$oxen${version_suffix[$codename]}_$arch.deb

extractpackage ngtcp2 $v $codename $oxen
if dpkg --compare-versions "$(dpkg-query --showformat='${Version}' --show g++)" lt 4:11; then
    pwd
    patch -p1 -i ../../patches/ngtcp2-disable-client-server.patch
fi
buildpackage
