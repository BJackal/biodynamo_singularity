#!/bin/bash
# -----------------------------------------------------------------------------
#
# Copyright (C) 2021 CERN & University of Surrey for the benefit of the
# BioDynaMo collaboration. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#
# See the LICENSE file distributed with this work for details.
# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# -----------------------------------------------------------------------------

if [[ $# -ne 1 ]]; then
  echo "ERROR: Wrong number of arguments.
Description:
  This script builds ROOT.
  The archive will be stored in BDM_PROJECT_DIR/build/root.tar.gz
Arguments:
  \$1 ROOT version that should be build (e.g. v6-22-00)"
  exit 1
fi

set -e -x

ROOT_VERSION=$1
PYVERS=3.9.1

BDM_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
cd $BDM_PROJECT_DIR

# import util functions
. $BDM_PROJECT_DIR/util/installation/common/util.sh

# archive destination dir
BDM_OS=$(DetectOs)
DEST_DIR=$BDM_PROJECT_DIR/build/build-third-party
mkdir -p $DEST_DIR
EchoNewStep "Start building ROOT $ROOT_VERSION. Result will be stored in $DEST_DIR"
# working dir
WORKING_DIR=~/bdm-build-third-party
mkdir -p $WORKING_DIR
cd $WORKING_DIR

ROOT_INSTALL_DIR=$WORKING_DIR/root-install
if [ -d $ROOT_INSTALL_DIR ]; then
  echo "ERROR: $ROOT_INSTALL_DIR exists already."
  exit 1
fi
mkdir -p $ROOT_INSTALL_DIR

# install prerequisites
. $BDM_PROJECT_DIR/util/build-third-party/third-party-prerequisites.sh

# Get the right ROOT source version, untar creates "root-$ROOT_VERSION"
wget https://root.cern.ch/download/root_v$ROOT_VERSION.source.tar.gz
tar -zxf root_v$ROOT_VERSION.source.tar.gz
cd root-$ROOT_VERSION
ROOTSRC=`pwd`
cd ..

# On macOS use brew's python
brewpy=no
if [[ $(uname -s) == "Darwin" ]]; then
  brewpy=yes
fi

if [ $brewpy == "yes" ]; then
   pyth="$(brew --prefix)/bin/python3"
else
   # Set Python to $PYVERS
   if [[ $(uname -s) == "Darwin" ]]; then
      export PYENV_ROOT=/usr/local/opt/.pyenv
   fi
   eval "$(pyenv init -)"
   pyenv shell $PYVERS
   pyth="`pyenv which python`"
fi

# Make sure numpy is installed for python
#$pyth -m pip install numpy

# unset any env var to local installed libraries
unset XRDSYS
unset RFIO
unset CASTOR
unset FFTW3
unset MONALISA
unset ORACLE
unset PYTHIA6
unset PYTHIA8
unset DAVIX

mkdir build
cd build

if [[ $(uname -s) == "Darwin" ]]; then
   OSXARCH=`arch`
   if [ $OSXARCH == "arm64" ]; then
      cmake -G Ninja \
         -Dmacos_native=YES \
         -Dbuiltin_fftw3=OFF \
         -Dbuiltin_freetype=ON \
         -Dbuiltin_ftgl=ON \
         -Dbuiltin_glew=ON \
         -Dbuiltin_gsl=ON \
         -Dbuiltin_lz4=ON \
         -Dbuiltin_lzma=ON \
         -Dbuiltin_openssl=ON \
         -Dbuiltin_pcre=ON \
         -Dbuiltin_tbb=OFF \
         -Dbuiltin_unuran=ON \
         -Dbuiltin_xxhash=ON \
         -Dbuiltin_zlib=ON \
         -Dbuiltin_zstd=ON \
         -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX=$ROOT_INSTALL_DIR \
         -DCMAKE_CXX_STANDARD=14 \
         -DTBB_ROOT_DIR=$(brew --prefix)
         -DPYTHON_EXECUTABLE="$pyth" \
         $ROOTSRC
   else
      cmake -G Ninja \
         -Dmacos_native=YES \
         -Dbuiltin_fftw3=ON \
         -Dbuiltin_freetype=ON \
         -Dbuiltin_ftgl=ON \
         -Dbuiltin_glew=ON \
         -Dbuiltin_gsl=ON \
         -Dbuiltin_lz4=ON \
         -Dbuiltin_lzma=ON \
         -Dbuiltin_openssl=ON \
         -Dbuiltin_pcre=ON \
         -Dbuiltin_tbb=ON \
         -Dbuiltin_unuran=ON \
         -Dbuiltin_xxhash=ON \
         -Dbuiltin_zlib=ON \
         -Dbuiltin_zstd=ON \
         -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_INSTALL_PREFIX=$ROOT_INSTALL_DIR \
         -DCMAKE_CXX_STANDARD=14 \
         -DPYTHON_EXECUTABLE="$pyth" \
         $ROOTSRC
   fi
else
  # -Droot7=OFF only because centos7 fails on one contruct.
  cmake -G Ninja \
    -Dbuiltin_fftw3=ON \
    -Dbuiltin_freetype=ON \
    -Dbuiltin_ftgl=ON \
    -Dbuiltin_glew=ON \
    -Dbuiltin_gsl=ON \
    -Dbuiltin_lz4=ON \
    -Dbuiltin_lzma=ON \
    -Dbuiltin_openssl=ON \
    -Dbuiltin_pcre=ON \
    -Dbuiltin_tbb=ON \
    -Dbuiltin_unuran=ON \
    -Dbuiltin_xxhash=ON \
    -Dbuiltin_zlib=ON \
    -Dbuiltin_zstd=ON \
    -Droot7=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=$CC \
    -DCMAKE_CXX_COMPILER=$CXX \
    -DCMAKE_INSTALL_PREFIX=$ROOT_INSTALL_DIR \
    -DCMAKE_CXX_STANDARD=14 \
    -DPYTHON_EXECUTABLE="$pyth" \
    $ROOTSRC
fi

ninja install

cd $ROOT_INSTALL_DIR
if [[ $(uname -s) == "Darwin" ]]; then
   RESULT_FILE=root_v${ROOT_VERSION}_python3_${BDM_OS}-${OSXARCH}.tar.gz
else
   RESULT_FILE=root_v${ROOT_VERSION}_python3_${BDM_OS}.tar.gz
fi
tar -zcf ${RESULT_FILE} *

# mv to destination directory
mv ${RESULT_FILE} $DEST_DIR
cd $DEST_DIR
shasum -a256 ${RESULT_FILE} > ${RESULT_FILE}.sha256
