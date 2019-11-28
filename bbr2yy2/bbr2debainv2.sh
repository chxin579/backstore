#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error! You must be root to run this script!"
    echo "错误！你必须要以root身份运行此脚本！"
    exit 1
fi

this_file_path=$(readlink -f $0)
this_file_dir=$(dirname $(readlink -f $0))
red_color="\033[31m"
green_color="\033[32m"
color_end="\033[0m"

cat /etc/issue | grep -q "CentOS"
if [ $? -eq 0 ]; then
    echo "    Oh Nononononono! You are using CentOS?
    Unfortunately, this script only works for Debian."
    echo "    哦不不不不不不！你正在使用CentOS？
    请使用另一个脚本运行！"
    exit 0
fi

install_rc.local() {
    [ -f "/etc/rc.local" ] && echo "Error! /etc/rc.local already exist." && echo "错误！/etc/rc.local已经存在。" && exit 1
    systemctl stop rc-local
    cat > /etc/rc.local << EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

exit 0
EOF
    chmod +x /etc/rc.local
    systemctl start rc-local
}
add_to_rc.local() {
    [ ! -f "/etc/rc.local" ] && install_rc.local
    sed -i "s/will \"exit 0\" on/will \"exit yeying.org\" on/g" /etc/rc.local
    sed -i "/exit 0/d" /etc/rc.local
    sed -i "s/will \"exit yeying.org\" on/will \"exit 0\" on/g" /etc/rc.local
    echo "$1" >> /etc/rc.local
    echo 'exit 0' >> /etc/rc.local
}

check_environment() {
    unset environment_debian
    unset environment_x64
    unset environment_headers
    unset environment_image
    unset environment_kernel
    unset environment_bbr2
    unset environment_ecn
    unset environment_otherkernels
    cat /etc/issue | grep -q "Debian" && [ $? -eq 0 ] && environment_debian="true"
    cat /etc/issue | grep -q "Ubuntu" && [ $? -eq 0 ] && environment_debian="true"
    uname -a | grep -q "x86_64" && [ $? -eq 0 ] && environment_x64="true"
    dpkg -l | grep linux-headers | awk '{print $2}' | grep -q "linux-headers-5.4.0-rc6" && [ $? -eq 0 ] && environment_headers="true"
    dpkg -l | grep linux-image | awk '{print $2}' | grep -q "linux-image-5.4.0-rc6" && [ $? -eq 0 ] && environment_image="true"
    uname -r | grep -q "5.4.0-rc6" && [ $? -eq 0 ] && environment_kernel="true"
    cat /etc/sysctl.conf | grep -q "bbr2" && [ $? -eq 0 ] && lsmod | grep -q "tcp_bbr2" && [ $? -eq 0 ] && environment_bbr2="true"
    cat /etc/sysctl.conf | grep -q "net.ipv4.tcp_ecn" && [ $? -eq 0 ] && [[ "$(cat /sys/module/tcp_bbr2/parameters/ecn_enable)" = "Y" ]] && cat /etc/rc.local | grep -q "echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable" && [ $? -eq 0 ] && environment_ecn="true"
    other_linux_images=$(dpkg -l | grep linux-image | awk '{print $2}') && other_linux_images=${other_linux_images/"linux-image-5.4.0-rc6"/} && [ ! -z "$other_linux_images" ] && environment_otherkernels="true"
    other_linux_headers=$(dpkg -l | grep linux-headers | awk '{print $2}') && other_linux_headers=${other_linux_headers/"linux-headers-5.4.0-rc6"/} && [ ! -z "$other_linux_headers" ] && environment_otherkernels="true"

    [[ "$environment_debian" != "true" ]] && echo "Error! Your OS is not Debian! This script is only suitable for Debian 9/10." && echo "错误！你的系统不是Debian，此脚本只适用于Debian 9/10！" && exitone="true"
    [[ "$environment_x64" != "true" ]] && echo "Error! Your OS is not x86_64! This script is only suitable for x86_64 OS." && echo "错误！你的系统不是64位系统，此脚本只适用于64位系统(x86_64)！" && exitone="true"

    [[ "$exitone" = "true" ]] && exit 1
}

analyze_environment() {
    if [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]]; then
        if [[ "$environment_kernel" = "true" ]]; then
            echo -e "Kernel: ${green_color}Installed${color_end}-${green_color}Using${color_end} | 內核: ${green_color}已安装${color_end}-${green_color}使用中${color_end}"
        else
            echo -e "Kernel: ${green_color}Installed${color_end}-${red_color}Not using${color_end} | 內核: ${green_color}已安装${color_end}-${red_color}未使用${color_end}"
        fi
    else
        echo -e "Kernel: ${red_color}Not installed${color_end} | 內核: ${red_color}未安装${color_end}"
    fi

    if [[ "$environment_bbr2" = "true" ]]; then
        echo -e "BBR2: ${green_color}Enabled${color_end} | BBR2: ${green_color}已启用${color_end}"
    elif [[ "$environment_kernel" = "true" ]]; then
        echo -e "BBR2: ${red_color}Disabled${color_end} | BBR2: ${red_color}已禁用${color_end}"
    fi

    if [[ "$environment_ecn" = "true" ]]; then
        echo -e "ECN: ${green_color}Enabled${color_end} | ECN: ${green_color}已启用${color_end}"
    elif [[ "$environment_bbr2" = "true" ]]; then
        echo -e "ECN: ${red_color}Disabled${color_end} | ECN: ${red_color}已禁用${color_end}"
    fi
}

install_kernel() {
    if [[ "$environment_headers" != "true" ]]; then
        [ ! -f "linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb" ] && wget --no-check-certificate -O linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb "https://backstore.netlify.com/bbr2yy2/linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb"
        [ ! -f "linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb" ] && echo "Error! Download file failed! File \"linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb\" Not Found!" && echo "错误！下载文件失败！找不到文件 \"linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb\"" && exit 1
    fi
    if [[ "$environment_image" != "true" ]]; then
        [ ! -f "linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb" ] && wget --no-check-certificate -O linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb "https://backstore.netlify.com/bbr2yy2/linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb"
        [ ! -f "linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb" ] && echo "Error! Download file failed! File \"linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb\" Not Found!" && echo "错误！下载文件失败！找不到文件 \"linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb\"" && exit 1
    fi
    [[ "$environment_headers" != "true" ]] && dpkg -i linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb
    [[ "$environment_image" != "true" ]] && dpkg -i linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb
    rm -f linux-headers-5.4.0-rc6_5.4.0-rc6-2_amd64.deb linux-image-5.4.0-rc6_5.4.0-rc6-2_amd64.deb
    update-grub
}
enable_bbr2() {
    sed -i "/tcp_dctcp/d" /etc/modules-load.d/modules.conf
    sed -i "/tcp_bbr2/d" /etc/modules-load.d/modules.conf
    sed -i "/tcp_bbr/d" /etc/modules-load.d/modules.conf
    sed -i "/tcp_dctcp/d" /etc/modules
    sed -i "/tcp_bbr2/d" /etc/modules
    sed -i "/tcp_bbr/d" /etc/modules
    modprobe tcp_bbr2
    echo "tcp_bbr2" >> /etc/modules
    sed -i "/net.core.default_qdisc/d" /etc/sysctl.conf
    sed -i "/net.ipv4.tcp_congestion_control/d" /etc/sysctl.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr2" >> /etc/sysctl.conf
    sysctl -p
}
disable_bbr2() {
    sed -i "/tcp_bbr2/d" /etc/modules
    sed -i "/net.core.default_qdisc/d" /etc/sysctl.conf
    sed -i "/net.ipv4.tcp_congestion_control/d" /etc/sysctl.conf
    sed -i "/net.ipv4.tcp_ecn/d" /etc/sysctl.conf
    echo 0 > /sys/module/tcp_bbr2/parameters/ecn_enable
    sysctl -p
    sed -i "/\/sys\/module\/tcp_bbr2\/parameters\/ecn_enable/d" /etc/rc.local
}
enable_ecn() {
    sed -i "/net.ipv4.tcp_ecn/d" /etc/sysctl.conf
    echo "net.ipv4.tcp_ecn=1" >> /etc/sysctl.conf
    echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable
    sysctl -p
    sed -i "/\/sys\/module\/tcp_bbr2\/parameters\/ecn_enable/d" /etc/rc.local
    add_to_rc.local "echo 1 > /sys/module/tcp_bbr2/parameters/ecn_enable"
}
disable_ecn() {
    sed -i "/net.ipv4.tcp_ecn/d" /etc/sysctl.conf
    echo 0 > /sys/module/tcp_bbr2/parameters/ecn_enable
    sysctl -p
    sed -i "/\/sys\/module\/tcp_bbr2\/parameters\/ecn_enable/d" /etc/rc.local
}
remove_other_kernels() {
    if [[ "$environment_kernel" != "true" ]]; then
        echo 'Abort kernel removal? Choose <No>'
        echo '当出现"Abort kernel removal?"选项时，请选择 <No>'
        echo 'Abort kernel removal? Choose <No>'
        echo '当出现"Abort kernel removal?"选项时，请选择 <No>'
        echo 'Abort kernel removal? Choose <No>'
        echo '当出现"Abort kernel removal?"选项时，请选择 <No>'
        sleep 5s
    fi
    apt-get purge -y $other_linux_images $other_linux_headers
    update-grub
}


do_option() {
    case "$1" in
        0)
            exit 0
            ;;
        1)
            [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]] && echo "Invalid option." && echo "无效的选项。" && return 1
            install_kernel
            check_environment
            if [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]]; then
                echo "Please reboot and then run this script again to enable BBR2."
                echo "请重新启动然后再次执行此脚本以启动BBR2。"
                read -p "Reboot now? | 现在立即重启？ (y/n) " reboot
                [ -z "${reboot}" ] && reboot="y"
            	if [[ $reboot == [Yy] ]]; then
            		echo "Rebooting..."
                	echo "正在重新启动..."
            		reboot
            	fi
            else
                echo "Error! Kernel install failed!"
                echo "错误！內核安装失败！"
                return 1
            fi
            ;;
        2)
            [[ "$environment_kernel" != "true" ]] && echo "Invalid option." && echo "无效的选项。" && return 1
            [[ "$environment_bbr2" = "true" ]] && echo "Invalid option." && echo "无效的选项。" && return 1
            enable_bbr2
            ;;
        3)
            [[ "$environment_bbr2" != "true" ]] && echo "Invalid option." && echo "无效的选项。" && return 1
            disable_bbr2
            ;;
        4)
            [[ "$environment_bbr2" != "true" ]] && echo "Invalid option." && echo "无效的选项。" && return 1
            [[ "$environment_ecn" = "true" ]] && echo "Invalid option." && echo "无效的选项。" && return 1
            enable_ecn
            ;;
        5)
            [[ "$environment_ecn" != "true" ]] && echo "Invalid option." && echo "无效的选项。" && return 1
            disable_ecn
            ;;
        6)
            if [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]] && [[ "$environment_otherkernels" = "true" ]]; then
                remove_other_kernels
            else
                echo "Invalid option." && echo "无效的选项。" && return 1
            fi
            ;;
        7)
            if [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]] && [[ "$environment_kernel" != "true" ]]; then
                reboot
            else
                echo "Invalid option." && echo "无效的选项。" && return 1
            fi
            ;;
            
    esac
}

auto_install() {
    check_environment
    if [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]] && [[ "$environment_kernel" != "true" ]]; then
        this_file_path=${this_file_path//"/"/"\\/"} && sed -i "/bash $this_file_path auto/d" /etc/rc.local && this_file_path=${this_file_path//"\\/"/"/"}
        cat >> $this_file_dir/bbr2.sh.log << EOF
        Error! Install failed!
        Umm... It seems like you have installed the kernel for BBR2 but not using it...
        Maybe you have to manually remove other kernels and then reboot.
        错误！安装失败！
        呃...这看起来你已经安装了BBR2的內核但是並沒有启用。
        或许你需要手动卸载其余的內核然后重启。
EOF
        cat $this_file_dir/bbr2.sh.log
        exit 1
    elif [[ "$environment_kernel" != "true" ]]; then
        install_kernel
        check_environment
        if [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]]; then
            add_to_rc.local "bash $this_file_path auto"
            reboot
        else
            echo "Error! Kernel install failed!" >> $this_file_dir/bbr2.sh.log
            echo "错误！內核安装失败！" >> $this_file_dir/bbr2.sh.log
            cat $this_file_dir/bbr2.sh.log
            exit 1
        fi
    elif [[ "$environment_kernel" = "true" ]]; then
        enable_bbr2
        enable_ecn
        this_file_path=${this_file_path//"/"/"\\/"} && sed -i "/bash $this_file_path auto/d" /etc/rc.local && this_file_path=${this_file_path//"\\/"/"/"}
        check_environment
        if [[ "$environment_bbr2" = "true" ]] && [[ "$environment_ecn" = "true" ]]; then
            analyze_environment
            # If succeeded, no output to the log file. 这边成功就不输出到log文件了吧？故意的。
        else
            echo "Error! BBR2 install failed!" >> $this_file_dir/bbr2.sh.log
            echo $(analyze_environment) >> $this_file_dir/bbr2.sh.log
            cat $this_file_dir/bbr2.sh.log
            exit 1
        fi
    fi
}

[[ "$1" = "auto" ]] && auto_install && exit 0

while :
do
echo "+----------------------------------+" &&
echo "|  BBR2 V2 一键安装 for Debian x64 |" &&
echo "|        2019-11-21 Alpha-2        |" &&
echo "+----------------------------------+"

check_environment
analyze_environment

echo "What do you want to do? | 您要来点啥？"

while :
do
    echo "0) Exit script. | 退出脚本。 (0"
    if [[ "$environment_headers" != "true" ]] || [[ "$environment_image" != "true" ]]; then echo "1) Install the kernel for BBR2. | 安装通用BBR2的内核。 (1"; fi
    [[ "$environment_kernel" = "true" ]] && [[ "$environment_bbr2" != "true" ]] && echo "2) Enable BBR2. | 启用BBR2。 (2"
    [[ "$environment_bbr2" = "true" ]] && echo "3) Disable BBR2. | 禁用BBR2。 (3"
    [[ "$environment_bbr2" = "true" ]] && [[ "$environment_ecn" != "true" ]] && echo "4) Enable ECN. | 启用ECN。 (4"
    [[ "$environment_ecn" = "true" ]] && echo "5) Disable ECN. | 禁用ECN。 (5"
    [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]] && [[ "$environment_otherkernels" = "true" ]] && echo "6) Remove other kernels. | 卸载其余內核。 (6"
    [[ "$environment_headers" = "true" ]] && [[ "$environment_image" = "true" ]] && [[ "$environment_kernel" != "true" ]] && echo "7) reboot. | 重新启动。 (7"
    unset choose_an_option
    read -p "Choose an option. | 选择一个选项。 (Input a number | 输入一个数字) " choose_an_option

    if [[ "$choose_an_option" = "0" ]] || [[ "$choose_an_option" = "1" ]] || [[ "$choose_an_option" = "2" ]] || [[ "$choose_an_option" = "3" ]] || [[ "$choose_an_option" = "4" ]] || [[ "$choose_an_option" = "5" ]] || [[ "$choose_an_option" = "6" ]] || [[ "$choose_an_option" = "7" ]]; then
        do_option $choose_an_option
        break
    else
        continue
    fi
done

done