#!/bin/bash

CLFSUSER=clfs
CLFSUSERPASSWD=Clfsclfs

#passwd ${CLFSUSER}

echo "${CLFSUSER}:${CLFSUSERPASSWD}" | chpasswd

su - clfs