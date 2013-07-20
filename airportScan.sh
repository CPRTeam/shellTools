#!/bin/bash

trap "exit" SIGHUP SIGINT SIGQUIT SIGKILL SIGTERM SIGSTOP SIGTSTP SIGUSR1 SIGUSR2
while [ 1 ]; do
	result=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s | grep -e "^\s*$1\ " | awk '{print $1" "$3" "$2" "$4}' | sort | awk '{print $3"\t"$2"\t"$4"\t"$1}' | sed -e 's/\n/\\n/g')
	clear
	echo -e "$result"
done
exit_handler() {
	echo -e "\rSIGINT exit!"
	exit 2
}
trap exit_handler SIGHUP SIGINT SIGQUIT SIGKILL SIGTERM SIGSTOP SIGTSTP SIGUSR1 SIGUSR2
