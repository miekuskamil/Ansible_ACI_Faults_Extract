#!/usr/bin/python
import os
import random
import datetime

today = str(datetime.date.today())  
logf = open("error.log", "w")

list_of_lists = [['sandboxapicdc.cisco.com']]


ips_reachable = []
ips_random = []

#####Loop to check ping test connectivity of all the initial list elements.

for sub in list_of_lists:
        i = []
        for ip in sub:
                response = os.system("nc -vz  %s 443" % ip)
                if response == 0:
                        i.append(ip)
        ips_reachable.append(i)


######Loop to pick up random value from list and if condition to check for any empty lists

for sub in ips_reachable:
        if not sub:
                pass
        else:
                random_ip = (random.choice(sub))
                ips_random.append(random_ip)

#####Conditional to check if final list is empty, if so log to error.log file

if len(ips_random) == 0:
        info = (today + ' - Failed to reach any APIC\n')
        logf.write(info)
else:
        print ' '.join(ips_random)
