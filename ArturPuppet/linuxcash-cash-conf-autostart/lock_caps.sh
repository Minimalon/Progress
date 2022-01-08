#!/bin/bash

sleep 5
DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xmodmap -e "keycode 66 = NoSymbol"
