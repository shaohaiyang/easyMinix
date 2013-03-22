#!/bin/sh
DEV="/dev/sdc"
LABEL="/Amy"
LABEL_SWAP="/SWAP"
UPYUN_DIR="/root/upyun_work"
UP_MOCCA=mocha.tgz

read -p "You must supply a network configration. (`pwd`/network.info)" NETWORK_CONF
[ -z $NETWORK_CONF ] && NETWORK_CONF="`pwd`/network.info"
# make a whole partition for all sata drivers.
#PARTS=$(fdisk -l $DEV|awk '/^\/dev/{print substr($1,9)}')
fdisk $DEV<<EOF
d
4
d
3
d
2
d
1
n
p
1
1
+2G
n
p
2

+1G
n
p
3


t
2
82
a
1
w
EOF
partprobe $DEV

mkfs.ext4 -L $LABEL ${DEV}1
mkswap -L $LABEL_SWAP ${DEV}2
mount ${DEV}1 /mnt

cd $UPYUN_DIR/mini_os/;tar cvf - *|(cd /mnt;tar xvf -);cd -
cp -a $UPYUN_DIR/$UP_MOCCA /mnt/root/
cp -a $NETWORK_CONF /mnt/
mkdir -m 600 -p /mnt/root/.ssh
cp -a /root/.ssh/authorized_keys /mnt/root/.ssh

grub-install --root-directory=/mnt --no-floppy --recheck $DEV
umount /mnt
