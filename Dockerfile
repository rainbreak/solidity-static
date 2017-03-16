FROM alpine

RUN apk --no-cache --update add build-base cmake boost-dev git file perl

# stop boost complaining about sys/poll.h
RUN sed -i -E -e 's/include <sys\/poll.h>/include <poll.h>/' /usr/include/boost/asio/detail/socket_types.hpp

WORKDIR /src

RUN git clone --recursive https://github.com/ethereum/solidity

WORKDIR /src/solidity/build

RUN git checkout v0.4.10

# don't use nightly versioning for releases
RUN echo -n > ../prerelease.txt

RUN cmake -DCMAKE_BUILD_TYPE=Release \
          -DTESTS=1 \
          -DSTATIC_LINKING=1 \
          ..

RUN make --jobs=2 solc soltest lllc

RUN install -s solc/solc /usr/local/bin
RUN install -s test/soltest /usr/local/bin
RUN install -s lllc/lllc /usr/local/bin

RUN file /usr/local/bin/solc /usr/local/bin/soltest /usr/local/bin/lllc
RUN du -h /usr/local/bin/solc /usr/local/bin/soltest /usr/local/bin/lllc
