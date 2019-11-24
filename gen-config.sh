#!/bin/sh
set -eo pipefail

# ANSI colour escape sequences
RED='\033[0;31m'
RESET='\033[0m'
error() { >&2 echo -e "${RED}Error: $@${RESET}"; exit 1; }

CONF_RTORRENT='/config/rtorrent.rc'

if [ ! -e /config/*.rc ]; then

    cat > "$CONF_RTORRENT" <<EOL
## Instance layout (base paths)
method.insert = cfg.download, string|private|const, (cat, "/download")
method.insert = cfg.session,  string|private|const, (cat, "/session")
method.insert = cfg.watch,    string|private|const, (cat, "/watch")

## Basic operational settings
encoding.add          = UTF-8
session.use_lock.set  = no
session.path.set      = (cat, (cfg.session))
directory.default.set = (cat, (cfg.download), "/leeching")
system.daemon.set     = true
execute.nothrow       = sh, -c, (cat, "echo > ", (session.path), "/rtorrent.pid ", (system.pid))

## Listening port for incoming peer traffic
network.port_range.set  = ${RTORRENT_PORT}-${RTORRENT_PORT}
network.port_random.set = no
network.scgi.open_port  = 0.0.0.0:51102

## Tracker-less torrent and UDP tracker support
dht.mode.set         = disable
protocol.pex.set     = no
trackers.use_udp.set = no

## Peer settings
throttle.global_down.max_rate.set_kb = 92160
throttle.global_up.max_rate.set_kb   = 92160
throttle.max_downloads.global.set    = 300
throttle.max_uploads.global.set      = 300
throttle.min_peers.normal.set        = 99
throttle.max_peers.normal.set        = 100
throttle.min_peers.seed.set          = -1
throttle.max_peers.seed.set          = -1
throttle.max_downloads.set           = 50
throttle.max_uploads.set             = 50
trackers.numwant.set                 = 100
protocol.encryption.set              = allow_incoming,require,require_RC4

## Memory resource usage
pieces.memory.max.set         = 8192M
pieces.hash.on_completion.set = no
network.xmlrpc.size_limit.set = 2M

## Limits for file handle resources, this is optimized for
## an `ulimit` of 1024 (a common default)
network.max_open_sockets.set = 300
network.max_open_files.set   = 600
network.http.max_open.set    = 50

## Send and receive buffer size for socket
network.receive_buffer.size.set =  8M
network.send_buffer.size.set    = 24M

# Preloading a piece of a file
pieces.preload.type.set = 2

# CURL options to add support for nonofficial SSL trackers and peers
network.http.ssl_verify_host.set = 0
network.http.ssl_verify_peer.set = 0

# CURL option to lower DNS timeout.
network.http.dns_cache_timeout.set = 25

## Create base directory
method.insert = dirs,    string|private|const, (cat, "'leeching;seeding'")
method.insert = subdirs, string|private|const, (cat, "'apps;books;games;movies;music;other;tv'")

execute.throw = sh, -c, (cat, "for DIR in \`echo ", (dirs), " | tr ';' '\\\n'\`; do ", \\
        "for SUBDIR in \`echo ", (subdirs), " | tr ';' '\\\n'\`; do ", \\
            "mkdir -p ", (cfg.download), "/\$DIR/\$SUBDIR; ", \\
        "done; ", \\
    "done")

execute.throw = sh, -c, (cat, "for SUBDIR in \`echo ", (subdirs), " | tr ';' '\\\n'\`; do ", \\
        "mkdir -p ", (cfg.watch), "/\$SUBDIR; ", \\
    "done")

## global methode
method.insert = d.label_name, simple|private, "execute.capture = sh, -c, \\
    (cat, \"echo -n '\", (argument.0), \"' | sed 's|\", (argument.1), \"/\\\\\\\([^/]\\\\\\\+\\\\\\\).*|\\\\\\\1|'\")"
method.insert = d.dir_name,   simple|private, "execute.capture = sh, -c, \\
    (cat, \"echo -n '\", (argument.0), \"' | sed 's|\\\\\\\(.*\\\\\\\)/\", (argument.1), \"|\\\\\\\1|'\")"

## watch configuration
method.insert = d.get_start_update, simple|private, "cat = (directory.default), \"/\", (d.label_name, (argument.0), \\
    (cfg.watch))"
method.insert = d.file_load, simple|private, "load.start_verbose = (argument.0), (cat, d.directory.set=, \\
    (d.get_start_update, (argument.0))), d.delete_tied="

directory.watch.added = (cat, (cfg.watch), "/apps/"), d.file_load
directory.watch.added = (cat, (cfg.watch), "/books/"), d.file_load
directory.watch.added = (cat, (cfg.watch), "/games/"), d.file_load
directory.watch.added = (cat, (cfg.watch), "/movies/"), d.file_load
directory.watch.added = (cat, (cfg.watch), "/music/"), d.file_load
directory.watch.added = (cat, (cfg.watch), "/other/"), d.file_load
directory.watch.added = (cat, (cfg.watch), "/tv/"), d.file_load

## process add
method.insert  = d.dir_erase, simple|private, "d.close=; d.erase="
method.insert  = d.custom1_update, simple|private, "cat = d.custom1.set=, (d.label_name, (d.directory), \\
    (directory.default))"
method.set_key = event.download.inserted_new, d.label_add, "branch = ((equal, ((directory.default)), \\
    ((d.dir_name, (d.directory), (d.name))))), ((d.dir_erase)), (d.custom1_update)"

## process finish
method.insert  = d.get_move_leech, simple|private, "cat = (directory.default), \"/\", (argument.0)"
method.insert  = d.get_move_seed, simple|private, "cat = (cfg.download), \"/seeding/\", (argument.0)"
method.insert  = d.move_mkdir, simple|private, "execute.throw = sh, -c, (cat, \"mkdir -p \", (d.get_move_seed, \\
    (argument.0)))"
method.insert  = d.move_mv, simple|private, "execute.throw = sh, -c, (cat, \"mv \", (d.get_move_leech, (argument.0)), \\
    \"/\", (argument.1), \" \", (d.get_move_seed, (argument.0)))"
method.set_key = event.download.finished, d.move_complete, "d.directory.set = (d.get_move_seed, (d.custom1)); \\
    d.move_mkdir = (d.custom1); d.move_mv = (d.custom1), (d.name)"

# Save all the sessions in every 12 hours
schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))
schedule2 = session_save, 1200, 43200, ((session.save))

## Logging:
##   Levels = critical error warn notice info debug
method.insert  = cfg.logfile, string|private|const, (cat, "/dev/stdout")
log.open_file  = "log", (cfg.logfile)
log.add_output = "${LOG_LEVEL:-info}", "log"

EOL

    if [ ! -e "$CONF_RTORRENT" ]; then
        error "Unable to generate the configuration file $(basename $CONF_RTORRENT)"
    fi

fi
