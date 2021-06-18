#!/bin/bash
if [ -s /network.info ];then
         . /network.info
else
        echo "You should be supply right network config." ; exit 0
fi

nmcli -v|grep -iq version >/dev/null 2>&1
if [ $? = 0 ];then
        IS_NetworkManager="yes"
	sed -r -i '/managed/s@=.*@=true@g' /etc/NetworkManager/NetworkManager.conf
	if [ -x /usr/sbin/netplan ] ;then
cat >  /etc/netplan/00-installer-config.yaml <<EOF
network:
  renderer: NetworkManager
EOF
	fi
fi

if [ ! -z $HOSTNAME ];then
	hostnamectl set-hostname --static $HOSTNAME
	hostnamectl set-hostname --pretty $HOSTNAME
fi

if [ -z $IS_NetworkManager ];then
        rm -rf /etc/sysconfig/network-scripts/ifcfg-eth*
        rm -rf /etc/sysconfig/network-scripts/ifcfg-bond*
else
        rm -rf /etc/sysconfig/network-scripts/ifcfg-bond*
        systemctl stop network && systemctl disable network
	[ -x /usr/sbin/netplan ] && netplan apply
        nmcli -t -f UUID con show| xargs nmcli connection down
        nmcli -t -f UUID con show| xargs nmcli connection del 
fi

> /etc/resolv.conf

if [ -z "$BONDING" ];then
for device in $NET_IF;do
        echo "$device"|grep -q "^#"
        [ $? = 0 ] && continue
    
        STRING=""
        xx=$IFS;IFS="|";read -r dev nick state ip mask gw mtu <<<"$device";IFS=$xx
        [ -z $mtu ] && mtu="1500"
        echo $dev $nick $state $ip $mask $gw $mtu
        echo $dev|grep -q "^*"
        if [ $? = 0 ];then
                dev=${dev#\*}
                dev=`echo $dev|awk -F: '{print $1}'`
                STRING2="ip ro re default via $gw dev $dev;ip ro fl ca"
        fi  
        STRING+="DEVICE=\"$dev\"\nONBOOT=yes\nBOOTPROTO=static\nIPADDR=$ip\nNETMASK=$mask\nGATEWAY=$gw\nMTU=$mtu\n"
    
        if [ -z $IS_NetworkManager ];then
                echo -en $STRING > /etc/sysconfig/network-scripts/ifcfg-$dev
        else
                nmcli connection add type ethernet ifname $dev con-name "$dev" ip4 "$ip/$mask" gw4 $gw mtu $mtu 
                nmcli con up $dev
        fi  
done
else
for device in $BONDING;do
        STRING=""
        xx=$IFS;IFS="|";read -r nick devs mode ip mask gw mtu <<<"$device";IFS=$xx
        [ -z $mtu ] && mtu="1500"
        echo $nick $devs $mode $ip $mask $gw $mtu
        echo $nick|grep -q "^*"
        if [ $? = 0 ];then
                nick=${nick#\*}
                nick=`echo $nick|awk -F: '{print $1}'`
                STRING3="ip ro re default via $gw dev $nick;ip ro fl ca"
        fi  

        if [ -z $IS_NetworkManager ];then
                if [ "O${mode}O" = "O2O" ];then
                        STRING+="DEVICE=\"$nick\"\nONBOOT=yes\nBOOTPROTO=static\nBONDING_OPTS=\"miimon=100 mode=2 xmit_hash_policy=1\"\nIPADDR=$ip\nNETMASK=$mask\nGATEWAY=$gw\nMTU=$mtu\n"
                else
                        STRING+="DEVICE=\"$nick\"\nONBOOT=yes\nBOOTPROTO=static\nBONDING_OPTS=\"miimon=100 mode=$mode\"\nIPADDR=$ip\nNETMASK=$mask\nGATEWAY=$gw\nMTU=$mtu\n"
                fi  
                echo -en $STRING > /etc/sysconfig/network-scripts/ifcfg-$nick
                DEVS=`echo $devs|sed -r 's:@: :g'`
                for ii in $DEVS;do
                        echo -en "DEVICE=$ii\nONBOOT=yes\n" > /etc/sysconfig/network-scripts/ifcfg-$ii
                done
                echo "alias $nick bonding" > /etc/modprobe.d/$nick.conf
                STRING2+="ifenslave $nick $DEVS\n"
        else
                if [ $mode = 2 ];then
                        nmcli con add type bond ifname $nick con-name $nick bond.options "mode=$mode,miimon=100,xmit_hash_policy=1" 
        else
                        nmcli con add type bond ifname $nick con-name $nick bond.options "mode=$mode,miimon=100"
                fi          
                nmcli con modify  $nick ipv4.address $ip/$mask ipv4.gateway $gw mtu $mtu ipv4.method manual connection.autoconnect-slaves 1            
                DEVS=`echo $devs|sed -r 's:@: :g'`
                for ii in $DEVS;do
                        nmcli c add type ethernet slave-type bond con-name $ii ifname $ii master $nick
                done        
                nmcli c up $nick
                echo "alias $nick bonding" > /etc/modprobe.d/$nick.conf
        fi          
done        
fi

if [ -z $IS_NetworkManager ];then
        sed -r -i -e "/ip ro re default/d" -e "/ifenslave/d" /etc/rc.d/rc.local
        sed -r -i "/#\!\/bin\/sh/a\\$STRING2$STRING3" /etc/rc.d/rc.local
else                                                                                                                               
        systemctl unmask NetworkManager
        systemctl enable NetworkManager
        systemctl restart NetworkManager
fi
ln -snf /etc/rc.d/rc.local /etc/rc.local

for dns in $DNS;do
        echo "nameserver $dns" >> /etc/resolv.conf
done       
