#!/bin/bash

. common.sh

v=3.8.1-2
oxen='~oxen1'

check_already_in_repo nettle-dev $v $codename $oxen

rebuildpackage nettle $v $codename $oxen
