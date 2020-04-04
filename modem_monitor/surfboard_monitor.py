#!/usr/bin/python
# File    : surfboar_monitor.py
# Author  : Scott Pack
# Created : April 2020
# Purpose : Polls a Surfboard cable modem for status information suitable
#           for ingestion by a Nagios compatible monitoring system.
#
#     Copyright (c) 2020 Scott Pack. All rights reserved.
#
import argparse
from lxml import html
import requests

parser = argparse.ArgumentParser(description='Polls a Surfboard cable modem for \
    status information suitable for ingestion by a Nagios compatible monitoring system.')
group = parser.add_mutually_exclusive_group()
group.add_argument('-a', '--address', '--host', action='store', dest='addr',
                   help='Host name or IP address to query')
group.add_argument('-w', '--warn', action='store', dest='warn', default='75',
                   help='Warning threshold (default: 75)')
group.add_argument('-c', '--crit', action='store', dest='crit', default='90',
                   help='Critical threshold (default: 90)')

options = parser.parse_args()


url = 'http://' + options.addr + '/indexData.htm'
page = requests.get(url)
tree = html.fromstring(page.content)
elements = tree.xpath('//tr/td//text()')
allStatuses = {elements[i]: elements[i + 1] for i in range(0, len(elements), 2)} 
oprStatus = allStatuses['Cable Modem Status']

print(oprStatus)
