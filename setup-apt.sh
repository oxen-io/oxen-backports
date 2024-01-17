#!/bin/bash

set -e
set -x

DISTRO="$1"
CODENAME="$2"

if [ -z "$DISTRO" ] || [ -z "$CODENAME" ]; then
    echo "Usage: $0 DISTRO CODENAME [SRCDIST...], e.g.  $0 ubuntu focal  or  $0 debian bookworm" >&2
    false
fi

shift 2

# Can be passed debian repos to add deb-src lines to apt sources; typically one of: `sid`,
# `bookworm`, `sid experimental`.  Optional, but used anywhere we want to rebuild an upstream debian
# package for another distro/release.
SRC_DIST="$@"

apt-get -o=Dpkg::Use-Pty=0 -q update
apt-get -o=Dpkg::Use-Pty=0 -q install -y eatmydata

cp deb.oxen.io.gpg /etc/apt/trusted.gpg.d

>/etc/apt/sources.list.d/oxen-backports.list
for p in '' '/beta' '/staging'; do
    echo "deb http://deb.oxen.io$p $CODENAME main" >>/etc/apt/sources.list.d/oxen-backports.list
done

pkgs="ccache openssh-client devscripts"

add_debian_key=
for SRC_DIST in "$@"; do
    echo "deb-src http://deb.debian.org/debian $SRC_DIST main" >>/etc/apt/sources.list.d/oxen-backports.list
    if [ "$DISTRO" != "debian" ]; then
        add_debian_key=1
    fi
done
if [ -n "$add_debian_key" ]; then
    cp debian-archive-bookworm-automatic.gpg /etc/apt/trusted.gpg.d
fi

eatmydata apt-get -o=Dpkg::Use-Pty=0 -q update
eatmydata apt-get -o=Dpkg::Use-Pty=0 -q install -y $pkgs
