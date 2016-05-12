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

RUN git clone https://github.com/weidai11/cryptopp.git
RUN git clone https://github.com/open-source-parsers/jsoncpp.git
RUN git clone https://github.com/cinemast/libjson-rpc-cpp
RUN git clone https://github.com/google/leveldb

RUN mkdir -p /src/built/include /src/built/lib

RUN cd cryptopp && \
    make static && \
    PREFIX=/src/built/ make install

## These aren't really necessary for solc, but can't build without them
## as devcore links to them.
RUN cd jsoncpp && \
    cmake -DCMAKE_INSTALL_PREFIX=/src/built/ . && \
    make jsoncpp_lib_static && \
    make install

RUN mkdir -p libjson-rpc-cpp/build && \
    sed -e 's/^#include <string>/#include <string.h>/' libjson-rpc-cpp/src/jsonrpccpp/server/connectors/unixdomainsocketserver.cpp -i && \
    cd libjson-rpc-cpp/build && \
    cmake -DJSONCPP_LIBRARY=../../jsoncpp/src/lib_json/libjsoncpp.a \
          -DJSONCPP_INCLUDE_DIR=../../jsoncpp/include/ \
          -DBUILD_STATIC_LIBS=YES                      \
          -DBUILD_SHARED_LIBS=NO                       \
          -DCOMPILE_TESTS=NO                           \
          -DCOMPILE_EXAMPLES=NO                        \
          -DCOMPILE_STUBGEN=NO                         \
          -DCMAKE_INSTALL_PREFIX=/src/built/           \
          .. && \
    make install

RUN cd leveldb && \
    make && \
    cp -rv include/leveldb /src/built/include/ && \
    cp -v out-static/libleveldb.a /src/built/lib/

# make sure that boost links statically
RUN mkdir -p /src/boost/lib /src/boost/include/boost
RUN cp /usr/lib/libboost*.a /src/boost/lib/
RUN cp -r /usr/include/boost /src/boost/include/
RUN apk del boost-dev

WORKDIR /src

RUN git clone https://github.com/ethereum/webthree-umbrella

RUN cd webthree-umbrella && \
    git checkout release --force && \
    git submodule update --init

RUN mkdir -p /src/webthree-umbrella/build
WORKDIR /src/webthree-umbrella/build

RUN cmake -DSOLIDITY=1 -DCMAKE_BUILD_TYPE=Release \
          -DEVMJIT=0 -DGUI=0 -DFATDB=0 -DETHASHCL=0 -DMINIUPNPC=0 \
          -DTOOLS=0 -DTESTS=1 -DETH_STATIC=1 \

          -DCMAKE_CXX_FLAGS='-Wno-error -static' \

          -DJSONCPP_LIBRARY=/src/built/lib/libjsoncpp.a \
          -DJSONCPP_INCLUDE_DIR=/src/built/include/ \

          -DCRYPTOPP_LIBRARY=/src/built/lib/libcryptopp.a \
          -DCRYPTOPP_INCLUDE_DIR=/src/built/include \

          -DLEVELDB_LIBRARY=/src/built/lib/libleveldb.a \
          -DLEVELDB_INCLUDE_DIR=/src/built/include/  \

          -DJSON_RPC_CPP_CLIENT_LIBRARY=/src/built/lib/libjsonrpccpp-client.a \
          -DJSON_RPC_CPP_COMMON_LIBRARY=/src/built/lib/libjsonrpccpp-common.a \
          -DJSON_RPC_CPP_SERVER_LIBRARY=/src/built/lib/libjsonrpccpp-server.a \
          -DJSON_RPC_CPP_INCLUDE_DIR=/src/built/include \

          -DBoost_USE_STATIC_LIBS=1 \
          -DBoost_USE_STATIC_RUNTIME=1 \
          -DBoost_FOUND=1 \

          -DBoost_INCLUDE_DIR=/src/boost/include/ \
          -DBoost_CHRONO_LIBRARY=/src/boost/lib/libboost_chrono.a \
          -DBoost_CHRONO_LIBRARIES=/src/boost/lib/libboost_chrono.a \
          -DBoost_DATE_TIME_LIBRARY=/src/boost/lib/libboost_date_time.a \
          -DBoost_DATE_TIME_LIBRARIES=/src/boost/lib/libboost_date_time.a \
          -DBoost_FILESYSTEM_LIBRARY=/src/boost/lib/libboost_filesystem.a \
          -DBoost_FILESYSTEM_LIBRARIES=/src/boost/lib/libboost_filesystem.a \
          -DBoost_PROGRAM_OPTIONS_LIBRARY=/src/boost/lib/libboost_program_options.a \
          -DBoost_PROGRAM_OPTIONS_LIBRARIES=/src/boost/lib/libboost_program_options.a \
          -DBoost_RANDOM_LIBRARY=/src/boost/lib/libboost_random.a \
          -DBoost_RANDOM_LIBRARIES=/src/boost/lib/libboost_random.a \
          -DBoost_REGEX_LIBRARY=/src/boost/lib/libboost_regex.a \
          -DBoost_REGEX_LIBRARIES=/src/boost/lib/libboost_regex.a \
          -DBoost_SYSTEM_LIBRARY=/src/boost/lib/libboost_system.a \
          -DBoost_SYSTEM_LIBRARIES=/src/boost/lib/libboost_system.a \
          -DBoost_THREAD_LIBRARY=/src/boost/lib/libboost_thread.a \
          -DBoost_THREAD_LIBRARIES=/src/boost/lib/libboost_thread.a \
          -DBoost_UNIT_TEST_FRAMEWORK_LIBRARY=/src/boost/lib/libboost_unit_test_framework.a \
          -DBoost_UNIT_TEST_FRAMEWORK_LIBRARIES=/src/boost/lib/libboost_unit_test_framework.a \
          ..

RUN sed -e 's/^#if defined(__linux__)/#if defined(__ignoreme__)/' -i ../libweb3core/libdevcore/Log.cpp

RUN make --jobs=2 solc soltest

RUN cp /src/webthree-umbrella/build/solidity/solc/solc /usr/local/bin/
RUN cp /src/webthree-umbrella/build/solidity/test/soltest /usr/local/bin/

RUN soltest

RUN apk add file

RUN file /usr/local/bin/solc
RUN file /usr/local/bin/soltest

RUN du -h /usr/local/bin/solc
RUN du -h /usr/local/bin/soltest
