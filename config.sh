# See https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/#macros_installation
# for these variable names.

_exec_prefix=${_prefix}
_includedir=${_prefix}/include
_bindir=${_exec_prefix}/bin
_lib=lib64
_libdir=${_prefix}/${_lib}
_sysconfdir=${_prefix}/etc
_datarootdir=${_prefix}/share
_pkgdocdir=${_prefix}/share/doc/llvm
llvm_triple=x86_64-redhat-linux-gnu
build_type=RelWithDebInfo