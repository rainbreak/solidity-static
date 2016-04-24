<a href='https://travis-ci.org/rainbeam/solidity-static'> <img src='https://travis-ci.org/rainbeam/solidity-static.svg?branch=master'> </a>

## Static, portable builds of Solidity

This is a script to produce a fully static build of `solc`, the
Solidity compiler.

This is done by statically linking to [musl] in an [Alpine Linux][alpine]
environment. Unlike glibc, musl is built with static linking in
mind.

[musl]: http://www.musl-libc.org/
[alpine]: http://www.alpinelinux.org/

The resulting binary should work on a wide variety of Linux
platforms (tested here with CentOS, Arch, Alpine and Busybox).

```bash
$ file solc soltest
solc: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, not stripped
soltest: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, not stripped
```
