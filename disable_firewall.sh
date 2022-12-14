#!/bin/bash

# Reset iptables to avoid getting locked out

iptables -F   #Flush all chains
iptables -X   #Delete optional chains
iptables -Z   #Zero packet count
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
