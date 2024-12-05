#!/bin/bash

# 读取用户输入的网卡设备名
read -p "请输入你的网卡设备名：" DEVICE_NAME
# 读取用户输入的IP地址
read -p "请输入你的IP地址：" IPADDRESSES
# 读取用户输入的网关
read -p "请输入你的网关：" GATEWAY
# 读取用户输入的主DNS
read -p "请输入你的主DNS：" DNS1
# 读取用户输入的备用DNS
read -p "请输入你的备用DNS：" DNS2

# 获取网卡设备类型
DEVICE_TYPE=$(nmcli connection show | grep "${DEVICE_NAME}" | awk '{print $3}') &> /dev/null
# 获取网卡设备ID
DEVICE_ID=$(nmcli connection show | grep "${DEVICE_NAME}" | awk '{print $2}')
# 删除原有网卡配置
nmcli connection delete ${DEVICE_ID} &> /dev/null
# 添加新的网卡配置
nmcli connection add type ethernet ifname ${DEVICE_NAME} con-name ${DEVICE_NAME} &> /dev/null
# 设置IP地址
nmcli connection modify ens33 ipv4.addresses "${IPADDRESSES}"
# 设置网关
nmcli connection modify ens33 ipv4.gateway "${GAETWAY}"
# 设置主DNS
nmcli connection modify ens33 ipv4.dns "${DNS1}"
# 设置备用DNS
nmcli connection modify ens33 +ipv4.dns "${DNS2}"
# 设置IP获取方式为手动
nmcli connection modify ens33 ipv4.method manual
# 设置网卡自动连接
nmcli connection modify ens33 autoconnect on
# 重新加载网卡配置
nmcli connection reload
# 启用网卡
nmcli connection up ${DEVICE_NAME} &> /dev/null

# 判断网卡配置是否成功
if [ $? -eq 0 ];then
	echo "网卡${DEVICE_NAME}重新配置成功"
else
	echo "网卡${DEVICE_NAME}重新配置失败"
fi
