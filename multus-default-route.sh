#!/bin/bash

##########################################################################################################################################################################################
## Created by John Lam  (Nokia NSW CS&C CCH)	
## Contributor: Piyush Shewkani (Nokia NSW CS&C CCH)
## Email: john.lam@nokia.com
## This script was created to bypass the Multus limitation where default routes cannot be defined during Network CRD creation
## Ideally this script can me mounted using a configMap with an Init Container. For testing purpose , you can run this scripts once the POD is created depending on your privlege level
## Enhancements (Piyush Shewkani) : Added multiple interface route manipulation using loops 
##########################################################################################################################################################################################


########### PACKAGE INSTALLATION ################################
#Install iproute2 and net-tools to create route tables and view ip/route info
yum install which -y
apk add which

PACKAGE1=iproute2
PACKAGE2=net-tools
PACKAGE3=iproute
#This condition will check for distro and install packages based on that
YUM_CMD=$(which yum)
APK_CMD=$(which apk)
if [[ ! -z $YUM_CMD ]]; then
   yum install -y $PACKAGE3
   yum install -y $PACKAGE2
elif [[ ! -z $APK_CMD ]]; then
   apk add $PACKAGE1
   apk add $PACKAGE2
else
   echo "error can't install package $PACKAGE"
   exit 1;
fi


############### STORING VARIABLES ##############################
#store ip address of net1 as a variable $ip4
ip4=$(/sbin/ip -o -4 addr list net1 | awk '{print $4}' | cut -d/ -f1)

#store ip subnet of net1 as variable $ipsub
ipsub=$(ip route | awk '/proto/ && !/default/ {print $1}')

#store subnet without the "/"  as variable $subval
subval=$(route -n | grep -w 'U' | awk '{print $1}')

#Since multus does not push the Gateway for net1 into the routing table, I was able to acquire the GW by taking the $subval viariable and adding +1 to the last octet, storing in variable $gw
#Note the below command assumes the GW is the 1st IP after the network ID. This assumtion is made specific to the project CIQ. Eg if your network is 10.46.90.224/27 , the GW will be 10.46.90.225 (10.46.90.224+1).
# Alternatively you can change the $gw value with your IP GW or call the variable using a values.yaml file when using helm
gw=$(echo $subval |awk -F. '{ print $1"."$2"."$3"."$4+1 }')


################ CONFIGURE ROUTING #############################
# Add route table "t2" if not present in the rt_table 
grep "t2" /etc/iproute2/rt_tables || sed -i '1s/^/100  t2 \n/' /etc/iproute2/rt_tables
ip route show table t2 | grep $ip4 || ip route add $ipsub dev net1 src $ip4 table t2
ip route show table t2 | grep default ||ip route add table t2 default via $gw dev net1
ip rule add table t2 from $ip4
sysctl net.ipv4.conf.default.arp_filter=1
