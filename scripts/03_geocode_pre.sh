#!/usr/bin/env bash

mkdir ../geocode

QHOME=${QHOME:-~/q}

rlwrap "${QHOME}"/m64/q ../q/geocode.q "RUN"