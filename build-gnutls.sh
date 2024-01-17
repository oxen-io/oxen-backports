#!/bin/bash

. common.sh

v=3.8.3-1
oxen='~oxen1'

# If we built nettle, install it
installdebs {libhogweed6,libnettle8,nettle-dev}_*_$arch.deb

$apt_get install -y gettext

extractpackage gnutls28 $v $codename $oxen

if dpkg --compare-versions "$(dpkg-query --showformat='${Version}' --show gettext)" lt 0.20; then
    pwd
    patch -p1 -i ../../patches/gnutls-gettextize.patch
fi

if [ "$codename" == "buster" ]; then
    patch -p1 -i ../../patches/gnutls-pkcs-fix.patch
elif [ "$codename" == "bionic" ]; then
    patch -p1 -i ../../patches/gnutls-pkcs-fix.patch
    patch -p1 -i ../../patches/bionic-p11-kit-hack.patch
    sed -i -e 's/^CONFIGUREARGS = /CONFIGUREARGS = --disable-tests /' debian/rules
    sed -i -e 's/ texlive-plain-generic,/ texlive-plain-generic, texlive-fonts-recommended,/' debian/control
fi

buildpackage
