#!/bin/sh
set -eo pipefail

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'
error() { >&2 echo -e "${RED}Error: $@${RESET}"; exit 1; }

CONF_RTORRENT='/config/rtorrent.rc'

if [ ! -e /config/*.rc ]; then

    wget https://github.com/triptixx/rtorrent/raw/master/rtorrent.rc -O $CONF_RTORRENT
    if [ $? -ne 0 ]; then
        error "Unable to download file $(basename $CONF_RTORRENT)"
    fi

    

fi
