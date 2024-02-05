#!/bin/bash

. common.sh

v=1.0.19-1
oxen='~oxen1'

check_already_in_repo libsodium-dev $v $codename $oxen

rebuildpackage libsodium $v $codename $oxen
