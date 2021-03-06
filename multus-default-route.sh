#!/bin/bash
##########################################################################################################################################################################################
## Created by John Lam  (Nokia NSW CS&C CCH)	
## Email: john.lam@nokia.com
## Contributor: Piyush Shewkani (Nokia NSW CS&C CCH)
## This script was created to bypass the Multus limitation where default routes cannot be defined during Network CRD creation
## Ideally this script can me mounted using a configMap with an Init Container. For testing purpose , you can run this scripts once the POD is created depending on your privlege level
## Enhancements (Piyush Shewkani) : Added multiple interface route manipulation using conditional loops 
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
############### Get Multus interface names, number of interfaces attached and set a count variable for conditional loop below  ############
C=1
MULTUS_INT_NAMES=$(ip -o -4 addr list | grep -w 'lo\|eth0' -v | awk '{print $2}')
IF_COUNT=$(ip -o -4 addr list | grep -w 'lo\|eth0' -v -c)

############### Conditional loop to configure route tables for each Multus interface ############
while [[ $C -le $IF_COUNT ]]; do
		############### STORING VARIABLES ##############################
	#Get first interface name from MULTUS_INT_NAMES variable
	CURRENT_INT=$(echo $MULTUS_INT_NAMES | awk -v C=$C '{print $C}')
	#store ip address of current interface as a variable $ip4
	ip4=$(/sbin/ip -o -4 addr list $CURRENT_INT | awk '{print $4}' | cut -d/ -f1)

	#store network ID of current interface as variable $ipsub
	ipsub=$(ip route | grep $CURRENT_INT | awk '{print $1}')

	#store subnet without the "/"  as variable $subval
	netsubval=$(route -n | grep -w $CURRENT_INT | awk '{print $1}')

	#Since multus does not push the Gateway for net1 into the routing table, I was able to acquire the GW by taking the $netsubval viariable and adding +1 to the last octet, storing in variable $gw
	#Note the below command assumes the GW is the 1st IP after the network ID. This assumtion is made specific to the project CIQ. Eg if your network is 10.46.90.224/27 , the GW will be 10.46.90.225 (10.46.90.224+1).
	# Alternatively you can change the $gw value with your IP GW or call the variable using a values.yaml file when using helm
	gw=$(echo $netsubval |awk -F. '{ print $1"."$2"."$3"."$4+1 }')

	################ CONFIGURE ROUTING #############################
	# Add route tables (t1,t2,t3...tn) if not present in the rt_table with sequence (100,101,102...n) 
	grep "t$C" /etc/iproute2/rt_tables || echo 10$C t$C >> /etc/iproute2/rt_tables
	ip route show table t$C | grep $ip4 || ip route add $ipsub dev $CURRENT_INT src $ip4 table t$C
	ip route show table t$C | grep default ||ip route add table t$C default via $gw dev $CURRENT_INT
	ip rule add table t$C from $ip4
	sysctl net.ipv4.conf.default.arp_filter=1
	C=$((C + 1))
done
