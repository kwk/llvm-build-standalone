#!/bin/bash

# This script builds LLVM and Clang in standalone mode that means it first
# builds LLVM and installs it into a specific directory. That directory is then
# used when building Clang which depends on it. The configration is currently
# very similar to the one being used to generate LLVM daily Fedora snapshots.
# (See: https://copr.fedorainfracloud.org/coprs/g/fedora-llvm-team/llvm-snapshots/)

# Enable Error tracing
set -o errtrace

# Print trace for all commands ran before execution
set -x

# Include the Buildbot helper functions
HERE="$(dirname $0)"
. ${HERE}/buildbot-helper.sh

# Ensure all commands pass, and not dereferencing unset variables.
set -eu
halt_on_failure

BUILDBOT_ROOT=${BUILDBOT_ROOT:-/home/bb-worker/}
REVISION=${BUILDBOT_REVISION:-origin/main}
LLVM_ROOT="${BUILDBOT_ROOT}/llvm-project"

LLVM_INSTALL_DIR=${BUILDBOT_ROOT}/llvm-install/
LLVM_BUILD_DIR=${BUILDBOT_ROOT}/llvm-build/
CLANG_INSTALL_DIR=${BUILDBOT_ROOT}/clang-install/
CLANG_BUILD_DIR=${BUILDBOT_ROOT}/clang-build/
BUILD_TYPE=RelWithDebInfo

# Set-up llvm-project
if [ ! -d "${LLVM_ROOT}" ]; then
  build_step "Cloning llvm-project repo"
  git clone --progress https://github.com/llvm/llvm-project.git ${LLVM_ROOT}
fi

build_step "Updating llvm-project repo"
git -C "${LLVM_ROOT}" fetch origin
git -C "${LLVM_ROOT}" reset --hard ${REVISION}

# See https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/#macros_installation
# for these variable names.

build_step "Configuring llvm"

_lib=lib64
llvm_triple=x86_64-redhat-linux-gnu

_prefix=${LLVM_INSTALL_DIR}
_exec_prefix=${_prefix}
_includedir=${_prefix}/include
_bindir=${_exec_prefix}/bin
_libdir=${_prefix}/${_lib}
_sysconfdir=${_prefix}/etc
_datarootdir=${_prefix}/share
_pkgdocdir=${_prefix}/share/doc/llvm

cmake \
    -S ${LLVM_ROOT}/llvm \
    -B ${LLVM_BUILD_DIR} \
    -G Ninja \
    -DCMAKE_C_FLAGS_RELEASE:STRING=-DNDEBUG \
    -DCMAKE_CXX_FLAGS_RELEASE:STRING=-DNDEBUG \
    -DCMAKE_Fortran_FLAGS_RELEASE:STRING=-DNDEBUG \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_INSTALL_DO_STRIP:BOOL=OFF \
    -DCMAKE_INSTALL_PREFIX:PATH=${_prefix} \
    -DINCLUDE_INSTALL_DIR:PATH=${_includedir} \
    -DLIB_INSTALL_DIR:PATH=${_libdir} \
    -DSYSCONF_INSTALL_DIR:PATH=${_sysconfdir} \
    -DSHARE_INSTALL_PREFIX:PATH=${_datarootdir} \
    -DLIB_SUFFIX=64 \
    -DBUILD_SHARED_LIBS:BOOL=ON \
    -DBUILD_SHARED_LIBS:BOOL=OFF \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DCMAKE_SKIP_RPATH:BOOL=ON \
    -DLLVM_LIBDIR_SUFFIX=64 \
    -DLLVM_TARGETS_TO_BUILD=all \
    -DLLVM_ENABLE_LIBCXX:BOOL=OFF \
    -DLLVM_ENABLE_ZLIB:BOOL=ON \
    -DLLVM_ENABLE_FFI:BOOL=ON \
    -DLLVM_ENABLE_RTTI:BOOL=ON \
    -DLLVM_USE_PERF:BOOL=ON \
    -DLLVM_BINUTILS_INCDIR=${_includedir} \
    -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=AVR \
    -DLLVM_BUILD_RUNTIME:BOOL=ON \
    -DLLVM_INCLUDE_TOOLS:BOOL=ON \
    -DLLVM_BUILD_TOOLS:BOOL=ON \
    -DLLVM_INCLUDE_TESTS:BOOL=ON \
    -DLLVM_BUILD_TESTS:BOOL=ON \
    -DLLVM_LIT_EXTRA_ARGS=-v \
    -DLLVM_INCLUDE_EXAMPLES:BOOL=ON \
    -DLLVM_BUILD_EXAMPLES:BOOL=OFF \
    -DLLVM_INCLUDE_UTILS:BOOL=ON \
    -DLLVM_INSTALL_UTILS:BOOL=ON \
    -DLLVM_UTILS_INSTALL_DIR:PATH=${_bindir} \
    -DLLVM_TOOLS_INSTALL_DIR:PATH=bin \
    -DLLVM_INCLUDE_DOCS:BOOL=ON \
    -DLLVM_BUILD_DOCS:BOOL=ON \
    -DLLVM_ENABLE_SPHINX:BOOL=ON \
    -DLLVM_ENABLE_DOXYGEN:BOOL=OFF \
    -DLLVM_BUILD_LLVM_DYLIB:BOOL=ON \
    -DLLVM_LINK_LLVM_DYLIB:BOOL=ON \
    -DLLVM_BUILD_EXTERNAL_COMPILER_RT:BOOL=ON \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY:BOOL=OFF \
    -DLLVM_DEFAULT_TARGET_TRIPLE=${llvm_triple} \
    -DSPHINX_WARNINGS_AS_ERRORS=OFF \
    -DLLVM_INSTALL_SPHINX_HTML_DIR=${_pkgdocdir}/html \
    -DSPHINX_EXECUTABLE=/usr/bin/sphinx-build-3 \

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

_prefix=${CLANG_INSTALL_DIR}
_exec_prefix=${_prefix}
_includedir=${_prefix}/include
_bindir=${_exec_prefix}/bin
_libdir=${_prefix}/${_lib}
_sysconfdir=${_prefix}/etc
_datarootdir=${_prefix}/share
_pkgdocdir=${_prefix}/share/doc/llvm

# help find llvm-config that we just build with build-llvm.sh
# PATH="${LLVM_INSTALL_DIR}/bin;$PATH"

cmake \
    -S ${LLVM_ROOT}/clang \
    -B ${CLANG_BUILD_DIR} \
    -G Ninja \
    -DLLVM_CMAKE_DIR=${LLVM_INSTALL_DIR}/lib64/cmake/llvm/ \
    -DCMAKE_C_FLAGS_RELEASE:STRING=-DNDEBUG \
    -DCMAKE_CXX_FLAGS_RELEASE:STRING=-DNDEBUG \
    -DCMAKE_Fortran_FLAGS_RELEASE:STRING=-DNDEBUG \
    -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON \
    -DCMAKE_INSTALL_DO_STRIP:BOOL=OFF \
    -DCMAKE_INSTALL_PREFIX:PATH=${_prefix} \
    -DINCLUDE_INSTALL_DIR:PATH=${_includedir} \
    -DLIB_INSTALL_DIR:PATH=${_libdir} \
    -DSYSCONF_INSTALL_DIR:PATH=${_sysconfdir} \
    -DSHARE_INSTALL_PREFIX:PATH=${_datarootdir} \
    -DLIB_SUFFIX=64 \
    -DBUILD_SHARED_LIBS:BOOL=ON \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DLLVM_LINK_LLVM_DYLIB:BOOL=ON \
    -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
    -DPYTHON_EXECUTABLE=/usr/bin/python3 \
    -DCMAKE_SKIP_RPATH:BOOL=ON \
    -DLLVM_ENABLE_PLUGINS:BOOL=ON \
    -DCLANG_ENABLE_PLUGINS:BOOL=ON \
    -DCLANG_INCLUDE_TESTS:BOOL=ON \
    -DLLVM_EXTERNAL_CLANG_TOOLS_EXTRA_SOURCE_DIR=${LLVM_ROOT}/clang-tools-extra \
    -DLLVM_EXTERNAL_LIT=/usr/bin/lit \
    -DLLVM_MAIN_SRC_DIR=${_datarootdir}/llvm/src \
    -DLLVM_LIBDIR_SUFFIX=64 \
    -DLLVM_TABLEGEN_EXE:FILEPATH=${LLVM_INSTALL_DIR}/bin/llvm-tblgen \
    -DCLANG_ENABLE_ARCMT:BOOL=ON \
    -DCLANG_ENABLE_STATIC_ANALYZER:BOOL=ON \
    -DCLANG_INCLUDE_DOCS:BOOL=ON \
    -DCLANG_PLUGIN_SUPPORT:BOOL=ON \
    -DENABLE_LINKER_BUILD_ID:BOOL=ON \
    -DLLVM_ENABLE_EH=ON \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_BUILD_DOCS=ON \
    -DLLVM_ENABLE_NEW_PASS_MANAGER=ON \
    -DLLVM_ENABLE_SPHINX=ON \
    -DCLANG_LINK_CLANG_DYLIB=ON \
    -DSPHINX_WARNINGS_AS_ERRORS=OFF \
    -DCLANG_BUILD_EXAMPLES:BOOL=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DCLANG_DEFAULT_UNWINDLIB=libgcc \
    -DCMAKE_INSTALL_LIBDIR=${_libdir}

build_step "Building clang"
LD_LIBRARY_PATH="${LD_LIBRARY_PATH};${LLVM_INSTALL_DIR}/lib64" cmake --build ${CLANG_BUILD_DIR}

build_step "Installing clang"
rm -rf ${CLANG_INSTALL_DIR}
cmake --install ${CLANG_INSTALL_DIR}

exit 0