#!/bin/bash


###FUNCTIONS
newline () {
echo -ne "\n"
}



###GLOBAL
today=$(date +%Y-%m-%dT%H:%M:%S )
yesterday=$(date +%Y-%m-%dT%H:%M:%S --date="1 day ago")
today_short=$(date +%Y-%m-%d)
today_line=$(date +%Y-%m-%d-%H:%M)
yesterday_line=$(date +%Y-%m-%d-%H:%M --date="1 day ago")



###REACHIBILITY CHECK
declare -a arr
arr+=($(python nested_list_iteration.py | tail -n1 ))
#echo "${arr[@]}"



###LIST FOR LOOP
for ip in "${arr[@]}"
do
	file=$(echo ${ip}_faults_daily_report-$(date +%Y-%m-%d-%H-%M).html)
	echo -ne "\nWorking on: $ip ..."

###API CALLS

	operational_ansible=$(ansible-playbook faults_playbook.yml -i ../inventories/inventory.txt --vault-password-file ../vault.txt --limit "sandboxapicdc.cisco.com," --tags="operational_faults" --extra-vars "today=$today yesterday=$yesterday") 
        operational_ansible_cut=$(echo -ne "$operational_ansible" | egrep -i -A20 --group-separator=$'\n----------\n' "ack" | tr -d \, | sed -e 's/^[ \t]*//')
	sleep 1



	config_ansible=$(ansible-playbook faults_playbook.yml -i ../inventories/inventory.txt --vault-password-file ../vault.txt --limit "sandboxapicdc.cisco.com," --tags="config_faults" --extra-vars "today=$today yesterday=$yesterday")
	config_ansible_cut=$(echo -ne "$config_ansible" | egrep -i -A20 --group-separator=$'\n----------\n' "\"ack\"" | tr -d \, | sed -e 's/^[ \t]*//')
	sleep 1



	communications_ansible=$(ansible-playbook faults_playbook.yml -i ../inventories/inventory.txt --vault-password-file ../vault.txt --limit "sandboxapicdc.cisco.com," --tags="communications_faults" --extra-vars "today=$today yesterday=$yesterday")
        communications_ansible_cut=$(echo -ne "$communications_ansible" | egrep -i -A20 --group-separator=$'\n----------\n' "\"ack\"" | tr -d \, | sed -e 's/^[ \t]*//')
	sleep 1



	environmental_ansible=$(ansible-playbook faults_playbook.yml -i ../inventories/inventory.txt --vault-password-file ../vault.txt --limit "sandboxapicdc.cisco.com," --tags="environmental_faults" --extra-vars "today=$today yesterday=$yesterday")
        environmental_ansible_cut=$(echo -ne "$environmental_ansible" | egrep -i -A20 --group-separator=$'\n----------\n' "\"ack\"" | tr -d \, | sed -e 's/^[ \t]*//')
	sleep 1


###CONDITIONALS ON JSON EXTRACTS
	        if [[ "echo $operational_ansible" == *'"totalCount": 0'* ]]; then
                	operational=$(echo -ne "\nNO FAULTS BETWEEN $yesterday_line and $today_line\n")
                	sleep 1
        	else
                	operational=$(echo -ne "\nFAULTS BETWEEN $yesterday_line and $today_line:\n$operational_ansible_cut\n")
                	sleep 1
        	fi


		if [[ "echo $config_ansible" == *'"totalCount": 0'* ]]; then      	
			config=$(echo -ne "\nNO FAULTS BETWEEN $yesterday_line and $today_line\n\n")
			sleep 1
		else
			config=$(echo -ne "\nFAULTS BETWEEN $yesterday_line and $today_line:\n\n$config_ansible_cut\n")
          	        sleep 1
		fi



	        if [[ "echo $communications_ansible" == *'"totalCount": 0'* ]]; then
	                communications=$(echo -ne "\nNO FAULTS BETWEEN $yesterday_line and $today_line\n\n")
        	        sleep 1
        	else
                        communications=$(echo -ne "\nFAULTS BETWEEN $yesterday_line and $today_line:\n\n$communications_ansible_cut\n")            	
			sleep 1
        	fi



        	if [[ "echo $environmental_ansible" == *'"totalCount": 0'* ]]; then
                	environmental=$(echo -ne "\nNO FAULTS BETWEEN $yesterday_line and $today_line\n\n")
                	sleep 1
        	else
                        environmental=$(echo -ne "\nFAULTS BETWEEN $yesterday_line and $today_line:\n\n$environmental_ansible_cut\n")
                	sleep 1
        	fi


###HTML FORM

		echo -ne "
		<pre><strong>OPERATIONAL</strong> - The system has detected an operational issue, such as a log capacity limit or a failed component discovery</pre>
		<pre><strong>CONFIG</strong> - The system is unable to successfully configure a specific component</pre>
		<pre><strong>COMMUNICATIONS</strong> - This fault happens when the system has detected a network issue such as a link down</pre>
		<pre><strong>ENVIRONMENTAL</strong> - The system has detected a power problem, thermal problem, voltage problem, or a loss of CMOS settings</pre>
		<table valign='top' style='width: 1000px; float: left; background-color: #f5b286;' border='1'>
		<tbody>
		<tr>
		<td valign='top' style='width: 500px; text-align: center;'><span style='color: #000000;'><strong>OPERATIONAL</strong></span></td>
		<td valign='top' style='width: 500px;'><pre>$operational</pre></td>
		</tr>
		<tr>
		<td valign='top' style='width: 500px; text-align: center;'><span style='color: #000000;'><strong>CONFIG</strong></span></td>
		<td valign='top' style='width: 500px;'><pre>$config</pre></td>
		</tr>
		<tr>
		<td valign='top' style='width: 500px; text-align: center;'><span style='color: #000000;'><strong>COMMUNICATIONS</strong></span></td>
		<td valign='top' style='width: 500px;'><pre>$communications</pre></td>
		</tr>
		<tr>
		<td valign='top' style='width: 500px; text-align: center;'><span style='color: #000000;'><strong>ENVIRONMENTAL</strong></span></td>
		<td valign='top' style='width: 500px;'><pre>$environmental</pre></td>
		</tr>
		</tbody>
		</table>" > $file
done

###MAIL CALL

		ansible-playbook mail_playbook.yml
                rm -r *.html

newline
