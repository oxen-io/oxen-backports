#!/bin/bash

. common.sh

v=1.0.19-1
oxen='~oxen1'

rebuildpackage libsodium $v $codename $oxen
