#!/usr/bin/bash
DEV="/dev/sdd"
LABEL="/Amy"
LABEL_SWAP="/SWAP"
UPYUN_DIR="/root/work"
MOUNT="/media"
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

n
p
1

+1500M
n
p
2


a
1
w
EOF
partprobe $DEV
partx -a $DEV

#mkfs.xfs -f ${DEV}1
#xfs_admin -L $LABEL ${DEV}1
mkfs.ext4 -L $LABEL ${DEV}1
mount ${DEV}1 $MOUNT
cp -a $NETWORK_CONF $MOUNT/
exit

cd $UPYUN_DIR/mini_os/;tar cvf - *|(cd $MOUNT;tar xvf -);cd -
cp -a $UPYUN_DIR/$UP_MOCCA $MOUNT/root/
mkdir -m 600 -p $MOUNT/root/.ssh
cp -a /root/.ssh/authorized_keys $MOUNT/root/.ssh
cp -a `pwd`/ceph_id_rsa  $MOUNT/root/.ssh/id_rsa
cat `pwd`/ceph_authorized_keys >> $MOUNT/root/.ssh/authorized_keys
sed -r -i '/^PasswordAuthentication/s:.*:PasswordAuthentication no:' $MOUNT/etc/ssh/sshd_config
grub-install --root-directory=$MOUNT --no-floppy --recheck $DEV
umount $MOUNT
