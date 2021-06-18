#!/bin/bash
export LC_ALL=C.UTF-8
#echo 'root:upyun.com123' | sudo chpasswd

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
	
ZONE='Asia/Shanghai'
SSHPORT='22'

timedatectl set-timezone $ZONE
timedatectl set-ntp 1
timedatectl set-local-rtc 0

ntpdate pool.ntp.org
cat > /etc/cron.d/upyun <<EOF
SHELL=/bin/bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin
CRON_TZ=$ZONE
0 * * * * root (ntpdate pool.ntp.org)
EOF

#sshd config
grep -iq shaohy /root/.ssh/authorized_keys
if [ $? = 0 ];then
	sed -r -i "/#Port 22/s^.*^Port $SSHPORT^g;s/^PermitRootLogin.*/PermitRootLogin yes/g;/^PasswordAuthentication/s^.*^PasswordAuthentication no^g" /etc/ssh/sshd_config
else
	ssh-keygen -t rsa -b 4096 -P "" -f ~/.ssh/id_rsa
	rm -rf ~/.ssh/id_rsa*
	curl -X GET -o ~/.ssh/authorized_keys http://115.231.100.110/resource/authorized_keys
fi
chmod 0400 ~/.ssh/*

sed -r -i 's@weekly@daily@g;s@^rotate.*@rotate 7@g;s@^#compress.*@compress@g' /etc/logrotate.conf
sed -r -i -e '/Compress=/s@.*@Compress=yes@g; /SystemMaxUse=/s@.*@SystemMaxUse=4G@g; ' \
	-e '/SystemMaxFileSize=/s@.*@SystemMaxFileSize=256M@g; /MaxRetentionSec=/s@.*@MaxRetentionSec=2week@g' /etc/systemd/journald.conf

cat >/etc/apt/sources.list <<EOF
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF

ln -fs /lib/systemd/system/rc-local.service /etc/systemd/system/rc-local.service
sed -r -i '/Install/d;/WantedBy=/d;/Alias=/d;' /lib/systemd/system/rc-local.service
cat >> /lib/systemd/system/rc-local.service <<EOF
[Install]
WantedBy=multi-user.target
Alias=rc-local.service
EOF

sed -r -i '/\/bin\/sh/d; /\/bin\/bash/d;' /etc/rc.d/rc.local
sed -r -i '1i #!/bin/bash' /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
ln -snf /etc/rc.d/rc.local /etc/rc.local

#apt install -y systemd logrotate ncat lldpd curl ethtool lsscsi ntpdate smartmontools network-manager vim openssh-server ifupdown net-tools netplan.io sysstat python3-pip jq netcat xfsprogs bind9-dnsutils iproute2 tcpdump iputils-*
apt update -y

systemctl start lldpd && systemctl enable lldpd
systemctl start rc-local && systemctl enable rc-local
