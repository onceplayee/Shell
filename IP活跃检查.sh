#!/bin/bash
#

# 定义子网地址
subnet=10.11.11.

# 循环遍历子网地址
for i in $(seq 1 254); do
    {
    # 构造IP地址
    ip=$subnet$i
    # 使用ping命令检测IP地址是否可达
    if ping -c 1 -W 1 $ip &> /dev/null; then
       # 如果可达，输出提示信息
       echo "Host $ip is up"
    fi
    }&
done
# 等待所有子进程结束
wait

