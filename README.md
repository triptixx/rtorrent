[hub]: https://hub.docker.com/r/loxoo/rtorrent
[git]: https://github.com/triptixx/rtorrent/tree/master
[actions]: https://github.com/triptixx/rtorrent/actions/workflows/main.yml

# [loxoo/rtorrent][hub]
[![Git Commit](https://img.shields.io/github/last-commit/triptixx/rtorrent/master)][git]
[![Build Status](https://github.com/triptixx/rtorrent/actions/workflows/main.yml/badge.svg?branch=master)][actions]
[![Latest Version](https://img.shields.io/docker/v/loxoo/rtorrent/latest)][hub]
[![Size](https://img.shields.io/docker/image-size/loxoo/rtorrent/latest)][hub]
[![Docker Stars](https://img.shields.io/docker/stars/loxoo/rtorrent.svg)][hub]
[![Docker Pulls](https://img.shields.io/docker/pulls/loxoo/rtorrent.svg)][hub]

## Usage

```shell
docker run -d \
    --name=srvrtorrent \
    --restart=unless-stopped \
    --hostname=srvrtorrent \
    -p 51570:51570 \
    -e RTORRENT_PORT=51570 \
    -v $PWD/config:/config \
    -v $PWD/session:/session \
    -v $PWD/watch:/watch \
    -v $PWD/download:/download \
    loxoo/rtorrent
```

## Environment

- `$SUID`                - User ID to run as. _default: `911`_
- `$SGID`                - Group ID to run as. _default: `900`_
- `$RTORRENT_PORT`       - Listening port for incoming peer traffic. _default: `51578`_
- `$LOG_LEVEL`           - Logging severity levels. _default: `info`_
- `$TZ`                  - Timezone. _optional_

## Volume

- `/session`             - Torrent files and status information for all open downloads will be stored in this directory.
- `/watch`               - Load torrent files dropped into special folders.
- `/download`            - Directory where downloaded and downloading files are stored.
- `/config`              - Server configuration file location.

## Network

- `51578/tcp`            - Listening port for incoming peer traffic.
- `51102/tcp`            - Port is used by the XMLRPC socket.