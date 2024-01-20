#!/usr/bin/env bash

# Script used with Drone CI to upload build artifacts (because specifying all this in
# .drone.jsonnet is too painful).



set -o errexit

if [ -z "$SSH_KEY" ]; then
    echo -e "\n\n\n\e[31;1mUnable to upload artifact: SSH_KEY not set\e[0m"
    # Just warn but don't fail, so that this doesn't trigger a build failure for untrusted builds
    exit 0
fi

echo "$SSH_KEY" >ssh_key

set -o xtrace  # Don't start tracing until *after* we write the ssh key

chmod 600 ssh_key

distro="${1/\//-}"
codename="${distro/*-}"
debarch="$2"

if [ -z "$distro" ] || [ -z "$debarch" ]; then
    echo "Usage: $0 DISTRO DEBARCH" >&2
    false
fi

base="deb-$codename-$(date --date=@$DRONE_BUILD_CREATED +%Y%m%dT%H%M%SZ)-${DRONE_COMMIT:0:9}"

br="${DRONE_BRANCH// /_}"
br="${br//\//-}"
upload_to="builds.lokinet.dev/${DRONE_REPO// /_}/$br/$distro/$base"

shopt -s nullglob

put=
debs=(build/*_${debarch}.deb)

if [ "$debarch" = "amd64" ]; then
    debs+=(build/*_all.deb)
fi

if [ "${#debs[@]}" -eq 0 ]; then
    echo -e "\n\n\n\n\e[31;1mError: found no debs to upload!\e[0m\n\n\n"
    false
fi

for deb in "${debs[@]}"; do
    put+=$'\n'"put $deb $upload_to"

    echo -e "\n\n\e[35;1m$deb contents:\e[0m"
    dpkg-deb --contents $deb
done

# sftp doesn't have any equivalent to mkdir -p, so we have to split the above up into a chain of
# -mkdir a/, -mkdir a/b/, -mkdir a/b/c/, ... commands.  The leading `-` allows the command to fail
# without error.
upload_dirs=(${upload_to//\// })
mkdirs=
dir_tmp=""
for p in "${upload_dirs[@]}"; do
    dir_tmp="$dir_tmp$p/"
    mkdirs="$mkdirs
-mkdir $dir_tmp"
done

sftp -i ssh_key -b - -o StrictHostKeyChecking=off drone@builds.lokinet.dev <<SFTP
$mkdirs
$put
SFTP

set +o xtrace

echo -e "\n\n\n\n\e[32;1mUploaded to https://${upload_to}\e[0m\n\n\n"

