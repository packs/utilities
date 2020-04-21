#!/usr/bin/python
# File    : check_surfboard_signal.py
# Author  : Scott Pack
# Created : April 2020
# Purpose : Polls a Surfboard cable modem for signal strength information 
#           suitable for ingestion by a Nagios compatible monitoring system.
#
#     Copyright (c) 2020 Scott Pack. All rights reserved.
#
from __future__ import print_function
from lxml import html
import argparse
import requests
import sys
import re

parser = argparse.ArgumentParser(description='Polls a Surfboard cable modem for \
    status information suitable for ingestion by a Nagios compatible monitoring system.')
group = parser.add_argument_group()
group.add_argument('-f', '--function', action='store', dest='func',
                   type=str, help='Moden statistic on which to report',
                   choices=['snr', 'power'], required=True)
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


# from https://arris.secure.force.com/consumers/articles/General_FAQs/SB6183-Cable-Signal-Levels
# Power levels are within the acceptable range of - 15 dBmV to + 15 dBmV for each downstream channel.
# If QAM64, SNR should be 23.5 dB or greater.
# If QAM256 and DPL( -6 dBmV to +15 dBmV) SNR should be 30 dB or greater.
# If QAM256 and DPL(-15 dBmV to -6 dBmV) SNR should be 33 dB or greater.

retval = state_ok
if( options.func == 'snr'):
    for chan in downStats:
        power = downStats[chan]['Power Level'].split()
        snr = downStats[chan]['Signal to Noise Ratio'].split()

        if( ( -6 <= int(power[0]) <= 15 ) and ( int(snr[0]) <= 35 ) and ( retval != state_critical ) ):
            retval = state_warning
        elif( (-6 <= int(power[0]) <= 15 ) and ( int(snr[0]) < 30 ) ):
            retval = state_critical
        elif( ( -15 <= int(power[0]) <= -6 ) and ( int(snr[0]) <= 38 ) and ( retval != state_critical ) ):
            retval = state_warning
        elif( (-6 <= int(power[0]) <= 15 ) and ( int(snr[0]) < 33 ) ):
            retval = state_critical
    if retval == state_ok:
        outMessage = "OK : Signal to Noise Ratios : "
    elif retval == state_warning:
        outMessage = "WARNING : Signal to Noise Ratios : "
    elif retval == state_critical:
        outMessage = "CRITICAL : Signal to Noise Ratios : "
    elif retval == state_unknown:
        outMessage = "UNKNOWN : Signal to Noise Ratios : "
    for chan in downStats:
        outMessage = outMessage + "Channel " + chan + " - " + downStats[chan]['Signal to Noise Ratio'] + " ; "
elif( options.func == 'power'):
    for chan in downStats:
        power = downStats[chan]['Power Level'].split()
        if( (abs(int(power[0])) <= 11 ) and retval != state_critical ):
            retval = state_warning
        elif( abs(int(power[0]) > 15)):
            retval = state_critical
        else:
            retval = state_unknown
    if retval == state_ok:
        outMessage = "OK : Power Levels : "
    elif retval == state_warning:
        outMessage = "WARNING : Power Levels : "
    elif retval == state_critical:
        outMessage = "CRITICAL : Power Levels : "
    elif retval == state_unknown:
        outMessage = "UNKNOWN : Power Levels : "
    for chan in downStats:
        outMessage = outMessage + "Channel " + chan + " - " + downStats[chan]['Power Level'] + " ; "

print (outMessage)
sys.exit(retval)