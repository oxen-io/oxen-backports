#!/bin/bash

set -e
set -x

codename="$1"
arch="$2"

if [ -z "$codename" ] || [ -z "$arch" ]; then
    echo "Invalid usage: must run builds with CODENAME ARCH as arguments" >&2
    false
fi

shopt -s nullglob

apt_get='eatmydata apt-get -o=Dpkg::Use-Pty=0 -q'

declare -A version_suffix=(
    [sid]=''
    [buster]='~deb10'
    [bullseye]='~deb11'
    [bookworm]='~deb12'
    [trixie]='~deb13'
    [xenial]='~ubuntu1604'
    [bionic]='~ubuntu1804'
    [focal]='~ubuntu2004'
    [jammy]='~ubuntu2204'
    [lunar]='~ubuntu2304'
    [mantic]='~ubuntu2310'
    [noble]='~ubuntu2404'
)

export PATH="/usr/lib/ccache:$PATH"
ccache -s

export DEBFULLNAME='Jason Rhinelander'
export DEBEMAIL='jason@oxen.io'

mkdir -p build
cd build

extractpackage() {
    # Extracts a package, updates the changelog, and leaves you inside the package directory.
    # Typically followed by some modifications, and then a buildpackage.  Just use rebuildpackage
    # instead if there are no intermediate steps.
    pkg=$1
    debver=$2
    ver=${debver/-*/}
    codename=$3
    suffix="${4:-~oxen1}${version_suffix[$codename]}"

    $apt_get source "$pkg=$debver"

    cd "$pkg-$ver"
    dch -v "$debver$suffix" -b --allow-lower-version '*~oxen*' -D $codename "Oxen rebuild for $codename"

    if grep -q debhelper-compat debian/control; then
        # If on an older distro we might need to lower the debhelper-compat level if too new for the
        # debhelper in the distro.  This could, in theory, break things in the package build but
        # seems okay for most packages.  For debhelper 12 this is easy:
        $apt_get install -y debhelper
        our_dh=$(dpkg-query --showformat='${Version}' --show debhelper | sed -e 's/\..*//')
        if [ "$our_dh" -eq 12 ]; then
            sed -i -e 's/debhelper-compat (= 13)/debhelper-compat (= 12)/' debian/control
        elif [ "$our_dh" -lt 12 ]; then
            # for 11 we have to put "11" into the debian/compat file and depend on debhelper 11
            # instead of the debhelper-compat virtual package:
            sed -i -e 's/debhelper-compat (= 1[23])/debhelper (>= '$our_dh'~)/' debian/control
            echo $our_dh >debian/compat
        fi
    fi
    # for 11 and earlier we have to change the dependency to debhelper and create the debian/compat file.
}

buildpackage() {
    # Installs deps and builds the package.  Must already be in the source dir, typically from a
    # call to extractpackage.
    cd debian
    eatmydata mk-build-deps -i -r --tool="$apt_get -o Debug::pkgProblemResolver=yes --no-install-recommends -y" control
    cd ..
    eatmydata dpkg-buildpackage -uc -us -b -j${JOBS:-6}
    cd ..
}

rebuildpackage() {
    # Call as: rebuildpackage pkgname 1.2.3-1 $codename
    # Args are:
    # $1 - package name
    # $2 - package version, including debian suffix
    # $3 - codename being built (e.g. "sid", "trixie")
    # $4 - optional oxen suffix version; used "~oxen1" if unspecified.
    #
    # This will increment the changelog to build something like: pkgname-1.2.3-1~oxen1~deb12

    extractpackage "$@"
    buildpackage
}

installdebs() {
    # Call as: installdebs some.deb another.deb ...
    # This installs them properly (i.e. first via dpkg, then fixing up dependencies via apt-get).
    # Does nothing if called with nothing (and so you can use `installdebs whatever*.deb` to have
    # nothing happen if there are no matching debs without having to check first).

    if [ "$#" -eq 0 ]; then
        return
    fi

    dpkg --force-depends -i "$@"
    $apt_get install -f -y
}
