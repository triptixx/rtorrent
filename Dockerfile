ARG ALPINE_TAG=3.10
ARG RTORRENT_VER=0.9.8

FROM loxoo/alpine:${ALPINE_TAG}

ARG RTORRENT_VER

LABEL org.label-schema.name="rtorrent" \
      org.label-schema.description="A Docker image for rTorrent BitTorrent client" \
      org.label-schema.url="https://github.com/rakshasa/rtorrent" \
      org.label-schema.version=${RTORRENT_VER}

COPY --from=builder /output/ /

VOLUME ["/config", "/session", "/download"]

EXPOSE 51570/TCP

HEALTHCHECK --start-period=10s --timeout=5s \
    CMD 

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["rtorrent"]
