#!/usr/bin/env python
# -*- coding: utf-8 -*-


#Сделать проверку что есть Waybillv4 в папке. И выводить в консоль если его нету
#Вывод итогово образца чека для отправки на УТМ
#Написать что check.img сформируется если была хотя бы одна продажа за день
#Написать README


import os, re , request

ttnload = os.listdir("/root/ttnload/TTN/")

x = 0
for TTN in ttnload:
	x += 1
	print(str(x) + ": " + TTN)

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
                        if "EAN" in line:
                            EAN = re.split(">|<", line)[2]
                        if "Price" in line:
                            price = re.split(">|<", line)[2]
                        if "<ce:amc>" in line:
                            amark = re.split(">|<", line)[2]
                            check.write("<Bottle barcode=" + amark + '"' + ' volume="1.0000" ean="' + EAN + '"' + ' price="' + price + '"/>' + "\n")
            check.write("</Cheque>")
r = requests.post('http://localhost:8082/opt/in',   ) # Пытаюсь сделать пост запрос check.xml на УТМ

