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

SESSION="wslvpn" # TMUX session name
WINDOW="monitor" # TMUX monitor name
IPWATCH_TIMEOUT=10 # Time in seconds to wait between each ipwatch request
IPWATCH_URL="https://api.ipify.org/?format=text"

STUNNEL_CFG="$(echo -n "$1"|tr -d "'"|sed 's/\\/\\\\\\\\/g')"
OPENVPN_CFG="$(echo -n "$2"|tr -d "'"|sed 's/\\/\\\\\\\\/g')"
OPENVPN_LOG="$(echo -n "$3"|tr -d "'")"

if [ -z "$STUNNEL_CFG" -o -z "$OPENVPN_CFG" -o -z "$OPENVPN_LOG" ]; then
    echo "USAGE: $(basename $0) config.ssl config.ovpn logfile.log"
    exit 1
fi

function yes_no_question {
  shopt -s nocasematch
  local ANSWER=""

  while ! [[ $ANSWER =~ ^(y(es)?)|(no?)$ ]]; do
    read -p "$1 (y/n) " ANSWER
  done

  [ "${ANSWER,,}" == "y" -o "${ANSWER,,}" == "yes" ]
}

if (tmux has-session -t "$SESSION" 2>/dev/null); then
    echo "Session already $SESSION exists."
    if [ -z "$TMUX" ]; then
        echo "Attaching to session $SESSION..."
        tmux attach-session -t "$SESSION"
    fi
else
    tmux new-session -d -n "$WINDOW" -s "$SESSION" "watch -n $IPWATCH_TIMEOUT 'curl -s $IPWATCH_URL'"
    tmux split-window -t "$SESSION:$WINDOW" -v -p 90 "bash -c \"while true; do stunnel.sh '$STUNNEL_CFG'; read -p 'Press enter to restart stunnel'; reset; done\""
    tmux split-window -t "$SESSION:$WINDOW.1" -v -p 70 "bash -c \"while true; do openvpn.sh '$OPENVPN_CFG' '$OPENVPN_LOG'; read -p 'Press enter to restart openvpn'; reset; done\""
fi

exit 0
