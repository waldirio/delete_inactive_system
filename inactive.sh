#!/bin/bash

#
# Date .....: 10/22/2018
# Dev ......: Waldirio Pinheiro <waldirio@redhat.com / waldirio@gmail.com>
# Purpose ..: Check all inactive systems after x Days and then remove it from Satellite
# Note .....:
# 	      Will be filled a new RFE to do this action, this script is just to help you while we don't provide
#	      this feature yet. Red Hat will not support this routine on the future.
# 

LOG="/var/log/inactive_satellite.log"
MIN_DAYS=6

# Initial time
echo "Starting"		| tee -a $LOG
$(echo date) 		| tee -a $LOG

# Generate the list of Content Hosts with lastcheckin greather then MIN_DAYS
su - postgres -c  "echo \"select name,lastcheckin from cp_consumer where lastcheckin < now() - interval '$MIN_DAYS days' order by lastcheckin\"|psql candlepin" >/tmp/list_inactives.log	| tee -a $LOG

# Content Hosts without update for a while (only hostname)
cat /tmp/list_inactives.log | grep "|" | awk '{print $1}' | sed -e 's/^ //g' | grep -v ^name$ > /tmp/ch_to_be_removed.log	| tee -a $LOG

# List of all Content Hosts (complete list)
su - postgres -c "echo \"select name from hosts\" | psql foreman" > /tmp/complete_ch_list.log					| tee -a $LOG

# The same list as above but now clear/filtered
cat /tmp/complete_ch_list.log | sed -e 's/^ //g' | grep -v ^$ | grep -v ^\( | grep -v ^--- | grep -v "   name   " > /tmp/complete_ch_list_only_hostname.log	| tee -a $LOG

# To clear the file all run
>/tmp/result.log	| tee -a $LOG

# Collecting the name of the Content Host according to the initial list
while read line
do
  #echo - $line
  result_query=$(grep -i "$line" /tmp/complete_ch_list_only_hostname.log | tee -a $LOG)
  if [ $? -eq 0 ]; then
    echo $result_query >>/tmp/result.log	| tee -a $LOG
  fi
done < /tmp/ch_to_be_removed.log

# Here is the command to remove the system from Satellite ** THIS WILL JUST SHOW YOU THE MACHINES AND COMMANDS **
for b in $(cat /tmp/result.log); do echo - Removing $b; echo "hammer host delete --name $b"; done	| tee -a $LOG

# This will delete, to proceed, uncomment line below and rerun the script.
# for b in $(cat /tmp/result.log); do echo - Removing $b; echo "hammer host delete --name $b";hammer host delete --name $b; done	| tee -a $LOG

# Final time
echo "Ending"	| tee -a $LOG
$(echo date) 	| tee -a $LOG
