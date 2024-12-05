#!/bin/bash

# 检查/root/.ssh目录下是否存在id_rsa文件，如果存在则删除
if [ -f /root/.ssh/id_rsa ];then
	rm -rf /root/.ssh/id_rsa*
fi

# 生成rsa密钥对
ssh-keygen -t rsa -f /root/.ssh/id_rsa -P "" &> /dev/null

# 清空/root/.ssh/known_hosts文件
> /root/.ssh/known_hosts

# 循环执行ssh-copy-id命令，将公钥复制到目标主机
for i in 37 38;do
/usr/bin/expect << EOF &> /dev/null
set timeout 10
spawn ssh-copy-id root@192.168.44.$i
expect "(yes/no)?"
send "yes\n"
expect "password:"
send "561300\n"
expect EOF
EOF
done

# 检查ssh-copy-id命令是否执行成功
if [ $? -eq 0 ];then
echo "执行成功"
else
echo "执行失败"
fi
