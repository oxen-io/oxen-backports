#!/bin/bash

. common.sh

v=1.1.0-1
oxen='~oxen2'

check_already_in_repo libngtcp2-dev $v $codename $oxen

# If we have dependency backport debs sitting here from previous steps then install them first
installdebs {libhogweed6,libnettle8,nettle-dev,libgnutls28-dev,libgnutls30,libgnutls-dane0,libgnutls-openssl27}_*_$arch.deb

rebuildpackage nghttp3 $v $codename $oxen

installdebs libnghttp3{-dev,-9}_$v$oxen${version_suffix[$codename]}_$arch.deb

extractpackage ngtcp2 $v $codename $oxen
if dpkg --compare-versions "$(dpkg-query --showformat='${Version}' --show g++)" lt 4:11; then
    pwd
    patch -p1 -i ../../patches/ngtcp2-disable-client-server.patch
fi
buildpackage
