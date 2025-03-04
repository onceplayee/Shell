#!/bin/bash
# init_server.sh - 服务器初始化脚本
# 适用于 CentOS 7
#
# 功能：
# 1. 设置指定网卡为静态 IP
# 2. 禁止 SSH 以 root 用户登陆
# 3. 替换yum源为阿里云源并创建缓存
# 4. 关闭 SELinux
# 5. 关闭 firewalld 防火墙
# 6. 配置时间同步（安装并启动 chrony）
#
# 注意：请根据实际情况修改以下变量

# 检查是否以root身份运行
if [ "$(id -u)" -ne 0 ]; then
    echo "请以root身份运行此脚本"
    exit 1
fi

##############################
# 1. 配置静态IP
##############################
# 请修改以下变量为你的实际网络配置
INTERFACE="eth0"
STATIC_IP="192.168.1.100"
NETMASK="255.255.255.0"
GATEWAY="192.168.1.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"

CONFIG_FILE="/etc/sysconfig/network-scripts/ifcfg-${INTERFACE}"
if [ -f "$CONFIG_FILE" ]; then
    echo "配置 ${INTERFACE} 为静态IP..."
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" || echo "备份 $CONFIG_FILE 失败，请检查权限"
    # 清除原有相关配置，并写入新的配置
    sed -i '/^BOOTPROTO/d' "$CONFIG_FILE"
    sed -i '/^ONBOOT/d' "$CONFIG_FILE"
    sed -i '/^IPADDR/d' "$CONFIG_FILE"
    sed -i '/^NETMASK/d' "$CONFIG_FILE"
    sed -i '/^GATEWAY/d' "$CONFIG_FILE"
    sed -i '/^DNS1/d' "$CONFIG_FILE"
    sed -i '/^DNS2/d' "$CONFIG_FILE"
    echo "BOOTPROTO=static" >> "$CONFIG_FILE"
    echo "ONBOOT=yes" >> "$CONFIG_FILE"
    echo "IPADDR=${STATIC_IP}" >> "$CONFIG_FILE"
    echo "NETMASK=${NETMASK}" >> "$CONFIG_FILE"
    echo "GATEWAY=${GATEWAY}" >> "$CONFIG_FILE"
    echo "DNS1=${DNS1}" >> "$CONFIG_FILE"
    echo "DNS2=${DNS2}" >> "$CONFIG_FILE"
    systemctl restart network && echo "网络服务重启成功" || echo "网络服务重启失败，请手动检查"
else
    echo "网卡配置文件 ${CONFIG_FILE} 不存在，跳过静态IP设置"
fi

##############################
# 2. 禁止SSH以root用户登陆
##############################
SSHD_CONFIG="/etc/ssh/sshd_config"
if [ -f "$SSHD_CONFIG" ]; then
    echo "禁止SSH以root用户登陆..."
    cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak" || echo "备份 $SSHD_CONFIG 失败"
    # 修改或添加 PermitRootLogin no
    if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
        sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    else
        echo "PermitRootLogin no" >> "$SSHD_CONFIG"
    fi
    systemctl restart sshd && echo "sshd 重启成功" || echo "sshd 重启失败，请手动检查"
else
    echo "$SSHD_CONFIG 文件不存在，跳过SSH配置"
fi

##############################
# 3. 配置yum源并创建cache
##############################
echo "更新yum源为阿里云源..."
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo \
    && echo "yum源更新成功" \
    || echo "wget更新yum源失败，请检查网络连接"
yum clean all && yum makecache && echo "yum缓存创建成功" || echo "yum缓存创建失败"

##############################
# 4. 关闭SELinux
##############################
SELINUX_CONFIG="/etc/selinux/config"
if [ -f "$SELINUX_CONFIG" ]; then
    echo "关闭SELinux..."
    cp "$SELINUX_CONFIG" "${SELINUX_CONFIG}.bak" || echo "备份 SELinux 配置失败"
    sed -i 's/^SELINUX=.*/SELINUX=disabled/' "$SELINUX_CONFIG"
    setenforce 0 && echo "SELinux setenforce 0 成功" || echo "setenforce 0 失败，请检查SELinux状态"
else
    echo "$SELINUX_CONFIG 文件不存在，跳过SELinux配置"
fi

##############################
# 5. 关闭firewalld
##############################
if systemctl status firewalld &>/dev/null; then
    echo "关闭firewalld防火墙..."
    systemctl stop firewalld && echo "firewalld 已停止" || echo "停止firewalld失败"
    systemctl disable firewalld && echo "firewalld 已禁用" || echo "禁用firewalld失败"
else
    echo "firewalld 未安装或已停止"
fi

##############################
# 6. 配置时间同步（使用 chrony）
##############################
echo "配置时间同步..."
if ! rpm -q chrony &>/dev/null; then
    echo "安装chrony..."
    yum install -y chrony && echo "chrony 安装成功" || echo "chrony 安装失败，请检查yum源"
fi
systemctl enable chronyd && systemctl start chronyd \
    && echo "chronyd 启动成功" \
    || echo "chronyd 启动失败，请手动检查"

echo "服务器初始化完成，请检查以上输出是否有错误提示。"
