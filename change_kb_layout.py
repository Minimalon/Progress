#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import commands
import os
import datetime

def logger():
    with open("/linuxcash/net/server/server/logs/change_layout.txt", "a+") as log:
        log.write(datetime.datetime.strftime(datetime.datetime.now() ,"%Y/%m/%d %H:%M:%S") + " " + os.uname()[1] + "\n")


while True:
    layout = commands.getoutput("DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xset -q | grep LED | awk '{print $10}' | cut -c 5")
    if layout == '1':
      commands.getoutput("DISPLAY=:255 XAUTHORITY=/home/autologon/.Xauthority sudo -u autologon xdotool key ISO_Next_Group")
      logger()
