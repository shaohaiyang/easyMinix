#!/bin/bash
export LC_ALL=en_US.utf8
KERNEL="kernel-lt-5.4.94-1.el7.elrepo.x86_64.rpm"
ZONE="Asia/Shanghai"
SSHPORT="22"

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
timedatectl set-ntp 0
timedatectl set-local-rtc 0

setenforce 0
#echo root.com | passwd root --stdin

grep -iq shaohy /root/.ssh/authorized_keys
if [ $? = 0 ] ;then
	sed -r -i "/#Port 22/s^.*^Port $SSHPORT^g;/^PasswordAuthentication/s^yes^no^g" /etc/ssh/sshd_config
else
        ssh-keygen -t rsa -b 4096 -P "" -f ~/.ssh/id_rsa
        rm -rf ~/.ssh/id_rsa*
	curl -X GET -o ~/.ssh/authorized_keys http://xxxxxxxxx/authorized_keys
fi
chmod 0400 ~/.ssh/*

sed -r -i  '/^SELINUX=/s^=.*^=disabled^g' /etc/selinux/config
sed -r -i '/^[^root]/s:/bin/bash:/sbin/nologin:g' /etc/passwd
sed -r -i -e '/DefaultLimitCORE/s^.*^DefaultLimitCORE=infinity^g' -e '/DefaultLimitNOFILE/s^.*^DefaultLimitNOFILE=100000^g' -e '/DefaultLimitNPROC/s^.*^Defau
ltLimitNPROC=100000^g' /etc/systemd/system.conf
sed -r -i 's@weekly@daily@g;s@^rotate.*@rotate 7@g;s@^#compress.*@compress@g' /etc/logrotate.conf
sed -r -i -e '/Compress=/s@.*@Compress=yes@g; /SystemMaxUse=/s@.*@SystemMaxUse=4G@g; ' \
          -e '/SystemMaxFileSize=/s@.*@SystemMaxFileSize=256M@g; /MaxRetentionSec=/s@.*@MaxRetentionSec=2week@g' /etc/systemd/journald.conf

for bad in iptable_nat nf_nat nf_conntrack nf_conntrack_ipv4 nf_defrag_ipv4;do
        sed -r -i "/$bad/d" /etc/modprobe.d/blacklist.conf
        #echo "blacklist $bad" >>  /etc/modprobe.d/blacklist.conf
done
echo nf_conntrack > /usr/lib/modules-load.d/net.conf
echo "options nf_conntrack hashsize=262144" > /etc/modprobe.d/nf_conntrack.conf

cat > /etc/resolv.conf <<EOF
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
root       soft    proc     unlimited
EOF

cat > /etc/cron.d/xxxxxxx <<EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
CRON_TZ=$ZONE
*/10 * * * * root (/usr/sbin/ntpdate pool.ntp.org)
EOF

yum install -y tree ntpdate telnet bc nc net-tools wget lsof rsync nmon bash-completion \
               iptables-services firewalld sysstat mtr htop bind-utils yum-utils epel-release \
               smartmontools supervisor python-setuptools python-pip pkgconfig
cat > /etc/yum.repos.d/docker.repo<<EOF
[docker]
name=docker
baseurl=https://mirrors.cloud.tencent.com/docker-ce/linux/centos/7/x86_64/stable/
enabled=1
gpgcheck=0
EOF
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
rpm -Uvh http://download-ib01.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum makecache fast
yum -y install docker-ce

sed -r -i 's/biosdevname=0//g;s/net.ifnames=0//g' /etc/sysconfig/grub
sed -r -i 's/biosdevname=0//g;s/net.ifnames=0//g' /etc/default/grub
$(ip link|grep -iq "eth[0-9]\{1,3\}:.*up") && sed -r -i '/GRUB_CMDLINE_LINUX/s^(.*)="(.*)"$^\1="\2 biosdevname=0 net.ifnames=0"^g' /etc/sysconfig/grub
$(ip link|grep -iq "eth[0-9]\{1,3\}:.*up") && sed -r -i '/GRUB_CMDLINE_LINUX/s^(.*)="(.*)"$^\1="\2 biosdevname=0 net.ifnames=0"^g' /etc/default/grub
ntpdate pool.ntp.org

sed -r -i '$a /usr/sbin/ntpdate pool.ntp.org ntp.aliyun.com ' /etc/rc.d/rc.local

for file in set_irq.sh set_net_smp_affinity.sh set_rps.sh;do
        chmod +x /usr/local/sbin/$file
        sed -r -i "/$file/d" /etc/rc.d/rc.local
        echo "/usr/local/sbin/$file" >> /etc/rc.d/rc.local
done
sed -r -i "/-j NOTRACK/d" /etc/rc.d/rc.local
sed -r -i "/nameserver/d" /etc/rc.d/rc.local
#echo -en "iptables -t raw -A PREROUTING -p ALL -j NOTRACK\niptables -t raw -A OUTPUT -p ALL -j NOTRACK\n" >> /etc/rc.d/rc.local
cat >>  /etc/rc.d/rc.local <<EOF
echo -en "nameserver 119.29.29.29\nnameserver 180.76.76.76\nnameserver 114.114.114.114" > /etc/resolv.conf
EOF

chmod +x /etc/rc.d/rc.local

if [ ! -z $KERNEL ];then
    if [ -s $KERNEL ];then
        rpm -ivh $KERNEL
    else
        yum --enablerepo=elrepo-kernel -y install kernel-lt
    fi
    Version=`yum info kernel-lt|awk -F: '/Version/{print $2}'`
    Menu=`sed -r -n "s/^menuentry '(.*)' --class.*/\1/p" /boot/grub2/grub.cfg|grep $Version`
    grub2-set-default "$Menu"
    grub2-mkconfig -o /boot/grub2/grub.cfg
fi

systemctl unmask NetworkManager
systemctl enable NetworkManager
systemctl daemon-reload
systemctl disable network firewalld postfix irqbalance tuned rpcbind.target
systemctl enable auditd
