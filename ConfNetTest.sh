#!/bin/bash
cd `dirname $0`
if [ "$1" != "" ]; then
	./inetLookup.sh -t -gp .. -gs "0.1 0.2" $@
else
	echo -e "===== \033[34m${0##*/}\033[m is Script by Haraguroicha 2013-01-12 ====="
	usage="Usage: ${0##*/}"
	echo "$usage <interface> [ping_timeout]"
	echo "$usage <interface> <gateway_pattern> <gateway_suffix> [ping_timeout]"
	./inetLookup.sh
fi
