#!/bin/bash

master_ip="192.168.44.36"
master_port="7002"

node=$(netstat -tunlp | grep redis | awk '{print $4,$7}')
netstat -tunlp | grep redis | grep ${master_ip}:${master_port} &>/dev/null
if [ $? -ne 0 ];then
    echo -e "请检查是否存在主节点IP或端口出现错误输入，或者主节点是否启动,当前启动的redis节点为\n${node}"
    echo -e "您的主节点为${master_ip}:${master_port}"
    exit 99
fi

redis-cli -h ${master_ip} -p ${master_port} info replication &> /root/shell/redis_mscopy.txt

if [ -s "/root/shell/redis_mscopy.txt" ];then
link_number=$(cat /root/shell/redis_mscopy.txt | grep ^"slave" | wc -l)
    for number in $link_number;do
        if [ ${link_number} -ne 0 ];then
        link_info=$(cat /root/shell/redis_status.txt | grep ^"slave")
            echo -e "当前从节点连接数为 ${link_number}"
            echo -e "${link_info}"
        else
            echo "错误！当前无连接从节点"
        fi;
    done
fi
