#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, re

ttnload = list(reversed(os.listdir("/root/ttnload/TTN/")))

x = 0
for TTN in ttnload:
    if x == 10:
        break
    x += 1
    print(str(x) + ": " + TTN)

print("Обязательно должна быть одна продажа в смене (можно продажу и возврат сделать), чтобы забрать шапку для чека")
numberTTN = input("Введите номер строки: ")

WBpath = os.listdir("/root/ttnload/TTN/" + ttnload[numberTTN-1])

for line in WBpath:
    if "WayBill_v4.xml" in line:
        with open("/root/sendCheck/check.xml", "wt") as check:
            check.write('<?xml version="1.0" encoding="utf-8"?>' + "\n")
            with open("/linuxcash/logs/current/terminal.log") as terminal:
                for message in terminal:
                    if "kassa" in message:
                        cheque = message
                        break
                check.write(message)
                with open("/root/ttnload/TTN/" + ttnload[numberTTN-1] + "/WayBill_v4.xml") as f:
                    for line in f:
                        line = line.replace("<","\n<")
                        if "<wb:EAN13>" in line:
                            EAN = re.split(">|\n<", line)[2]
                        if "<wb:Price>" in line:
                            price = re.split(">|\n<", line)[2]
                        if "<ce:amc>" in line:
                            amark = re.split(">|\n<", line)[2]
                            check.write("<Bottle barcode="+ '"' + amark + '"' + ' volume="0.0000" ean="' + EAN + '"' + ' price="' + price[:-2] + '"/>' + "\n")
            check.write("</Cheque>")