#!/bin/bash

. common.sh

v=3.9.1-2
oxen='~oxen2'

check_already_in_repo nettle-dev $v $codename $oxen

rebuildpackage nettle $v $codename $oxen
