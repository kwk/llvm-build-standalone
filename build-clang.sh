#!/bin/bash

set -ex

_prefix=$PWD/clang-install/
llvm_install_dir=$PWD/llvm-install
source config.sh

# help find llvm-config that we just build with build-llvm.sh
# PATH="${llvm_install_dir}/bin;$PATH"

cmake \
    -S ../clang \
    -B clang-build \
    -G Ninja \
    -DLLVM_CMAKE_DIR=${llvm_install_dir}/lib64/cmake/llvm/ \
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
    -DCMAKE_BUILD_TYPE=${build_type} \
    -DPYTHON_EXECUTABLE=${_bindir}/python3 \
    -DCMAKE_SKIP_RPATH:BOOL=ON \
    -DLLVM_ENABLE_PLUGINS:BOOL=ON \
    -DCLANG_ENABLE_PLUGINS:BOOL=ON \
    -DCLANG_INCLUDE_TESTS:BOOL=ON \
    -DLLVM_EXTERNAL_CLANG_TOOLS_EXTRA_SOURCE_DIR=../clang-tools-extra \
    -DLLVM_EXTERNAL_LIT=/usr/bin/lit \
    -DLLVM_MAIN_SRC_DIR=${_datarootdir}/llvm/src \
    -DLLVM_LIBDIR_SUFFIX=64 \
    -DLLVM_TABLEGEN_EXE:FILEPATH=${llvm_install_dir}/bin/llvm-tblgen \
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

LD_LIBRARY_PATH="${LD_LIBRARY_PATH};${llvm_install_dir}/lib64" cmake --build clang-build
cmake --install clang-build