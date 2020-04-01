#!/usr/bin/env bash

mkdir ../geocode

QHOME=${QHOME:-~/q}

rlwrap ${QHOME}/m64/q geocode.q "RUN"