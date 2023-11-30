#!/bin/bash
FTYPE="ext4"
###################################################
export LC_ALL=en_US.utf8
unalias cp
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
        if [ $SIZE -gt 100000000000 ] && [ $SIZE -lt 1000000000000 ];then # bigger than 100G and small than 1T, it is ssd
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
FTYPE=${FTYPE,,}
DEV=`cat $SSD_DRVS`
# make a whole partition for all sata drivers.
FORMAT_FORCE="y"
if [ $FORMAT_FORCE = "y" ];then
# make a whole partition for all sata drivers.
for part in $(parted -s $DEV print|awk '/^ /{print $1}');do
        parted -s $DEV rm $part
done
parted -s $DEV  mklabel msdos mkpart primary $FTYPE 1M 40G
parted -s $DEV  mkpart primary linux-swap 40G 48G
parted -s $DEV  mkpart primary $FTYPE 48G 100%
parted -s $DEV  set 1 boot on
partprobe $DEV
partx -a $DEV
mkswap -L /SWAPC ${DEV}2
if [ $FTYPE = "xfs" ];then
	mkfs.xfs -f ${DEV}1
	mkfs.xfs -f ${DEV}3
	xfs_admin -L /AmyC ${DEV}1
	xfs_admin -L /disk/ssd1 ${DEV}3
else
	mkfs.ext4 -L /AmyC -F ${DEV}1
	mkfs.ext4 -L /disk/ssd1 -F ${DEV}3
fi
fi

mount ${DEV}1 /mnt/
cd /
tar zcvf - --exclude={dev,run,proc,sys,mnt,tmp} * | (cd /mnt;tar zxvf -)
mkdir -p /mnt/{dev,run,mnt,proc,sys,tmp,disk/ssd1}
chmod 1777 /mnt/tmp

echo "Install grub bootloader..."
grub2-install --root-directory=/mnt --no-floppy --recheck --force $DEV

echo "======    Rebuild GRUB2 MenuEntry   ======"
sed -r -i '/UPOS /,$d' /boot/grub2/grub.cfg
sed -r -n '/menuentry /,/}/p' /boot/grub2/grub.cfg | sed -r 's@Amy@AmyC@;s@MINIOS@UPOS@g' > new.cfg
sed -r -i '$r new.cfg' /boot/grub2/grub.cfg
sed -r -i '/set default=/s@=.*@=1@g' /boot/grub2/grub.cfg
rm -rf new.cfg
echo "${DEV}3" > /root/.boot_disk
cp -a /boot/grub2/grub.cfg* /mnt/boot/grub2/
sed -r -i '/HOSTNAME/s@=.*@=UPOS@g' /mnt/network.info
cat > /mnt/etc/fstab <<EOF 
LABEL=/AmyC	    /		$FTYPE	defaults  0 0
LABEL=/SWAPC	    swap	swap	defaults  0 0
LABEL=/disk/ssd1    /disk/ssd1  $FTYPE	defaults  0 0
EOF
echo "${DEV}" > /mnt/root/.boot_disk
umount /mnt
