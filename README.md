<a href='https://travis-ci.org/rainbeam/solidity-static'> <img src='https://travis-ci.org/rainbeam/solidity-static.svg?branch=master'> </a>

## Static, portable builds of Solidity

This is a script to produce a fully static build of `solc`, the
Solidity compiler.

This is done by statically linking to musl in an Alpine Linux
environment. Unlike glibc, musl is built with static linking in
mind.

The resulting binary should work on a wide variety of Linux
platforms.
