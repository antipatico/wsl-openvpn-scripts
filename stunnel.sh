#!/usr/bin/env bash
#
# USAGE: stunnel.sh C:\\Path\\To\\Config.ssl
#
# This script is used to wrap around tstunnel.exe (the shell version of stunnel
# for windows).
# It simply runs stunnel in the background and waits for CTRL+C.
# When CTRL+C is catched stunnel is killed and the script exits.
#
# Author: antipatico (github.com/antipatico)
# All wrongs reversed - 2019

[ -z "$1" ] && echo "USAGE: $(basename $0) config_file.ssl" && exit 1 

function kill_stunnel {
  taskkill.exe /IM tstunnel.exe /f
  exit 0
}

trap kill_stunnel SIGINT
tstunnel.exe "$1" &

wait
