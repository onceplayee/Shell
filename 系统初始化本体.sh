#!/bin/bash

# 定义红色输出函数
echo_red() { echo -e "\e[31m$1\e[0m"; }
# 定义绿色输出函数
echo_green() { echo -e "\e[32m$1\e[0m"; }
# 定义黄色输出函数
echo_yellow() { echo -e "\e[33m$1\e[0m"; }

# 获取默认网关接口
interface=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
# 获取本地IP地址
LocalIP=$(ip addr show $interface | awk '/inet / {print $2}' | cut -d/ -f1 | tail -1)
# 获取系统发行版
linux=$(awk -F "("  '{print $1}' /etc/redhat-release)
# 获取主机名
hostname=$(cat /etc/hostname)

# 输出系统信息
echo_yellow "当前系统发行版为  $linux"
echo_yellow "当前系统网卡名为  $interface"
echo_yellow "本机IP地址为      $LocalIP"
echo_yellow "本机主机名为      $hostname"
echo_yellow "内核版本为        $(uname -r)"

# 等待2秒
sleep 2
echo_yellow '正在初始化请稍后...'
# 管理网络
manage_network(){
    # 获取网卡是否为开机自动连接
autoconnect=$(nmcli dev show $interface | grep 'GENERAL.AUTOCONNECT:' | awk '{print $2}')
    # 如果网卡不是开机自动连接，则设置为开机自动连接
if [[ "$autoconnect" != "yes" ]]; then
    echo_yellow "检查网卡是否为开机自动连接..."
    nmcli con mod $interface connection.autoconnect yes &>/dev/null
    nmcli con up $interface &>/dev/null
    sed -i '/^ONBOOT/ c ONBOOT=yes' /etc/sysconfig/network-scripts/"ifcfg-${interface}" &>/dev/null
    systemctl restart network &>/dev/null
    echo_green "网卡已设置为开机自动连接"
else
    echo_green "网卡已设置为开机自动连接"
fi

    # 获取IP地址模式
ip_mode=$(nmcli dev show $interface | grep 'IP4.ADDRESS[1]' | awk '{print $2}')
    # 获取网关和DNS
gateway_dns=$(ip addr show $interface | awk '/inet / {split($2,a,"."); print a[1]"."a[2]"."a[3]}')
    # 获取IP地址模式2
ip_mode2=$(grep BOOTPROTO /etc/sysconfig/network-scripts/"ifcfg-$interface" | awk -F "=" '{print $2}')

# 如果IP地址模式为空或者不是静态IP地址，则设置为静态IP地址
if [[ -z "$ip_mode" ]] || [ "$ip_mode2" != static ] ; then
    echo_green "正在检查网卡是否为静态IP地址..."
    nmcli con mod $interface ipv4.addresses "${LocalIP}/24" &>/dev/null
    nmcli con mod $interface ipv4.gateway "${gateway_dns}.2" &>/dev/null
    nmcli con mod $interface ipv4.dns "114.114.114.114" &>/dev/null
    nmcli con mod $interface +ipv4.dns "223.5.5.5" &>/dev/null
    nmcli con mod $interface ipv4.method manual &>/dev/null
    nmcli con up $interface &>/dev/null
    sed -i '/^BOOTPROTO/ c BOOTPROTO=static' /etc/sysconfig/network-scripts/"ifcfg-${interface}" &>/dev/null
    systemctl restart network &>/dev/null
    echo_green "网卡已设置静态IP"
else
    echo_green "网卡已设置静态IP"
fi


    # 检查网络连通性
for n in {1..3}; do
    if ping -c 1 -w 1 www.jd.com &>/dev/null; then
        echo_green "网络连通正常"
        break
    else
        echo_red "网络错误请检查网络配置"
        echo_yellow "正在尝试重启网络（尝试次数：$n）"
        systemctl restart network &>/dev/null
	nmcli con reload &>/dev/null
        nmcli con up $interface &>/dev/null
	ping -c 1 -w 1 www.jd.com &>/dev/null
	if [ $? -eq 0 ];then
	         echo_green "网络连通正常"
		 break
	else
	   	 echo_red "网络连接失败"
	fi
    fi
done
}
manage_network

# 管理SELinux
manage_selinux() {
    # 获取SELinux状态
    SELINUXSTATUS=$(getenforce)

    # 如果SELinux未关闭，则关闭SELinux
    if [[ "$SELINUXSTATUS" == "Disabled" ]]; then
        echo_green "SELinux已关闭"
    else
        echo_red "SELinux未关闭，正在关闭..."
        sed -i '/^SELINUX=/ c\SELINUX=disabled' /etc/selinux/config
        setenforce 0
        if [[ "$(getenforce)" == "Disabled" ]]; then
            echo_green "SELinux已成功关闭"
        else
            echo_red "SELinux未能关闭，请手动解决"
        fi
    fi
}

manage_selinux 

# 管理firewalld
manage_firewalld(){
    # 获取firewalld状态
FIREWALLSTATUS=$(systemctl is-active firewalld.service)

    # 如果firewalld开启，则关闭firewalld
if [[ "$FIREWALLSTATUS" == "active" ]]; then
    echo_yellow "防火墙状态为开启，正在关闭防火墙..."
    systemctl disable --now firewalld.service &>/dev/null
    systemctl mask firewalld.service &>/dev/null
    echo_green "防火墙已关闭"
else
    echo_green "防火墙无需操作"
fi
}

manage_firewalld

# 管理yum
manage_yum(){
# 备份原有的CentOS-Base.repo
echo_yellow "正在备份原有的yum源配置文件..."
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup &>/dev/null
if [ $? -ne 0 ]; then
    echo_red "备份yum源配置文件失败，请检查权限或文件路径"
else
    echo_green "备份成功"
fi

# 下载新的CentOS-Base.repo
echo_yellow "正在下载新的yum源配置文件..."
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo &>/dev/null
if [ $? -eq 0 ]; then
    echo_green "新的yum源配置文件下载成功"
else
    echo_red "下载新的yum源配置文件失败，请检查网络连接或URL"
fi
:
# 清空yum缓存
echo_yellow "正在清空yum缓存..."
yum clean all &>/dev/null
if [ $? -eq 0 ]; then
    echo_green "yum缓存清空成功"
else
    echo_red "清空yum缓存失败"
fi

# 检查yum源是否更新成功
echo_yellow "正在检查yum源是否更新成功..."
yum makecache &>/dev/null
if [ $? -eq 0 ]; then
    echo_green "yum源更新成功"
else
    echo_red "yum源更新失败，请检查配置文件"
fi

# 安装常用软件
PACKAGES="lrzsz cowsay ntpdate ntp git elinks lftp lvm2 sysstat net-tools wget vim bash-completion dos2unix tree psmisc chrony rsync lsof"
echo_yellow "正在安装常用软件..."
yum -y install $PACKAGES &>/dev/null

if [ $? -eq 0 ]; then
    echo_green "安装成功"
else
    echo_red "安装失败，请检测yum镜像仓库"
fi
}

manage_yum

# 管理ntpdate
manage_ntpdate(){
    # 检查ntpd服务状态
    systemctl status ntpd &>/dev/null
    if [ $? -eq 0 ];then
    	# 停止ntpd服务
    	systemctl stop ntpd &>/dev/null
    	# 同步时间
    	ntpdate pool.ntp.org &>/dev/null
	# 启动ntpd服务
	systemctl enable --now ntpd &>/dev/null
	echo_green "时间同步完成。当前系统时间为$(date +%F_%T)"    
    # 同步时间
    else
        ntpdate pool.ntp.org &>/dev/null
	if [ $? -eq 0 ];then
    	    # 启动ntpd服务
    	    systemctl enable --now ntpd &>/dev/null
	    echo_green "时间同步完成。当前系统时间为$(date +%F_%T)"
	else 
	    echo_red "时间同步失败"	
	fi
    fi

}

manage_ntpdate

# 管理ssh
manage_ssh(){
    # 禁止root用户远程登录
    sed -i "s/PermitRootLogin yes//g" /etc/ssh/sshd_config
    echo "PermitRootLogin no" >> /etc/ssh/sshd_config
    sshd -t &>/dev/null
	if [ $? -eq 0 ];then
    	    echo_green "配置禁止ssh以root身份远程登录成功,退出脚本或者重启系统后实现此配置"
	else
	    echo_red "配置禁止ssh以root身份登录失败，请手动配置该文件 /etc/ssh/sshd_config"
fi
}

manage_ssh

# 管理系统语言
manage_language(){
   # 设置系统语言为en_US.UTF-8
   echo "export LANG=en_US.UTF-8" >> /root/.bashrc
   # 加载.bashrc文件
	source /root/.bashrc &>/dev/null
	if [ $? -eq 0 ];then
		echo_green "系统语言设置完成：en_US.UTF-8"
	else
		echo_red "系统语言设置失败，请手动设置"
	fi
}

manage_language

# 输出系统初始化完成
echo_green "系统初始化完成"
systemctl enable --now sshd
