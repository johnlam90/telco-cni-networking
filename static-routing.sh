#!/bin/bash 

#Custom static routes to for bidirectional communications while specifying interfaces. A config Map must be created and mounted using an init container 


#Example 

#ip route add 10.46.87.6/32 via 10.46.90.225 dev net1
#ip route add 10.46.87.5/32 via 10.46.88.141 dev net2 
