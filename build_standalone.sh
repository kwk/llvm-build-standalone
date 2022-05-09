#!/bin/bash

# This script builds LLVM and Clang in standalone mode that means it first
# builds LLVM and installs it into a specific directory. That directory is then
# used when building Clang which depends on it.

# Enable Error tracing
set -o errtrace

# Print trace for all commands ran before execution
set -x

# Include the Buildbot helper functions
HERE="$(realpath $(dirname $0))"
. ${HERE}/buildbot-helper.sh

# Ensure all commands pass, and not dereferencing unset variables.
set -eu
halt_on_failure

BUILDBOT_ROOT=${BUILDBOT_ROOT:-${HERE}}
REVISION=${BUILDBOT_REVISION:-origin/main}
LLVM_ROOT="${BUILDBOT_ROOT}/llvm-project"

LLVM_INSTALL_DIR=${BUILDBOT_ROOT}/llvm-install/
LLVM_BUILD_DIR=${BUILDBOT_ROOT}/llvm-build/
CLANG_INSTALL_DIR=${BUILDBOT_ROOT}/clang-install/
CLANG_BUILD_DIR=${BUILDBOT_ROOT}/clang-build/
BUILD_TYPE=Release

# Set-up llvm-project
if [ ! -d "${LLVM_ROOT}" ]; then
  build_step "Cloning llvm-project repo"
  git clone --progress https://github.com/llvm/llvm-project.git ${LLVM_ROOT}
fi

build_step "Updating llvm-project repo"
git -C "${LLVM_ROOT}" fetch origin
git -C "${LLVM_ROOT}" reset --hard ${REVISION}

# Clang standalone builds are currently not posible unless this patch is applied
build_step "Patch clang and clang-extra-tools for standalone builds (https://reviews.llvm.org/D120301)"
git -C ${LLVM_ROOT} reset --hard origin/main
git -C ${LLVM_ROOT} am ${HERE}/standalone-build.patch

build_step "Pre-build cleanup"
rm -rf ${LLVM_BUILD_DIR}
rm -rf ${LLVM_INSTALL_DIR}
rm -rf ${CLANG_BUILD_DIR}
rm -rf ${CLANG_INSTALL_DIR}

build_step "Configuring llvm"

cmake \
    -S ${LLVM_ROOT}/llvm \
    -B ${LLVM_BUILD_DIR} \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DLLVM_BUILD_LLVM_DYLIB=ON \
    -DLLVM_LINK_LLVM_DYLIB=ON \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INSTALL_UTILS=ON \
    -DCMAKE_INSTALL_PREFIX=${LLVM_INSTALL_DIR}

build_step "Building llvm"
cmake --build ${LLVM_BUILD_DIR}

build_step "Installing llvm"
rm -rf "${LLVM_INSTALL_DIR}"
cmake --install ${LLVM_BUILD_DIR}

# This is meant to extinguish any dependency on files being taken
# from the llvm build dir when building clang.
build_step "Removing llvm build directory"
rm -rf "${LLVM_BUILD_DIR}"

build_step "Configuring clang"

# TODO: Is this really needed?
export LLVM_DIR=${LLVM_INSTALL_DIR}/lib64/cmake/llvm

# help find llvm-config that we just build with build-llvm.sh
# PATH="${LLVM_INSTALL_DIR}/bin;$PATH"

cmake \
    -S ${LLVM_ROOT}/clang \
    -B ${CLANG_BUILD_DIR} \
    -G Ninja \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DCLANG_LINK_CLANG_DYLIB=ON \
    -DCLANG_INCLUDE_TESTS=ON \
    -DLLVM_EXTERNAL_LIT=/usr/bin/lit \
    -DCMAKE_INSTALL_PREFIX=${CLANG_INSTALL_DIR} \
    -DLLVM_ROOT=${LLVM_INSTALL_DIR}

build_step "Building clang"
LD_LIBRARY_PATH="${LLVM_INSTALL_DIR}/lib64" cmake --build ${CLANG_BUILD_DIR}

build_step "Installing clang"
rm -rf ${CLANG_INSTALL_DIR}
cmake --install ${CLANG_BUILD_DIR}

exit 0
