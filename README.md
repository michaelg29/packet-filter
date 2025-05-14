
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
git clone https://github.com/michaelg29/packet-filter
cd packet-filter
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
cd packet-filter-hw
bash fpga_get_hw.sh <USER@MACHINE> <REMOTE_PATH_TO_packet-filter-hw>
reboot # then login
```

On FPGA, run SW:
```
ifup eth0
cd src/packet-filter
git pull
cd packet-filter-sw
make MODULE=frame_generator_0
make MODULE=packet_filter
make MODULE=frame_receptor_0
insmod frame_generator_0.ko
insmod packet_filter.ko
insmod frame_receptor_0.ko
lsmod
./hello
rmmod packet_filter
```

