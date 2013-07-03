#!/bin/sh
MOUNTROOT="/root/work/mini_os"
PUPPET_TOOL="1"
KERNEL_VER="3.8.13.upyun"
SERVICES="crond network local sshd rsyslog"
LABEL="/Amy"
LABEL_SWAP="/SWAP"

[ -z $KERNEL_VER ] && KERNEL_VER=$(uname -r)

NET_DRIVER=$(dmesg|awk '{IGNORECASE=1}/eth.* link up/{print $1}'|head -1)
BIN="awk sh cat chown date dmesg find env egrep gawk hostname ln mkdir mknod mktemp more netstat pwd stty touch uname basename chgrp cp df false grep ipcalc login mount ping rm sleep sync true usleep bash chmod cut echo fgrep gzip kill ls mv ps sed sort tar umount vi dd traceroute plymouth dbus-cleanup-sockets dbus-daemon dbus-monitor dbus-send dbus-uuidgen zcat"
SBIN="arp agetty chkconfig ethtool e2label halt ifup udevd udevadm partx partprobe pidof runlevel rmmod arping hdparm init initctl ldconfig shutdown tune2fs consoletype fdisk hwclock mingetty swapoff telinit dhclient fsck fsck.ext4 ifconfig ip mke2fs poweroff plymouthd swapon sushell dhclient-script ifdown iptables mkfs.ext3 mkfs.ext4 reboot sysctl killall5 mkswap route rsyslogd tc insmod lsmod modprobe start_udev fstab-decode MAKEDEV"
USR_BIN="bc bzip2 chage du diff dig vim file groups ldd passwd pkill ssh tty w whereis clear less ssh-add wc whoami expr free id logger scp ssh-keygen screen strace seq uniq uptime wget which dirname tput xargs top tr md5sum nohup nc nslookup head tail tee telnet rsync"
USR_SBIN="adduser brctl lsof crond ntpdate sshd useradd usermod userdel ntpdate ntpd tcpdump hald"
PUPPET_USR_BIN="puppet filebucket pi puppetdoc ralsh facter ruby erb"
PUPPET_USR_SBIN="puppetca puppetd"

rm -rf $MOUNTROOT
mkdir $MOUNTROOT
cd $MOUNTROOT
mkdir -p bin boot dev etc sys lib/modules lib64/{modules,security,tls} home mnt proc root sbin tmp usr/{bin,sbin,lib,lib64,libexec,local,share} var/{empty,lock,run,spool,lib,www,log}
mkdir -p usr/local/{etc,bin,sbin,lib,lib64,include,libexec,share}
mkdir -p usr/lib64/perl5/CORE var/run/netreport var/{run,lib}/dbus
mkdir -p usr/share/{locale,misc,zoneinfo} var/empty/sshd var/lock/subsys var/spool/cron var/lib/dhcp 

bincp(){
	rm -rf /tmp/bin.tmp
	for i in $BIN;do
		cp -a /bin/$i $MOUNTROOT/bin/
		for j in `ldd /bin/$i`;do
			[ -f $j ] && echo $j >> /tmp/bin.tmp
		done
	done
	sort -ru /tmp/bin.tmp > /root/bin.txt

	for i in `cat /root/bin.txt`;do
		DIR=$(dirname $i)
		cp -a $i $MOUNTROOT/$i
		[ -L $i ] && (cp -a $DIR/`ls -al $i | awk -F'->' '{print $2}'|sed -r 's: ::g'` $MOUNTROOT/$DIR)
	done
}

sbincp(){
        rm -rf /tmp/sbin.tmp
        for i in $SBIN;do
                cp -a /sbin/$i $MOUNTROOT/sbin/
                for j in `ldd /sbin/$i`;do
			[ -f $j ] && echo $j >> /tmp/sbin.tmp
                done
        done
	sort -ru /tmp/sbin.tmp > /root/sbin.txt

        for i in `cat /root/sbin.txt`;do
		DIR=$(dirname $i)
		cp -a $i $MOUNTROOT/$i
		[ -L $i ] && (cp -a $DIR/`ls -al $i | awk -F'->' '{print $2}'|sed -r 's: ::g'` $MOUNTROOT/$DIR)
        done
}

usr_bincp(){
        rm -rf /tmp/usr_bin.tmp
        for i in $USR_BIN $PUPPET_USR_BIN;do
                cp -a /usr/bin/$i $MOUNTROOT/usr/bin
                for j in `ldd /usr/bin/$i`;do
			[ -f $j ] && echo $j >> /tmp/usr_bin.tmp
                done
        done
	sort -ru /tmp/usr_bin.tmp > /root/usr_bin.txt

        for i in `cat /root/usr_bin.txt`;do
		DIR=$(dirname $i)
		cp -a $i $MOUNTROOT/$i
		[ -L $i ] && (cp -a $DIR/`ls -al $i | awk -F'->' '{print $2}'|sed -r 's: ::g'` $MOUNTROOT/$DIR)
        done
}

usr_sbincp(){
        rm -rf /tmp/usr_sbin.tmp
        for i in $USR_SBIN $PUPPET_USR_SBIN;do
                cp -a /usr/sbin/$i $MOUNTROOT/usr/sbin/
                for j in `ldd /usr/sbin/$i`;do
			[ -f $j ] && echo $j >> /tmp/usr_sbin.tmp
                done
        done
        sort -ru /tmp/usr_sbin.tmp > /root/usr_sbin.txt

        for i in `cat /root/usr_bin.txt`;do
		DIR=$(dirname $i)
		cp -a $i $MOUNTROOT/$i
		[ -L $i ] && (cp -a $DIR/`ls -al $i | awk -F'->' '{print $2}'|sed -r 's: ::g'` $MOUNTROOT/$DIR)
        done
}

bincp
sbincp
usr_bincp
usr_sbincp
rm -rf /tmp/*.tmp
rm -rf /root/*bin.txt

#cp -a /root/make_devices $MOUNTROOT/dev
#cd $MOUNTROOT/dev
#./make_devices
 
cp -a /etc/cron.d /etc/*-release /etc/udev /etc/dbus-* /etc/ethers /etc/bashrc /etc/fstab /etc/group /etc/host* /etc/init* /etc/iproute2 /etc/ld.so.c* /etc/localtime /etc/login.defs /etc/modprobe.d/ /etc/nsswitch.conf /etc/ntp* /etc/pam.d/ /etc/passwd /etc/profile* /etc/protocols /etc/rc* /etc/resolv.conf /etc/secur* /etc/services /etc/shadow /etc/shells /etc/ssh/ /etc/sudoers /etc/sysconfig/ /etc/sysctl.* /etc/terminfo/ /etc/rsyslog* /etc/selinux $MOUNTROOT/etc

rm -rf $MOUNTROOT/etc/ld.so.cache
rm -rf $MOUNTROOT/etc/ld.so.conf.d/*
rm -rf $MOUNTROOT/etc/cron.d/*
rm -rf $MOUNTROOT/etc/rsyslog.d/*
rm -rf $MOUNTROOT/etc/selinux/targeted/*
rm -rf $MOUNTROOT/etc/rc.d/init.d/*openstack*
rm -rf $MOUNTROOT/etc/rc.d/rc{2,4,5}.d/*
rm -rf $MOUNTROOT/etc/rc{2,4,5}.d/*
rm -rf $MOUNTROOT/etc/rc{1,3,6}.d/*openstack*
rm -rf $MOUNTROOT/etc/rc{1,3,6}.d/K*
rm -rf $MOUNTROOT/etc/profile.d/*.csh

sed -r -i -e '/export LC_ALL/d' -e '/export PS1=/d' -e '/cp=/d' -e '/ls=/d' $MOUNTROOT/etc/profile
echo 'export LC_ALL=C' >> $MOUNTROOT/etc/profile
echo 'export PS1="[\u@\h \W]\\$ "' >> $MOUNTROOT/etc/profile
echo -e "alias cp=\"cp -a\"\nalias ls=\"ls --color\"\nalias grep=\"grep --color\"\n\n" >> $MOUNTROOT/etc/profile
> $MOUNTROOT/etc/sysconfig/i18n
echo -e "/lib\n/lib64\n/usr/lib\n/usr/lib64\n/usr/local/lib\n/usr/local/lib64" > $MOUNTROOT/etc/ld.so.conf.d/system.conf
echo -e "# detect own machine network card and load it." >> $MOUNTROOT/etc/rc.sysinit
echo -e "modprobe e1000\nmodprobe e1000e\nmodprobe mpt2sas" >> $MOUNTROOT/etc/rc.sysinit
echo -e "ldconfig\nsleep 1\n[ -x /usr/bin/set_network.sh ] && sh /usr/bin/set_network.sh" >> $MOUNTROOT/etc/rc.sysinit

for i in $SERVICES;do
	mv $MOUNTROOT/etc/rc3.d/*$i* $MOUNTROOT/tmp
done

rm -rf $MOUNTROOT/etc/rc3.d/*
mv $MOUNTROOT/tmp/* $MOUNTROOT/etc/rc3.d/

cp -a /boot/grub $MOUNTROOT/boot/
cp -a /boot/*-$KERNEL_VER* $MOUNTROOT/boot/
cp -a /lib/modules/$KERNEL_VER $MOUNTROOT/lib/modules/
sed -r -i "/root=/s:(.*) root=.* (e.*):\1 root=LABEL=$LABEL \2:g" $MOUNTROOT/boot/grub/grub.conf
sed -r -i "/default/s:.*:default=0:g" $MOUNTROOT/boot/grub/grub.conf
sed -r -i "/hiddenmenu/d" $MOUNTROOT/boot/grub/grub.conf
grep -i "title.*$KERNEL_VER*" $MOUNTROOT/boot/grub/grub.conf -A3 > /tmp/.xxx
sed -r -i "/kernel \/vmlinuz/s:\/vmlinuz:\/boot\/vmlinuz:g" /tmp/.xxx
sed -r -i "/initrd \/initramfs/s:\/initramfs:\/boot\/initramfs:g" /tmp/.xxx
sed -r -i '/title/,/initrd/d' $MOUNTROOT/boot/grub/grub.conf
cat /tmp/.xxx >> $MOUNTROOT/boot/grub/grub.conf;rm -rf /tmp/.xxx

sed -r -i "/\/ /s:.*(\/.*):LABEL=$LABEL\t\t\1:g" $MOUNTROOT/etc/fstab
sed -r -i "/swap/s:.*(swap.*swap):LABEL=$LABEL_SWAP\t\t\1:g" $MOUNTROOT/etc/fstab
sed -r -i "/UUID/d" $MOUNTROOT/etc/fstab
sed -r -i "/swift/d" $MOUNTROOT/etc/fstab
sed -r -i '/.*local.*/!d' $MOUNTROOT/etc/hosts

cp -a /lib64/libwrap.so* /lib64/libfreebl3.so /lib64/libdb-* /lib64/libnss_files* /lib64/libnss_dns* /lib64/libnss_compat* /lib64/libexpat* /lib64/xtables* /lib64/security /lib64/rsyslog $MOUNTROOT/lib64/
cp -a /usr/lib64/libdbus-glib-* /usr/lib64/cracklib_dict.* /usr/lib64/libcrack.so.* /usr/lib64/libsasl2.so.* /usr/lib64/libdb-*.so /usr/lib64/libpcap.so.* $MOUNTROOT/usr/lib64/
cp -a /usr/libexec/openssh $MOUNTROOT/usr/libexec/
cp -a /usr/share/file $MOUNTROOT/usr/share/
cp -a /usr/share/misc/magic* $MOUNTROOT/usr/share/misc/
cp -a /usr/share/cracklib $MOUNTROOT/usr/share/
cp -a /usr/share/zoneinfo/Asia $MOUNTROOT/usr/share/zoneinfo/
cp -a /lib/terminfo $MOUNTROOT/lib
cp -a /usr/share/terminfo/{p,r,s,x} $MOUNTROOT/lib/terminfo

# copy puppet needed file and library
if [ $PUPPET_TOOL = 1 ];then
	cp -a /etc/puppet $MOUNTROOT/etc
	cp -a /usr/lib/ruby $MOUNTROOT/usr/lib/
	cp -a /usr/lib64/ruby $MOUNTROOT/usr/lib64/
	cp -a /var/lib/puppet $MOUNTROOT/var/lib/
fi
