ARG ALPINE_TAG=3.20
ARG XMLRPC_VER=1.59.03
ARG LIBTORRENT_VER=0.13.8
ARG RTORRENT_VER=0.9.8

FROM loxoo/alpine:${ALPINE_TAG} AS builder

ARG XMLRPC_VER
ARG LIBTORRENT_VER
ARG RTORRENT_VER
ENV PKG_CONFIG_PATH=/libtorrent/lib/pkgconfig

# install xmlrpc-c
WORKDIR /xmlrpc-src
RUN apk add --no-cache build-base openssl-dev curl-dev; \
    wget -O- https://sourceforge.net/projects/xmlrpc-c/files/Xmlrpc-c%20Super%20Stable/${XMLRPC_VER}/xmlrpc-c-${XMLRPC_VER}.tgz \
        | tar xz --strip-components=1; \
    ./configure --prefix=/xmlrpc \
                --disable-libxml2-backend \
                --disable-cgi-server \
                --disable-libwww-client \
                --disable-wininet-client; \
    make -j$(nproc); \
    make install DESTDIR=/output

# install libtorrent
WORKDIR /libtorrent-src
RUN apk add --no-cache git automake autoconf libtool zlib-dev linux-headers; \
    git clone https://github.com/rakshasa/libtorrent.git --branch v${LIBTORRENT_VER} --depth 1 .; \
    ./autogen.sh; \
    ./configure --prefix=/libtorrent \
                --disable-debug \
                --disable-instrumentation; \
    make -j$(nproc); \
    make install DESTDIR=/output

# install rtorrent
WORKDIR /rtorrent-src
RUN apk add --no-cache ncurses-dev; \
    cp -a /output/* /; \
    git clone https://github.com/rakshasa/rtorrent.git --branch v${RTORRENT_VER} --depth 1 .; \
    ./autogen.sh; \
    ./configure --prefix=/rtorrent \
                --disable-debug \
                --with-xmlrpc-c=/xmlrpc/bin/xmlrpc-c-config; \
    make -j$(nproc); \
    make install DESTDIR=/output; \
    find /output -exec sh -c 'file "{}" | grep -q ELF && strip --strip-debug "{}"' \;

COPY *.sh /output/usr/local/bin/
RUN chmod +x /output/usr/local/bin/*.sh

#============================================================

FROM loxoo/alpine:${ALPINE_TAG}

ARG RTORRENT_VER
ENV SUID=911 SGID=900 \
    RTORRENT_PORT=51578 \
    LD_LIBRARY_PATH=/xmlrpc/lib

LABEL org.label-schema.name="rtorrent" \
      org.label-schema.description="A Docker image for rTorrent BitTorrent client" \
      org.label-schema.url="https://github.com/rakshasa/rtorrent" \
      org.label-schema.version=${RTORRENT_VER}

COPY --from=builder /output/ /

RUN apk add --no-cache ncurses-libs libstdc++ libcurl

VOLUME ["/config", "/session", "/download", "/watch"]

EXPOSE 51578/TCP 51102/TCP

HEALTHCHECK --start-period=10s --timeout=5s \
    CMD nc -z 127.0.0.1 $RTORRENT_PORT

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["/rtorrent/bin/rtorrent", "-n", "-o", "import=/config/rtorrent.rc"]
