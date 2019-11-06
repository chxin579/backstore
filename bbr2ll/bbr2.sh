#!/bin/bash
clear
echo
echo "#################################################################"
echo "# Google BBRv2 x86_64 Install"
echo "# System Required: CentOS 7 or Debian 8/9 or Ubuntu 19.04 x86_64"
echo "#################################################################"
echo

system_check(){
	if [ -f /usr/bin/yum ]; then
		centos_install
	elif [ -f /usr/bin/apt ]; then
		debian_install
	else
		echo -e "你的系统不支持"
	fi
}

centos_install(){
	[ ! -f "kernel-5.2.0_rc3+-1.x86_64.rpm" ] && wget --no-check-certificate -O kernel-5.2.0_rc3+-1.x86_64.rpm "https://backstore.netlify.com/bbr2ll/centos/kernel-5.2.0_rc3%2B-1.x86_64.rpm"
	[ ! -f "kernel-5.2.0_rc3+-1.x86_64.rpm" ] && echo "Error! Download file failed! File \"kernel-5.2.0_rc3+-1.x86_64.rpm\" Not Found!" && echo "错误！下载文件失败！找不到文件 \"kernel-5.2.0_rc3+-1.x86_64.rpm\"" && exit 1
	[ ! -f "kernel-headers-5.2.0_rc3+-1.x86_64.rpm" ] && wget --no-check-certificate -O kernel-5.2.0_rc3+-1.x86_64.rpm "https://backstore.netlify.com/bbr2ll/centos/kernel-headers-5.2.0_rc3%2B-1.x86_64.rpm"
	[ ! -f "kernel-headers-5.2.0_rc3+-1.x86_64.rpm" ] && echo "Error! Download file failed! File \"kernel-headers-5.2.0_rc3+-1.x86_64.rpm\" Not Found!" && echo "错误！下载文件失败！找不到文件 \"kernel-headers-5.2.0_rc3+-1.x86_64.rpm\"" && exit 1
	yum -y localinstall kernel-5.2.0_rc3+-1.x86_64.rpm
	yum -y localinstall kernel-headers-5.2.0_rc3+-1.x86_64.rpm
	rm -f kernel-5.2.0_rc3+-1.x86_64.rpm kernel-headers-5.2.0_rc3+-1.x86_64.rpm
	grub2-set-default 0
	echo "tcp_bbr" >> /etc/modules-load.d/tcp_bbr.conf
	echo "tcp_bbr2" >> /etc/modules-load.d/tcp_bbr2.conf
	echo "tcp_dctcp" >> /etc/modules-load.d/tcp_dctcp.conf
	sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control = bbr2" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.conf
	sysctl -p
	rm -rf ~/bbr2
	read -p "内核安装完成，重启生效，是否现在重启？[Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "正在重启"
		reboot
	fi
}

debian_install(){
	apt -y update
	[ ! -f "linux-image-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb" ] && wget --no-check-certificate -O linux-image-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb "https://backstore.netlify.com/bbr2yy/linux-image-5.2.0-rc3%2B_5.2.0-rc3%2B-1_amd64.deb"
	[ ! -f "linux-image-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb" ] && echo "Error! Download file failed! File \"linux-image-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb\" Not Found!" && echo "錯誤！下載文件失敗！找不到文件 \"linux-image-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb\"" && exit 1
	[ ! -f "linux-headers-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb" ] && wget --no-check-certificate -O linux-headers-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb "https://backstore.netlify.com/bbr2yy/linux-headers-5.2.0-rc3%2B_5.2.0-rc3%2B-1_amd64.deb"
	[ ! -f "linux-headers-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb" ] && echo "Error! Download file failed! File \"linux-headers-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb\" Not Found!" && echo "錯誤！下載文件失敗！找不到文件 \"linux-headers-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb\"" && exit 1
	apt -y install linux-headers-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb
	apt -y install linux-image-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb
	rm -f linux-headers-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb linux-image-5.2.0-rc3+_5.2.0-rc3+-1_amd64.deb
	echo "tcp_bbr" >> /etc/modules
	echo "tcp_bbr2" >> /etc/modules
	echo "tcp_dctcp" >> /etc/modules
	sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
	echo "net.ipv4.tcp_congestion_control = bbr2" >> /etc/sysctl.conf
	echo "net.ipv4.tcp_ecn = 1" >> /etc/sysctl.conf
	sysctl -p
	rm -rf ~/bbr2
	read -p "内核安装完成，重启生效，是否现在重启？[Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
		echo -e "正在重启"
		reboot
	fi
}

start_menu(){
	read -p "请输入数字(1/2/3)  1：安装BBRv2  2：开启ECN  3：我是咸鱼我退出:" num
	case "$num" in
		1)
		system_check
		;;
		2)
		echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable
		;;
		3)
		exit 1
		;;
	esac
}

start_menu
