#!/usr/bin/bash
# U盘符很重要，不小心就会覆写系统盘
DEV="/dev/sda"
LABEL="/Amy"
UPYUN_DIR="/root/upos-centos8.tgz"
MOUNT="/mnt"
readonly PARTION=msdos

read -p "You must supply a network configration. (`pwd`/network.info)" NETWORK_CONF
[ -z $NETWORK_CONF ] && NETWORK_CONF="`pwd`/network.info"

# make a whole partition for all sata drivers.
for part in $(parted -s $DEV print|awk '/^ /{print $1}');do
        parted -s $DEV rm $part
done

if [ ${PARTION,,} = "gpt" ];then
	# 这个gpt是是EFI文件系统，要用efi引导启动
	parted -s $DEV mklabel gpt mkpart primary ext4 8192s 2G
	# 设置启动标识位
	parted -s $DEV set 1 bios_grub on
else
	# mklabel msdos是传统的 grub引导
	parted -s $DEV mklabel msdos mkpart primary ext4 1M 2G
	# 设置启动标识位
	parted -s $DEV set 1 boot on
fi

# 新分区生效
partprobe $DEV
partx -a $DEV

# 去除一些不必要的菜单
ln -snf /etc/default/grub /etc/sysconfig/grub 

chmod -x /etc/grub.d/[2-4]*
sed -r -i '/menuentry /,$d' /etc/grub.d/40_custom

# 显式输出菜单参数
sed -r -i '/GRUB_ENABLE_BLSCFG=/s@=.*@=false@g' /etc/default/grub

# 调整内核引导参数并更新
sed -r -i '/GRUB_CMDLINE_LINUX=/s@=.*@="net.ifnames=0 biosdevname=0 selinux=0"@g' /etc/default/grub
grubby --update-kernel ALL --args="net.ifnames=0 biosdevname=0 selinux=0" --remove-args="resume"

# 重新导出配置
grub2-mkconfig | sed -r -n '/^menuentry /, /}/p' > .grub.tmp 

sed -r -i -e '/if /,/fi$/d' -e 's@CentOS@MINIOS@g' -e "s@set root=.*@set root=\'hd0,${PARTION,,}1\'@g" \
        -e 's@vmlinuz@boot/vmlinuz@g' -e 's@initramfs@boot/initramfs@g' \
        -e 's@root=UUID=.* (ro.*)@root=LABEL=/Amy \1@g' .grub.tmp

if [ ${PARTION,,} = "msdos" ];then
	sed -r -i -e '/part_gpt/a insmod part_msdos' .grub.tmp
fi

# 重新导入新的grub menuentry
chmod -x /etc/grub.d/1*
grub2-mkconfig -o .grub.old
chmod +x /etc/grub.d/[1-4]*

# 格式化分区
mkfs.ext4 -F -L $LABEL ${DEV}1

# 挂载分区并解压文件
mount ${DEV}1 $MOUNT
tar zxvf $UPYUN_DIR -C $MOUNT

# 补充系统保存动态信息的必要目录
mkdir -p   $MOUNT/{dev,run,mnt,proc,sys,tmp}
chmod 1777 $MOUNT/tmp

# 修改 fstab文件，挂载正确的分区目标
cat > $MOUNT/etc/fstab <<EOF 
LABEL=/Amy        /        ext4     defaults  0 0
EOF

# 生成自定义菜单
cat .grub.old .grub.tmp > $MOUNT/boot/grub2/grub.cfg 
cp -a $MOUNT/boot/grub2/grub.cfg $MOUNT/boot/efi/EFI/centos/grub.cfg
chmod -x $MOUNT/etc/grub.d/[1-4]*
rm -rf $MOUNT/boot/grub2/grubenv
rm -rf $MOUNT/boot/efi/EFI/centos/grubenv
rm -rf $MOUNT/boot/loader/entries/*

# 拷贝原系统的登录公钥
rm -rf $MOUNT/root/* $MOUNT/root/.ssh/*
mkdir -m 600 -p $MOUNT/root/.ssh
cp -a /root/.ssh/authorized_keys $MOUNT/root/.ssh/

# 拷贝网络配置文件
cp -a $NETWORK_CONF $MOUNT/

# 安装grub引导
grub2-install --target=i386-pc --root-directory=$MOUNT --no-floppy --recheck $DEV
umount $MOUNT

