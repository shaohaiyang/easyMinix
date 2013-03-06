#!/bin/sh
MOUNTROOT="/root/mini_os"
KERNEL_VER="3.8.2.stack"
SERVICES="crond network local sshd rsyslog"
[ -z $KERNEL_VER ] && KERNEL_VER=$(uname -r)

NET_DRIVER=$(dmesg|awk '{IGNORECASE=1}/eth.* link up/{print $1}')
BIN="awk sh cat chown date dmesg find env egrep gawk hostname ln mkdir mknod mktemp netstat pwd stty touch uname basename chgrp cp df false grep ipcalc login mount ping rm sleep sync true usleep bash chmod cut echo fgrep gzip kill ls mv ps sed sort tar umount vi dd traceroute plymouth dbus-cleanup-sockets dbus-daemon dbus-monitor dbus-send dbus-uuidgen"
SBIN="arp agetty halt ifup udevd udevadm pidof runlevel arping hdparm init initctl ldconfig shutdown tune2fs consoletype fdisk hwclock mingetty swapoff telinit dhclient fsck fsck.ext4 ifconfig ip mke2fs poweroff plymouthd swapon dhclient-script ifdown iptables iptables-multi mkfs.ext3 mkfs.ext4 reboot sysctl killall5 mkswap route rsyslogd tc insmod lsmod modprobe start_udev fstab-decode MAKEDEV"
USR_BIN="bzip2 du vim file groups ldd passwd ssh tty w whereis clear less ssh-add wc expr free id logger scp ssh-keygen screen uptime wget which dirname tput xargs top tr md5sum head tail"
USR_SBIN="adduser lsof crond ntpdate sshd useradd ntpdate ntpd tcpdump hald"

rm -rf $MOUNTROOT
mkdir $MOUNTROOT
cd $MOUNTROOT
mkdir -p bin boot dev etc sys lib/modules lib64/{modules,security,tls} home mnt proc root sbin tmp usr/{bin,sbin,lib64,libexec,local,share} var/{empty,lock,run,spool,lib,www,log}
mkdir -p usr/share/locale var/empty/sshd var/lock/subsys var/spool/cron var/lib/dhcp usr/local/{etc,bin,sbin,lib64,include,libexec,share,var,src}
mkdir -p usr/lib64/perl5/CORE var/run/netreport var/{run,lib}/dbus

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
        for i in $USR_BIN;do
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
        for i in $USR_SBIN;do
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
rm -rf /root/*.txt

#cp -a /root/make_devices $MOUNTROOT/dev
#cd $MOUNTROOT/dev
#./make_devices
 
cp -a /etc/cron.d /etc/*-release /etc/udev /etc/dbus-* /etc/ethers /etc/bashrc /etc/fstab /etc/group /etc/host* /etc/init* /etc/issue /etc/iproute2 /etc/ld.so.c* /etc/localtime /etc/login.defs /etc/modprobe.d/ /etc/pam.d/ /etc/passwd /etc/profile* /etc/protocols /etc/rc* /etc/resolv.conf /etc/secur* /etc/services /etc/shadow /etc/shells /etc/ssh/ /etc/sudoers /etc/sysconfig/ /etc/sysctl.* /etc/terminfo/ /etc/rsyslog* /etc/selinux $MOUNTROOT/etc

rm -rf $MOUNTROOT/etc/ld.so.cache
rm -rf $MOUNTROOT/etc/ld.so.conf.d/*
rm -rf $MOUNTROOT/etc/cron.d/*
rm -rf $MOUNTROOT/etc/rsyslog.d/*
rm -rf $MOUNTROOT/etc/selinux/targeted/*
rm -rf $MOUNTROOT/etc/rc.d/rc{2,4,5}.d 
rm -rf $MOUNTROOT/etc/rc{2,4,5}.d
rm -rf $MOUNTROOT/etc/rc{0,1,3,6}.d/K*
rm -rf $MOUNTROOT/etc/rc{0,1,3,6}.d/*openstack*
rm -rf $MOUNTROOT/etc/profile.d/*.csh
sed -r -i '/export LC_ALL/d' $MOUNTROOT/etc/profile
sed -r -i '/export PS1=/d' $MOUNTROOT/etc/profile
echo 'export LC_ALL=C' >> $MOUNTROOT/etc/profile
echo 'export PS1="[\u@\h \W]\\$ "' >> $MOUNTROOT/etc/profile
echo '' > /etc/sysconfig/i18n
echo -e "/lib\n/lib64\n/usr/lib\n/usr/lib64\n/usr/local/lib\n/usr/local/lib64" > $MOUNTROOT/etc/ld.so.conf.d/system.conf
echo -e "\n# detect own machine network card and load it.\nmodprobe $NET_DRIVER" >> $MOUNTROOT/etc/rc.sysinit

for i in $SERVICES;do
	mv $MOUNTROOT/etc/rc3.d/*$i* $MOUNTROOT/tmp
done

rm -rf $MOUNTROOT/etc/rc3.d/*
mv $MOUNTROOT/tmp/* $MOUNTROOT/etc/rc3.d/

cp -a /lib64/libwrap.so* /lib64/libdb-* /lib64/libnss_files* /lib64/libnss_dns* /lib64/libnss_compat* /lib64/libexpat* /lib64/xtables /lib64/security /lib64/rsyslog $MOUNTROOT/lib64/
cp -a /usr/lib64/libdbus-glib-* /usr/lib64/cracklib_dict.* /usr/lib64/libcrack.so.* /usr/lib64/libsasl2.so.* /usr/lib64/libdb-*.so $MOUNTROOT/usr/lib64/

cp -a /usr/libexec/openssh $MOUNTROOT/usr/libexec/
cp -a /lib/terminfo $MOUNTROOT/lib
cp -a /usr/share/terminfo/x $MOUNTROOT/lib/terminfo
cp -a /usr/share/file $MOUNTROOT/usr/share/
cp -a /boot/grub $MOUNTROOT/boot/
cp -a /boot/*-$KERNEL_VER* $MOUNTROOT/boot/
cp -a /lib/modules/$KERNEL_VER $MOUNTROOT/lib/modules/

