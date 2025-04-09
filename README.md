
# Ethernet packet filter

## Running instructions

Plug in mini-USB cable then connect on workstation
```
screen /dev/ttyUSB0 115200
```

All the commands below are now within this screen session

Turn on board
Login to `root` with password `CSee4840!`

Plug in ethernet
Connect to the network (expecting DHCPREQUEST, DHCPDISCOVER, DHCPREQUEST, DHCPOFFER, DHCACK messages)
```
root@de1-soc:~# ifup eth0
```

One-time setup
```
# unix packages
apt update
apt upgrade -y
apt install -y gcc make libusb-1.0-0-dev usbutils nano vim-tiny openssh-client wget git telnet kmod
apt clean

# linux headers
wget https://www.cs.columbia.edu/~sedwards/classes/2025/4840-spring/linux-headers-4.19.0.tar.gz
tar Pzxf linux-headers-4.19.0.tar.gz
ls /usr/src/linux-headers-4.19.0

# repository
mkdir -p src
cd src
git clone https://github.com/michaelg29/packet-filter
```

Generate files on the workstation:
```
LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/tools/intel/intelFPGA/21.1/quartus/linux64" make clean qsys quartus rbf
embedded_command_shell.sh
make dtb
exit # embedded_command_shell.sh
```

On FPGA, copy files:
```
mount /dev/mmcblk0p1 /mnt
scp mag2346@microXX.ee.columbia.edu:~/src/embedded-systems/embedded-systems/lab3/lab3-hw/output_files/soc_system.rbf /mnt
scp mag2346@microXX.ee.columbia.edu:~/src/embedded-systems/embedded-systems/lab3/lab3-hw/soc_system.dtb /mnt
sync
reboot # then login
```

On FPGA, run SW:
```
ifup eth0
cd src/packet-filter
git pull
cd packet-filter-sw
make
insmod packet_filter.ko
lsmod
./hello
rmmod packet_filter
```

