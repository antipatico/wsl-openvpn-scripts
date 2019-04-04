#!/bin/bash
#
# USAGE: tmux-session.sh C:\\config.ssl C:\\config.ovpn /mnt/C/logfile.log
#
# This scripts create a TMUX session in which you can see both stunnel and
# openvpn logs. It also has a pane with your public IP.
#
# It is configured to restart the services on exit (stunnell && openvpn).
# To kill the session simply kill the services using CTRL+C and then kill
# the session using "tmux kill-session -t wslvpn".
#
# You can attach to the terminal from windows using
# "C:\Windows\System32\wsl.exe tmux attach-session -t wslvpn"
# Or by changin wsl.exe with your favourite terminal emulator :)
#
# Authors: antipatico (github.com/antipatico)
# All wrongs reversed - 2019

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
    echo "USAGE: $(basename $0) config.ssl config.ovpn logfile.log"
    exit 1
fi

STUNNEL_CFG="$(echo -n "$1"|tr -d "'"|sed 's/\\/\\\\\\\\/g')"
OPENVPN_CFG="$(echo -n "$2"|tr -d "'"|sed 's/\\/\\\\\\\\/g')"
OPENVPN_LOG="$(echo -n "$3"|tr -d "'")"

session="wslvpn"
if (tmux has-session -t "$session" 2>/dev/null); then
    echo "Session already $session exists."
    if [ -z "$TMUX" ]; then
        echo "Attaching to session $session..."
        tmux attach-session -t "$session"
    fi
else
    tmux new-session -d -n "monitor" -s "$session" "watch -n 10 'curl -s https://api.ipify.org/?format=text'"
    tmux split-window -t "wslvpn:monitor" -v -p 90 "bash -c \"while true; do stunnel.sh '$STUNNEL_CFG'; read -p 'Press enter to restart stunnel'; reset; done\""
    tmux split-window -t "wslvpn:monitor.1" -v -p 70 "bash -c \"while true; do openvpn.sh '$OPENVPN_CFG' '$OPENVPN_LOG'; read -p 'Press enter to restart openvpn'; reset; done\""
fi

exit 0
