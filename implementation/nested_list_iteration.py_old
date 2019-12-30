#!/usr/bin/python3


from ansible.module_utils.basic import AnsibleModule
import os
import random
import datetime
import yaml

class looping(object):

 def __init__(self):
  self.today = str(datetime.date.today())
  self.logf = open("error.log", "w")
  self.apics = open("apics.txt", "w")
  self.f = open("list_of_lists.yml", "r")
  self.list_of_lists = yaml.load(f)

 def run_module(self):
  self.ips_reachable = []
  self.ips_random = []


#####Loop to check ping test connectivity of all the initial list elements.

  for sub in self.list_of_lists:
          i = []
          for ip in sub:
                 #response = os.system("curl -kIX GET https://%s" % ip)
                  response = os.system("ping -i 0.2 -c 2 -W 1 %s" % ip)
                  if response == 0:
                          i.append(ip)
          self.ips_reachable.append(i)


######Loop to pick up random value from list and if condition to check for any empty lists

  for sub in self.ips_reachable:
          if not sub:
                  pass
          else:
                  self.random_ip = (random.choice(sub))
                  self.ips_random.append(random_ip)

#####Conditional to check if final list is empty, if so log to error.log file

  if len(self.ips_random) == 0:
          info = (today + ' - Failed to reach any APIC\n')
          logf.write(info)
  else:

          self.final_list = ' '.join(ips_random)

  self.apics.write(self.final_list)
  self.apics.close()
  self.logf.close()
  self.f.close()

  #####Main Ansible module to call above function

 def main():
     run_module = looping()
     #module = AnsibleModule(argument_spec={})
     module.exit_json(changed=False, meta=self.final_list)


if __name__ == '__main__':
    main()
