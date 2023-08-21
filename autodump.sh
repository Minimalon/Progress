#!/usr/bin/env bash


dumpfile=$(find /root/dumpsdict/ -name '*.gz' | grep dictionaries | xargs ls -t | head -n 1)
if [ -f "$dumpfile" ]; then
  echo "Устанавливаю дамп $dumpfile"
  gunzip -c "$dumpfile" | mysql dictionaries
else
  echo "Не найдено дампов dictionaries в папке /root/dumpsdict/"
fi
