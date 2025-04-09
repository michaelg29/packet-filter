#!/bin/bash

ssh_machine=$1
hw_dir=$2
if [ -z "$ssh_machine" ]; then
	echo "First argument required to set ssh_machine"
	exit 1
fi
if [ -z "$hw_dir" ]; then
	hw_dir="packet-filter-hw"
fi

scp $ssh_machine:~/src/packet-filter/$hw_dir/\{output_files/soc_system.rbf,soc_system.dtb\} /mnt
sync

