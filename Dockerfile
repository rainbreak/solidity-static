FROM alpine:3.3

# We can static link to these with -static if we want
RUN apk --no-cache --update add --virtual dependencies \
            libgcc \
            libstdc++
RUN apk --no-cache --update add --virtual build-dependencies \
            bash \
            cmake \
            curl-dev \
            git \
            gcc \
            g++ \
            linux-headers \
            make \
            perl \
            python \
            scons\

            boost-dev \
            gmp-dev\
            libmicrohttpd-dev

RUN mkdir -p /src/deps

WORKDIR /src/deps

RUN git clone https://github.com/mmoss/cryptopp.git
RUN git clone https://github.com/open-source-parsers/jsoncpp.git
RUN git clone https://github.com/cinemast/libjson-rpc-cpp
RUN git clone https://github.com/google/leveldb

ENV PREFIX /src/built

RUN mkdir -p ${PREFIX}/include ${PREFIX}/lib

RUN cd cryptopp \
 && cmake -DCRYPTOPP_LIBRARY_TYPE=STATIC \
          -DCRYPTOPP_RUNTIME_TYPE=STATIC \
          -DCRYPTOPP_BUILD_TESTS=FALSE \
          -DCMAKE_INSTALL_PREFIX=${PREFIX}/ \
          . \
 && make cryptlib \
 && cp -r src ${PREFIX}/include/cryptopp \
 && cp src/libcryptlib.a ${PREFIX}/lib/


## These aren't really necessary for solc, but can't build without them
## as devcore links to them.
RUN cd jsoncpp \
 && cmake -DCMAKE_INSTALL_PREFIX=${PREFIX}/ . \
 && make jsoncpp_lib_static \
 && make install

RUN mkdir -p libjson-rpc-cpp/build \
 && sed -e 's/^#include <string>/#include <string.h>/' libjson-rpc-cpp/src/jsonrpccpp/server/connectors/unixdomainsocketserver.cpp -i \
 && cd libjson-rpc-cpp/build \
 && cmake -DJSONCPP_LIBRARY=../../jsoncpp/src/lib_json/libjsoncpp.a \
          -DJSONCPP_INCLUDE_DIR=../../jsoncpp/include/ \
          -DBUILD_STATIC_LIBS=YES                      \
          -DBUILD_SHARED_LIBS=NO                       \
          -DCOMPILE_TESTS=NO                           \
          -DCOMPILE_EXAMPLES=NO                        \
          -DCOMPILE_STUBGEN=NO                         \
          -DCMAKE_INSTALL_PREFIX=${PREFIX}/           \
          .. \
 && make install

RUN cd leveldb \
 && make \
 && cp -rv include/leveldb ${PREFIX}/include/ \
 && cp -v out-static/libleveldb.a ${PREFIX}/lib/

WORKDIR /src

RUN git clone https://github.com/ethereum/webthree-umbrella

ENV buildbranch=release

RUN cd webthree-umbrella \
 && git checkout ${buildbranch} --force \
 && git submodule update --init --recursive

RUN mkdir -p /src/webthree-umbrella/build
WORKDIR /src/webthree-umbrella/build

# stop complaining about sys/poll.h
RUN sed -i -E -e 's/include <sys\/poll.h>/include <poll.h>/' /usr/include/boost/asio/detail/socket_types.hpp

RUN cmake -DCMAKE_BUILD_TYPE=Release \
          -DEVMJIT=0 -DGUI=0 -DFATDB=0 -DETHASHCL=0 -DMINIUPNPC=0 \
          -DTOOLS=0 \
          -DTESTS=1 \
          -DSOLIDITY=1 \
          -DSTATIC_LINKING=1 \
          -DCMAKE_PREFIX_PATH=${PREFIX} \
          ..

RUN make --jobs=2 solc soltest

RUN cp /src/webthree-umbrella/build/solidity/solc/solc /usr/local/bin/
RUN cp /src/webthree-umbrella/build/solidity/test/soltest /usr/local/bin/

RUN soltest

RUN apk add file

RUN file /usr/local/bin/solc
RUN file /usr/local/bin/soltest

RUN du -h /usr/local/bin/solc
RUN du -h /usr/local/bin/soltest
