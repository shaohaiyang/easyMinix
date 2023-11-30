#!/bin/bash
export LC_ALL=en_US.utf8
KERNEL=
ZONE="Asia/Shanghai"
SSHPORT="22"

IP=$(ip a| awk -F"/" '/inet 192.168./{split($1,a," ");print a[2]}'|uniq|head -1)
if [ ! -z $IP ];then
        NICK=$(ip a| awk -F"/" '/inet 192.168./{split($1,a," ");split(a[2],b,".");print b[3]"-"b[4]}'|uniq|head -1)
        HOST="UPOS-"$NICK

        hostnamectl --static set-hostname $HOST
        hostnamectl --pretty set-hostname $HOST
        hostnamectl --transient set-hostname $HOST
        echo "$HOST" > /proc/sys/kernel/hostname
        sed -r -i "/$HOST/d" /etc/hosts
        echo -en "$IP\t$HOST\n" >> /etc/hosts
fi

timedatectl set-timezone $ZONE
timedatectl set-ntp 1
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
        chmod 0400 ~/.ssh/*
fi

sed -r -i  '/^SELINUX=/s^=.*^=disabled^g' /etc/selinux/config
sed -r -i '/^[^root]/s:/bin/bash:/sbin/nologin:g' /etc/passwd
sed -r -i -e '/DefaultLimitCORE/s^.*^DefaultLimitCORE=infinity^g' -e '/DefaultLimitNOFILE/s^.*^DefaultLimitNOFILE=100000^g' -e '/DefaultLimitNPROC/s^.*^Defau
ltLimitNPROC=100000^g' /etc/systemd/system.conf
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

for file in set_irq.sh set_net_smp_affinity.sh set_rps.sh;do
        curl -X GET -u shaohy:XXXXXX -o /usr/local/sbin/$file http://xxxxxxxxx:88/$file
        chmod +x /usr/local/sbin/$file
        sed -r -i "/$file/d" /etc/rc.d/rc.local
        echo "/usr/local/sbin/$file" >> /etc/rc.d/rc.local
done
curl -X GET -u shaohy:XXXXXXX -o /etc/sysctl.d/99-sysctl.conf http://xxxxxxxxxx:88/sysctl.conf
chmod +x /etc/rc.d/rc.local

systemctl daemon-reload
for ss in firewalld postfix irqbalance tuned rpcbind.target auditd ;do
        systemctl stop $ss
        systemctl disable $ss
done
