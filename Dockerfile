FROM alpine

RUN apk update && apk add bash
RUN apk add python bash git curl-dev make cmake gcc g++ perl scons
RUN apk add boost-dev libmicrohttpd-dev

# ADD build_deps.sh .

# RUN ./build_deps.sh
RUN git clone https://github.com/ethereum/webthree-umbrella && \
    cd webthree-umbrella && \
    git submodule update --init --recursive

RUN mkdir -p deps

WORKDIR /deps

RUN git clone https://github.com/mmoss/cryptopp.git && \
    cd cryptopp && \
    cmake . && \
    make cryptopp

RUN git clone https://github.com/open-source-parsers/jsoncpp.git && \
    cd jsoncpp && \
    cmake . && \
    make jsoncpp_lib_static

RUN git clone https://github.com/cinemast/libjson-rpc-cpp && \
    mkdir -p libjson-rpc-cpp/build && \
    sed -e 's/^#include <string>/#include <string.h>/' libjson-rpc-cpp/src/jsonrpccpp/server/connectors/unixdomainsocketserver.cpp -i && \
    cd libjson-rpc-cpp/build && \
    cmake -DJSONCPP_LIBRARY=../../jsoncpp/src/lib_json/libjsoncpp.a \
          -DJSONCPP_INCLUDE_DIR=../../jsoncpp/include/ \
          -DBUILD_STATIC_LIBS=YES                      \
          -DBUILD_SHARED_LIBS=NO                       \
          -DCOMPILE_TESTS=NO                           \
          -DCOMPILE_EXAMPLES=NO                        \
          -DCOMPILE_STUBGEN=NO                         \
          .. && \
    make 

RUN git clone https://github.com/google/leveldb && \
    cd leveldb && \
    make

RUN git clone https://github.com/miniupnp/miniupnp && \
    cd miniupnp/miniupnpc && \
    make upnpc-static


WORKDIR /

RUN cd webthree-umbrella && \
    git checkout release && \
    git submodule update --force && \
    mkdir -p /webthree-umbrella/build

RUN apk add gmp-dev

WORKDIR /webthree-umbrella/build
RUN cmake -DSOLIDITY=1 -DCMAKE_BUILD_TYPE=Release -DEVMJIT=0 -DGUI=0 \
          -DETHASHCL=0 -DTESTS=0 -DTOOLS=0 -DETH_STATIC=1 \
          
          -DJSONCPP_LIBRARY=/deps/jsoncpp/src/lib_json/libjsoncpp.a \
          -DJSONCPP_INCLUDE_DIR=/deps/jsoncpp/include/ \
          
          -DCRYPTOPP_LIBRARY=/deps/cryptopp/target/lib/libcryptopp.a \
          -DCRYPTOPP_INCLUDE_DIR=/deps/cryptopp/target/include/ \
          
          -DLEVELDB_LIBRARY=/deps/leveldb/out-static/libleveldb.a \ 
          -DLEVELDB_INCLUDE_DIR=/deps/leveldb/include/  \
          
          -DMINIUPNPC_LIBRARY=/deps/miniupnp/miniupnpc/libminiupnpc.a \
          -DMINIUPNPC_INCLUDE_DIR=/deps/miniupnp/miniupnpc/ \
          
          -DJSON_RPC_CPP_CLIENT_LIBRARY=/deps/libjson-rpc-cpp/build/lib/libjsonrpccpp-client.a \
          -DJSON_RPC_CPP_COMMON_LIBRARY=/deps/libjson-rpc-cpp/build/lib/libjsonrpccpp-common.a \
          -DJSON_RPC_CPP_SERVER_LIBRARY=/deps/libjson-rpc-cpp/build/lib/libjsonrpccpp-server.a \
          -DJSON_RPC_CPP_INCLUDE_DIR=/deps/libjson-rpc-cpp/src/jsonrpccpp/ \
          
          -DCMAKE_CXX_FLAGS='-static -Wno-error' \
          -DBoost_USE_STATIC_LIBS=1 \
          -DBoost_USE_STATIC_RUNTIME=1 \
          ..

RUN sed -e 's/^#if defined(__linux__)/#if defined(__lolux__)/' -i ../libweb3core/libdevcore/Log.cpp

RUN make solc

RUN cp /webthree-umbrella/build/solidity/solc/solc /usr/local/bin/

CMD /usr/local/bin/solc
