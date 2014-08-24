#!/bin/bash

# Gets IP addresses of running instances.
# Typically used to get information about instances which are set up
# using DHCP in qemu/kvm, though it should ideally work for any setup.

for instance in $(virsh list|awk '/running/{print $2}')
do
        MAC="$(virsh dumpxml $instance | awk -F\' '/mac address/{print $2}')"

        printf "$instance: "
        arp -e | grep ${MAC} | awk '{print $1,$3}'
done
