#!/bin/bash

# 检查/root/.ssh目录下是否存在id_rsa文件，如果存在则删除
if [ -f /root/.ssh/id_rsa ];then
        rm -rf /root/.ssh/id_rsa*
fi

# 生成rsa密钥对
ssh-keygen -t rsa -f /root/.ssh/id_rsa -P "" &> /dev/null

# 清空/root/.ssh/known_hosts文件
> /root/.ssh/known_hosts

# 定义子网地址
subnet=192.168.44.
host=$(hostname -I | awk '{print $1}')
gateway=$(ip route | head -n1 | awk '{print $3}')

# 循环遍历子网地址
for i in $(seq 11 254); do
    {
    if [ $i -eq 36 ];then
    continue
    fi
# 构造IP地址
    ip=$subnet$i
        # 使用ping命令检测IP地址是否可达
    if ping -c 1 -W 1 $ip &> /dev/null; then

#循环执行ssh-copy-id命令，将公钥复制到目标主机
/usr/bin/expect << EOF &> /dev/null
set timeout 10
spawn ssh-copy-id root@$ip
expect "(yes/no)?"
send "yes\n"
expect "password:"
send "561300\n"
expect EOF
EOF
# 检查ssh-copy-id命令是否执行成功
        if [ $? -ne 0 ];then
                echo "$ip 执行失败"
                continue
        fi
                scp /root/INIT.sh root@$ip:/root/ &>/dev/null
        if [ $? -ne 0 ];then
                echo "复制脚本失败"
        else
                echo "正在初始化${ip}"
                ssh root@$ip bash /root/INIT.sh &>/var/sysinit.log
                if [ $? -eq 0 ];then
                        echo "${ip}初始化成功"
                fi
        fi
fi
    }&
done
wait
