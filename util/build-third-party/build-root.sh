#!/bin/bash
# -----------------------------------------------------------------------------
#
# Copyright (C) The BioDynaMo Project.
# All Rights Reserved.
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
  \$1 ROOT version that should be build"
  exit 1
fi

set -e -x

ROOT_VERSION=$1
BDM_PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.."
cd $BDM_PROJECT_DIR

# import util functions
. $BDM_PROJECT_DIR/util/installation/common/util.sh

# archive destination dir
DEST_DIR=$BDM_PROJECT_DIR/build
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

git clone https://github.com/root-project/root.git

cd root
git checkout $ROOT_VERSION
git status
cd ..

mkdir build
cd build
cmake \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=$CC \
  -DCMAKE_CXX_COMPILER=$CXX \
  -DCMAKE_INSTALL_PREFIX=$ROOT_INSTALL_DIR \
  -Dcxx14=on \
  ../root/
make -j$(CPUCount) install

cd $ROOT_INSTALL_DIR
tar -zcf root.tar.gz *

# mv to destination directory
mv root.tar.gz $DEST_DIR
