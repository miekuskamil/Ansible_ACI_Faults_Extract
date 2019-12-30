#!/usr/bin/python

'''Ansible module to test APIC reachibility on port 443 with netcat'''

import os
import random
import datetime
import yaml
from ansible.module_utils.basic import AnsibleModule


def run_module():

    ''' Initite lists. Iterate over nested lists. Nesting required to group APICs by environement'''

    today_date = str(datetime.date.today())
    log_file = open("error.log", "w")
    apics = open("apics.txt", "w")
    apics_file = open("list_of_lists.yml", "r")
    list_of_lists = yaml.load(apics_file)
    ips_reachable = []
    ips_random = []

#####Loop to check ping test connectivity of all the initial list elements.

    for sub in list_of_lists:
        ip_reachable = []
        for ip_address in sub:
            response = os.system("nc -w 2 -vz  %s 443" % ip_address)
            if response == 0:
                ip_reachable.append(ip_address)
        ips_reachable.append(ip_reachable)


######Loop to pick up random value from list and if condition to check for any empty lists

    for sub in ips_reachable:
        if not sub:
            pass
        else:
            random_ip = (random.choice(sub))
            ips_random.append(random_ip)

#####Conditional to check if final list is empty, if so log to error.log file

    if ips_random:
        final_list = ' '.join(ips_random)
        apics.write(final_list)
    else:
        info = (today_date + ' - Failed to reach any APIC\n')
        log_file.write(info)
        apics.write('None returned')

    apics.close()
    log_file.close()
    apics_file.close()

    return final_list

#####Main Ansible module to call above function

def main():

    '''Initiate  Ansible module'''

    final = run_module()
    module = AnsibleModule(argument_spec={})
    module.exit_json(changed=False, meta=final)


if __name__ == '__main__':
    main()
