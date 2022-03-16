#!/bin/bash

set -ex

# See https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/#macros_installation
# for these variable names.

_lib=lib64
llvm_triple=x86_64-redhat-linux-gnu
build_type=RelWithDebInfo

_prefix=$PWD/llvm-install/
_exec_prefix=${_prefix}
_includedir=${_prefix}/include
_bindir=${_exec_prefix}/bin
_libdir=${_prefix}/${_lib}
_sysconfdir=${_prefix}/etc
_datarootdir=${_prefix}/share
_pkgdocdir=${_prefix}/share/doc/llvm

echo @@@BUILD_STEP configuring llvm@@@
/usr/bin/cmake \
    -S ../llvm \
    -B llvm-build \
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
    -DCMAKE_BUILD_TYPE=${build_type} \
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
    -DCMAKE_INSTALL_PREFIX=${_prefix} \
    -DLLVM_INSTALL_SPHINX_HTML_DIR=${_pkgdocdir}/html \
    -DSPHINX_EXECUTABLE=/usr/bin/sphinx-build-3 \
    || echo @@@STEP_FAILURE@@@

echo @@@BUILD_STEP building llvm@@@
cmake --build llvm-build || echo @@@STEP_FAILURE@@@

echo @@@BUILD_STEP installing llvm@@@
cmake --install llvm-build || echo @@@STEP_FAILURE@@@

_prefix=$PWD/clang-install/
llvm_install_dir=$PWD/llvm-install
_exec_prefix=${_prefix}
_includedir=${_prefix}/include
_bindir=${_exec_prefix}/bin
_libdir=${_prefix}/${_lib}
_sysconfdir=${_prefix}/etc
_datarootdir=${_prefix}/share
_pkgdocdir=${_prefix}/share/doc/llvm

# help find llvm-config that we just build with build-llvm.sh
# PATH="${llvm_install_dir}/bin;$PATH"

echo @@@BUILD_STEP configuring clang@@@
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
    -DCMAKE_INSTALL_LIBDIR=${_libdir} \
    || echo @@@STEP_FAILURE@@@

echo @@@BUILD_STEP building clang@@@
LD_LIBRARY_PATH="${LD_LIBRARY_PATH};${llvm_install_dir}/lib64" cmake --build clang-build || echo @@@STEP_FAILURE@@@

echo @@@BUILD_STEP installing clang@@@
cmake --install clang-build || echo @@@STEP_FAILURE@@@