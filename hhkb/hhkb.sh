#!/bin/bash

# These environmental variables are required
# to access the x server.
# https://stackoverflow.com/a/20678530
export XAUTHORITY=/run/user/1000/gdm/Xauthority
export DISPLAY=:0

if [ "$ACTION" == "add" ]; then
    # Disable thinkpad built in keyboard
    xinput float 9
fi

if [ "$ACTION" == "remove" ]; then
    # Renable built in keyboard
    xinput reattach 9 3
fi
