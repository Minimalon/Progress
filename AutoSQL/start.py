#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, re
import pymysql
from contextlib import closing
from pymysql.cursors import DictCursor

ttnload = list(reversed(os.listdir("/root/ttnload/TTN/")))
for i in ttnload:
    if "TTN" not in i:
        ttnload.remove(i)

with closing(pymysql.connect(host='localhost', user='root', password='', db='dictionaries', charset='utf8mb4', cursorclass=DictCursor)) as connection:
    with connection.cursor() as cursor:
        for TTN in ttnload:
            WBpath = os.listdir("/root/ttnload/TTN/" + TTN)
            for line in WBpath:
                if "WayBill_v4.xml" in line:
                    with open("/root/ttnload/TTN/" + TTN + "/WayBill_v4.xml") as f:
                        for line in f:
                            line = line.replace("<","\n<")
                            if "<pref:FullName>" in line:
                                FullName = re.split(">|\n<", line)[2]
                            if "<pref:Capacity>" in line:
                                Capacity = re.split(">|\n<", line)[2]
                            if "<wb:Price>" in line:
                                price = str(float(re.split(">|\n<", line)[2]) + 1)
                            if "<wb:EAN13>" in line:
                                EAN = re.split(">|\n<", line)[2]

                                insert1 = "INSERT IGNORE INTO tmc (bcode, vatcode1, vatcode2, vatcode3, vatcode4, vatcode5, dcode, name, articul, cquant, measure, pricetype, price, minprice, valcode, quantdefault, quantlimit, ostat, links, quant_mode, bcode_mode, op_mode, dept_mode, price_mode, tara_flag, tara_mode, tara_default, unit_weight, code, aspectschemecode, aspectvaluesetcode, aspectusecase, aspectselectionrule, extendetoptions, groupcode, remain, remaindate, documentquantlimit, age, alcoholpercent, inn, kpp, alctypecode, manufacturercountrycode, paymentobject, loyaltymode, minretailprice) VALUES ('"+ EAN +"',301,302,303,304,305,1,'"+ FullName + " " + Capacity + "л""','',1.000,2114,0,0.00,"+ price.split(".")[0] +".00,0,1.000,0.000,0,0,15,3,192,1,1,NULL,NULL,'0',NULL,'"+ FullName + " " + Capacity + "л""',NULL,NULL,NULL,NULL,NULL,NULL,0.000,NULL,2.000,NULL,15.00,NULL,NULL,0,NULL,NULL,0,0.00)"
                                insert2 = "INSERT IGNORE INTO barcodes (code, barcode, name, price, cquant, measure, aspectvaluesetcode, quantdefault, packingmeasure, packingprice, minprice, minretailprice, customsdeclarationnumber, tmctype) VALUES ('" + EAN + "','" + EAN + "','" + FullName + " " + Capacity + "л""'," + price.split(".")[0] + ",NULL,2,NULL,1.000,2,NULL,0.00,NULL,NULL,NULL)"

                                cursor.execute(insert1)
                                cursor.execute(insert2)
                                connection.commit()