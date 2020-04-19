#!/usr/bin/env bash

mkdir -p ../geocode

QHOME=${QHOME:-~/q}

rlwrap "${QHOME}"/m64/q ../q/geocode.q "GEOCODE_PRE"