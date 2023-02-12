#!/usr/bin/env bash

NOTF_DIR="/root/notifications"
  find $NOTF_DIR -name "autoAccept_*" -mtime +1 -exec rm -rf {} \;
