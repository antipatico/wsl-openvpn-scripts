#!/usr/bin/env bash
#
# USAGE: openvpn.sh "C:\\Path\\To\\Config.ovpn" /mnt/c/Path/To/Log.log
#
# This script is used to wrap around openvpn.exe (the win version of openvpn).
# It runs openvpn.exe as admin, then tails -f the logfile and traps CTRL+C.
# When the trap triggers the openvpn.exe PID is retrieved (using tasklist.exe),
# then windows-kill.exe is run to send SIGINT to the openvpn.exe process.
#
# NOTE: the log file must be specified in windows path version inside the ovpn
#       config file and in wsl version (/mnt/c/...) for this script.
# NOTE: all the paths inside the config file should be relative (ca, log, ...)
#
# Author: antipatico (github.com/antipatico)
# All wrongs reversed - 2019

TIMEOUT=15 # time in seconds to wait openvpn to exit before trying to killing it

# NOTE: the following line is critical, since VPN_CONFIG is then piped into a
#       powershell script which will run as admin (in the openvpn_start
#       function). Thus, it is critical to escape it.
#       I don't know if this is good enough, if you find a way to evade this
#       please mail me a patch.
VPN_CONFIG=$(echo -n "$1"| tr -d "\"<>/|?*")
VPN_LOG=$2
[ -z "$VPN_CONFIG" ] || [ -z "$VPN_LOG" ] && echo "USAGE: $(basename $0) config_file.ovpn logfile.log" && exit 1 


function openvpn_pid {
  tasklist.exe /FI "IMAGENAME eq openvpn.exe" /FO CSV | grep -v "INFO" | tail -n 1 | cut -d "," -f 2 | tr -d '"' | tr -d "\n"
}

function openvpn_close {
  echo "Start-Process -FilePath \"windows-kill.exe\" -ArgumentList \"-SIGINT $(openvpn_pid)\" -verb RunAs -WindowStyle Hidden" | powershell.exe -Command -
}

function openvpn_kill {
  echo "Start-Process -FilePath \"taskkill.exe\" -ArgumentList \"/PID $(openvpn_pid) /F\" -verb RunAs -WindowStyle Hidden" | powershell.exe -Command -
}

function openvpn_start {
  echo "Start-Process -FilePath \"openvpn.exe\" -ArgumentList \"$VPN_CONFIG\" -verb RunAs -WindowStyle Hidden" | powershell.exe -Command -
}

function unix_timestamp {
  date +"%s"
}

function yes_no_question {
  shopt -s nocasematch
  local ANSWER=""

  while ! [[ $ANSWER =~ ^(y(es)?)|(no?)$ ]]; do
    read -p "$1 (y/n) " ANSWER
  done

  [ "${ANSWER,,}" == "y" -o "${ANSWER,,}" == "yes" ]
}

function clear_exit {
  if [ -n "$(openvpn_pid)" ]; then
    # If openvpn is still alive, send CTRL+C
    openvpn_close
  fi

  # Wait for openvpn to exit
  local TIMESTAMP=$(unix_timestamp)
  while [ $((TIMESTAMP-$(unix_timestamp))) -lt $TIMEOUT -a -n "$(openvpn_pid)" ]; do
    sleep 0.25
  done

  if [ -n "$(openvpn_pid)" ]; then
    # If openvpn is still alive, kill it
    openvpn_kill
  fi

  sleep 0.5
  # kill tail and resume the scripts execution (after the wait statement)
  kill -PIPE $TAIL_PID
}

if openvpn_start; then
  touch "$VPN_LOG"
  tail -n 1337 ---disable-inotify -qF "$VPN_LOG" &
  TAIL_PID=$!
  trap clear_exit SIGINT

  wait $TAIL_PID # wait for tail to exit
  if [ -z "$(openvpn_pid)" ] && yes_no_question "Do you want to shred the log file?"; then
    srm -v "$VPN_LOG"
  fi
fi

exit 0
