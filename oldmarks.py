#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, re
import xml.etree.ElementTree as ET

tree = ET.parse("WayBill_v3.xml")
root = tree.getroot()
#[0][7][1][0][1]
x=0
for lvlOne in root[1][0][2]:
    for lvlTwo in lvlOne[7][1]:
        print(lvlTwo.tag + " ")

#
# #!/usr/bin/env python
# # -*- coding: utf-8 -*-
#
# import os, re
# import xml.etree.ElementTree as ET
#
# tree = ET.parse("WayBill_v3.xml")
# root = tree.getroot()
# #[0][7][1][0][1]
# x=0
# for lvlOne in root[1][0][2]:
#     for lvlTwo in lvlOne[7][1]:
#         for lvlThree in lvlTwo[1]:
#             x+=1
#             print(lvlThree.text + " " + lvlTwo.find("ShortName"))
