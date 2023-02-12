#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import os
import requests
import xml.etree.ElementTree as ET
import urllib.parse
import json
import datetime


def get_dateRSA(port):
    date_RSA = requests.get("http://localhost:" + port + "/api/certificate/RSA").text  # [900:928]
    findIndex_RSA = date_RSA.find("To")
    date_RSA = date_RSA[findIndex_RSA + 4: findIndex_RSA + 33].replace(r']', '')
    date_RSA = date_RSA[:20] + date_RSA[24:]
    return datetime.datetime.strptime(date_RSA, '%a %b %d %H:%M:%S %Y')


def generate_pki(port, dateRSA, endDays):
    if len(sys.argv) == 2:
        if datetime.datetime.now() <= dateRSA - datetime.timedelta(days=endDays):
            print("\033[31m{}\033[0m".format(
                "Срок действия PKI не истекает через" + endDays + "дней. Он истекает " + datetime.datetime.strftime(dateRSA, '%d %B %Y %H:%M:%S')))
            exit()

    fsrar = ET.fromstring(requests.get(url=r"http://localhost:" + port + "/diagnosis").text).find('CN').text
    for shop in json.loads(requests.get(url="http://localhost:" + port + "/api/rsa").text)['rows']:
        if shop['Owner_ID'] == fsrar:
            if shop['KPP']:
                request = requests.get(url="http://localhost:" + port + "/api/rsa/keygen?" +
                                           "INN=" + str(shop['INN']) + "&" +
                                           "KPP=" + str(shop['KPP']) + "&" +
                                           "factAddress=" + urllib.parse.quote(shop['Fact_Address']) + "&" +
                                           "fsrarid=" + fsrar + "&" +
                                           "fullName=" + urllib.parse.quote(shop['Full_Name']) + "&" +
                                           "id=" + str(shop['ID']))
                if request.ok:
                    print("\033[32m{}\033[0m".format("PKI успешно перезаписан"))
                    with open('/linuxcash/net/server/server/logs/generatePKI.log', 'a+') as log:
                        log.write(datetime.datetime.strftime(datetime.datetime.now() ,"%Y/%m/%d %H:%M:%S") + " " + os.uname()[1] + " " + port + "\n")
                else:
                    print("\033[31m{}\033[0m".format(request.text))
            else:
                print("\033[31m{}\033[0m".format("ИП УТМ не перезаписываю"))


def main(port):
    try:
        status_UTM = requests.get("http://localhost:" + port).ok
    except Exception as ex:
        print("\033[31m{}\033[0m".format(ex))
        status_UTM = False

    if status_UTM:
        date_RSA = get_dateRSA(port)
        generate_pki(port, date_RSA, 90)


if __name__ == '__main__':
    main("8082")
else:
    main(str(sys.argv[1]))
