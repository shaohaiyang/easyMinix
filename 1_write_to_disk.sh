#!/bin/bash
###################################################
# detect how many ssd or sata disk inside machine and classifily them.
SSD_DRVS=/root/.ssd
#DEVS=$(lsscsi | awk 'BEGIN{IGNORECASE=1}{if($2=="disk") print $NF}') # Bug; some Raid mode return -
DEVS=$(fdisk -l|awk '/^Disk \//{split($2,a,":");print a[1]}')

rm -rf $SSD_DRVS $SSD_DRVS.sin /tmp/.install_to_disk

SIZE_MIN=2000000000000 # 2TB Disk
for dev in $DEVS;do
	smartctl -i $dev|grep -iq usb
        [ $? = 0 ] && echo $dev > /tmp/.install_to_disk

	SIN=$(smartctl -i $dev|grep -i "serial number"|awk '{print $3}')
	echo -e "$YELLOW_COL|||  ${dev}\t$SIN\t\tSSD";echo $dev >> $SSD_DRVS.sin

	#smartctl -i $dev|grep -i 'Device Model'|egrep -iq "ssd|kingston|samsung|solid|st[1-9][0-9][0-9][A-Za-z]" # Bug: some disk have none model
	SIZE=$(fdisk -l $dev |sed -r -n '/sectors$/s@.*, (.*) bytes.*@\1@gp')
	if [ $SIZE -gt 100000000000 ] && [ $SIZE -lt 2000000000000 ];then # bigger than 100G and small than 2T, it is ssd
		if [ $SIZE -lt $SIZE_MIN ];then
			SIZE_MIN=$SIZE
			DEV_MIN=$dev
		fi
	fi
done
echo "$DEV_MIN" > $SSD_DRVS
###################################################
[ ! -e /tmp/.install_to_disk ] && echo "You don't have USB Disk,could not install to hard disk." && exit 0
###################################################
if [ -s /root/.boot_disk ];then
	read -n1 -p "Do You really want to install again?" ANSWER
	ANSWER=`echo $ANSWER|tr 'A-Z' 'a-z'`

	if [ $ANSWER = "y" ];then
		echo `df -h|awk '($NF=="/"){print $1}'`|grep -iq `cat /tmp/.install_to_disk`
		if [ $? != 0 ] ;then
			echo -e "\nYou system is running on disk,install is abnormal.\n"
			exit 0
		else
			rm -rf /root/.boot_disk
		fi
	else
		echo -e "\nInstallation is quit.\n" && exit 0
	fi
fi
echo -e "\n============================================"
###################################################
DEV=`cat $SSD_DRVS`
# make a whole partition for all sata drivers.
FORMAT_FORCE="y"
if [ $FORMAT_FORCE = "y" ];then
while read dev;do
        fdisk $dev<<EOF
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

+20480M
n
p
2

+4096M
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
partprobe $dev
partx -a $dev
sleep 3
done < $SSD_DRVS

mkfs.ext4 -F -L /AmyC ${DEV}1
mkswap -L /SWAPC ${DEV}2
fi

mount ${DEV}1 /mnt/
cd /
tar zcvf - --exclude=dev --exclude=run --exclude=mnt --exclude=proc --exclude=sys --exclude=tmp * | (cd /mnt;tar zxvf -)
mkdir -p /mnt/{dev,run,mnt,proc,sys,tmp}
chmod 1777 /mnt/tmp

echo "Install grub bootloader..."
grub-install --root-directory=/mnt --no-floppy --recheck --force $DEV

echo "Rebuild grub menuentry..."
sed -r -n '/menuentry /,/}/p' /boot/grub/grub.cfg|sed -r 's@Amy@AmyC@;s@MINIOS@UPOS@g' > new.cfg
sed -r -i '/set timeout_style=menu/r new.cfg' /boot/grub/grub.cfg
sed -r -i '/set default="[0-9]/s@=.*@="1"@' /boot/grub/grub.cfg
echo "${DEV}3" > /root/.boot_disk
cp -a /boot/grub/grub.cfg /mnt/boot/grub/
sed -r -i '/HOSTNAME/s@MINIOS@UPOS@g' /mnt/network.info
sed -r -i 's:Amy:AmyC:g; s:SWAP:SWAPC:g' /mnt/etc/fstab
echo "${DEV}3" > /mnt/root/.boot_disk
umount /mnt
