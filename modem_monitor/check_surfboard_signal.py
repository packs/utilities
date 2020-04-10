#!/usr/bin/python
# File    : check_surfboard_signal.py
# Author  : Scott Pack
# Created : April 2020
# Purpose : Polls a Surfboard cable modem for signal strength information 
#           suitable for ingestion by a Nagios compatible monitoring system.
#
#     Copyright (c) 2020 Scott Pack. All rights reserved.
#
import argparse
from lxml import html
import requests
import sys
import re
import pprint

parser = argparse.ArgumentParser(description='Polls a Surfboard cable modem for \
    status information suitable for ingestion by a Nagios compatible monitoring system.')
group = parser.add_mutually_exclusive_group()
group.add_argument('-a', '--address', '--host', action='store', dest='addr',
                   type=str, help='Host name or IP address to query')
group.add_argument('-w', '--warn', action='store', dest='warn', default='75',
                   type=int, help='Warning threshold (default: 75)')
group.add_argument('-c', '--crit', action='store', dest='crit', default='90',
                   type=int, help='Critical threshold (default: 90)')
group.add_argument('-n', '--num', action='store', dest='numChan', default='4',
                   type=int, help='Number of bonding channels (default: 4)')

options = parser.parse_args()

state_ok = 0
state_warning = 1
state_critical = 2
state_unknown = 3

url = "http://" + options.addr + "/cmSignalData.htm"
numChan = options.numChan

page = requests.get(url)
tree = html.fromstring(page.content)
elements = tree.xpath('//tr/td//text()')

# Clean up some of junk elements, warning this may be Modem firmware dependent
regex = re.compile(r'(^\s+|The Downstream Power Level reading is a.*$)')
elements = [i.replace(u'\xa0', u'') for i in elements if not regex.match(i)]
elements = [i.replace('\n', '') for i in elements]
elements = [i.strip() for i in elements]

# Now we need to chop up the results to get only what we want
split = len(elements) - 1 - elements[::-1].index('Channel ID') 
keep = elements[:split]

# Now chunk to upstream and downstream info
split = len(keep) - 1 - keep[::-1].index('Channel ID') 
downstream, upstream = keep[:split], keep[split:]

downStats = {}
for i in range(1, numChan+1):
    tmpDict = {}
    for j in range(numChan+1,len(downstream)-numChan,numChan+1 ):
        tmpDict[downstream[j]] = downstream[j+i]
    downStats[downstream[i]] = tmpDict

pprint.pprint(downStats)

# if oprStatus == "Offline":
#     print("CRITICAL : Status", oprStatus)
#     retval = state_critical
# elif oprStatus == "Operational":
#     print("OK : Status", oprStatus)
#     retval = state_ok
# else:
#     retval = state_unknown

# sys.exit(retval)