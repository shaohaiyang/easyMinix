#!/bin/sh
export LC_ALL=en_US.utf8
KERNEL=
ZONE="Asia/Shanghai"
SSHPORT="22"

setenforce 0
if [ -z $1 ];then
        read -t30 -p "Please input HostName(eg. $HOSTNAME): " HOST
else
        HOST=$1
fi
[ -z $HOST ] && HOST=$HOSTNAME
hostnamectl --static set-hostname $HOST
hostnamectl --pretty set-hostname $HOST
hostnamectl --transient set-hostname $HOST
echo "$HOST" > /proc/sys/kernel/hostname

timedatectl set-timezone $ZONE
timedatectl set-ntp 1
timedatectl set-local-rtc 0

echo root.com | passwd root --stdin
ssh-keygen -t rsa -b 4096 -P "" -f ~/.ssh/id_rsa
curl -X GET -o ~/.ssh/authorized_keys http://xxxxxxxxx/authorized_keys
chmod 0400 ~/.ssh/*

grep -iq shaohy /root/.ssh/authorized_keys
[ $? = 0 ] && sed -r -i "/#Port 22/s^.*^Port $SSHPORT^g;/^PasswordAuthentication/s^yes^no^g" /etc/ssh/sshd_config
sed -r -i  '/^SELINUX=/s^=.*^=disabled^g' /etc/selinux/config
sed -r -i '/^[^root]/s:/bin/bash:/sbin/nologin:g' /etc/passwd
sed -r -i -e '/DefaultLimitCORE/s^.*^DefaultLimitCORE=infinity^g' -e '/DefaultLimitNOFILE/s^.*^DefaultLimitNOFILE=100000^g' -e '/DefaultLimitNPROC/s^.*^DefaultLimitNPROC=100000^g' /etc/systemd/system.conf 
sed -r -i 's@weekly@daily@g;s@^rotate.*@rotate 7@g;s@^#compress.*@compress@g' /etc/logrotate.conf
sed -r -i -e '/Compress=/s@.*@Compress=yes@g; /SystemMaxUse=/s@.*@SystemMaxUse=4G@g; ' \
	  -e '/SystemMaxFileSize=/s@.*@SystemMaxFileSize=256M@g; /MaxRetentionSec=/s@.*@MaxRetentionSec=2week@g' /etc/systemd/journald.conf

for bad in iptable_nat nf_nat nf_conntrack nf_conntrack_ipv4 nf_defrag_ipv4;do
	sed -r -i "/$bad/d" /etc/modprobe.d/blacklist.conf
	echo "blacklist $bad" >>  /etc/modprobe.d/blacklist.conf
done
echo nf_conntrack > /usr/lib/modules-load.d/net.conf
echo "options nf_conntrack hashsize=262144" > /etc/modprobe.d/nf_conntrack.conf

cat > /etc/resolv.conf <<EOF
options timeout:1 attempts:2 single-request-reopen
nameserver 192.168.21.20
nameserver 192.168.147.20
nameserver 119.29.29.29
nameserver 180.76.76.76
nameserver 114.114.114.114
EOF

localectl set-locale LANG=en_US.UTF8
cat > /etc/locale.conf <<EOF
LANG=en_US.utf8
LC_CTYPE=en_US.utf8
EOF

cat > /etc/security/limits.d/20-nproc.conf  <<EOF
*          soft    nproc    10240
root       soft    nproc    unlimited
EOF

cat > /etc/cron.d/upyun <<EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
CRON_TZ=$ZONE
*/10 * * * * root (/usr/sbin/ntpdate -o3  211.115.194.21 133.100.11.8 142.3.100.15)
EOF
grep MAILTO= /etc/ -r -l | xargs sed -r -i '/MAILTO=/s@=.*@=@'
sed -r -i '/^CRONDARGS=/s@=.*@="-s -m off"@g' /etc/sysconfig/crond

yum install -y lldpd mtr tree ntpdate telnet bc nc net-tools wget lsof \
		rsync nmon bash-completion iptables-services firewalld \
		sysstat htop bind-utils yum-utils smartmontools epel-release \
		supervisor python-setuptools python-pip pkgconfig

sed -r -i '$a /usr/sbin/ntpdate -u -o3  ntp.aliyun.com 211.115.194.21' /etc/rc.d/rc.local
for file in set_irq.sh set_net_smp_affinity.sh set_rps.sh;do
	curl -X GET -u shaohy:Geminis987 -o /usr/local/sbin/$file http://devops.upyun.com:88/$file
        chmod +x /usr/local/sbin/$file
        sed -r -i "/$file/d" /etc/rc.d/rc.local
        echo "/usr/local/sbin/$file" >> /etc/rc.d/rc.local
done    
sed -r -i "/-j NOTRACK/d" /etc/rc.d/rc.local
sed -r -i "/nameserver/d" /etc/rc.d/rc.local
echo -en "iptables -t raw -A PREROUTING -p ALL -j NOTRACK\niptables -t raw -A OUTPUT -p ALL -j NOTRACK\n" >> /etc/rc.d/rc.local
cat >>  /etc/rc.d/rc.local <<EOF
#echo -en "nameserver 119.29.29.29\nnameserver 180.76.76.76\nnameserver 114.114.114.114" > /etc/resolv.conf
EOF

chmod +x /etc/rc.d/rc.local

if [ ! -z $KERNEL ];then
    wget -c http://devops.upyun.com/kernel-el7/$KERNEL
    if [ -s $KERNEL ];then
        yum -y install $KERNEL
    else
        yum --enablerepo=elrepo-kernel -y install kernel-lt
    fi
    Version=`yum info kernel-lt|awk -F: '/Version/{print $2}'`
    Menu=`sed -r -n "s/^menuentry '(.*)' --class.*/\1/p" /boot/grub2/grub.cfg|grep $Version`
    grub2-set-default "$Menu"
    grub2-mkconfig -o /boot/grub2/grub.cfg
fi

systemctl daemon-reload
systemctl unmask NetworkManager
for svc in network auditd ;do
        systemctl enable $svc
done

for svc in firewalld postfix irqbalance tuned rpcbind.target NetworkManager;do
        systemctl disable $svc
done
