#!/bin/bash

master_ip=192.168.44.36
master_port=7001
echo -e 您指定的主节点为${master_ip}:${master_port}
nodes=$(netstat -tunlp | grep redis | awk '{print $4}')
netstat -tunlp | grep redis | grep ${master_ip}:${master_port} &>/dev/null
if [ $? -ne 0 ];then
    echo -e "请检查是否存在主节点IP或端口出现错误输入，或者主节点是否启动,当前启动的redis节点为\n${nodes}"
    exit 99
fi

redis-cli -h ${master_ip} -p ${master_port} info  &>/root/shell/redis_status.txt

if [ -s /root/shell/redis_status.txt ];then
process_id=$(cat /root/shell/redis_status.txt | grep -w process_id | awk -F: '{print $2}')
used_cpu_sys=$(cat /root/shell/redis_status.txt | grep -w used_cpu_sys | grep -v 'used_cpu_sys_children' | awk -F: '{print $2}')
used_cpu_user=$(cat /root/shell/redis_status.txt | grep -w used_cpu_user | grep -v 'used_cpu_user_children' | awk -F: '{print $2}')
used_cpu_sys_children=$(cat /root/shell/redis_status.txt | grep -w used_cpu_sys_children | awk -F: '{print $2}')
used_cpu_user_children=$(cat /root/shell/redis_status.txt | grep -w used_cpu_user_children | awk -F: '{print $2}')
used_memory_human=$(cat /root/shell/redis_status.txt | grep -w used_memory_human | awk -F: '{print $2}')
used_memory_rss_human=$(cat /root/shell/redis_status.txt | grep -w used_memory_rss_human | awk -F: '{print $2}')
total_connections_received=$(cat /root/shell/redis_status.txt | grep -w total_connections_received | awk -F: '{print $2}')
rejected_connections=$(cat /root/shell/redis_status.txt | grep -w rejected_connections | awk -F: '{print $2}')
total_net_input_bytes=$(cat /root/shell/redis_status.txt | grep -w total_net_input_bytes | awk -F: '{print $2}')
total_net_output_bytes=$(cat /root/shell/redis_status.txt | grep -w total_net_output_bytes |awk -F: '{print $2}' )
keyspace_hits=$(cat /root/shell/redis_status.txt | grep -w keyspace_hits |awk -F: '{print $2}' )
keyspace_misses=$(cat /root/shell/redis_status.txt | grep -w keyspace_misses | awk -F: '{print $2}')
fi

echo -e "redis资源使用概要:"
echo -e "进程ID:\t\t${process_id}"
echo -e "系统使用CPU(%):\t${used_cpu_sys}"
echo -e "用户使用CPU(%):\t${used_cpu_user}"
echo -e "系统子进程(%):\t${used_cpu_sys_children}"
echo -e "用户子进程(%):\t${used_cpu_user_children}"
echo -e "已使用内存:\t${used_memory_human}"
echo -e "常驻内存集大小:\t${used_memory_rss_human}"
echo -e "接收的连接数:\t${total_connections_received}"
echo -e "拒绝的连接数:\t${rejected_connections}"
echo -e "流入流量(字节):\t${total_net_input_bytes}"
echo -e "流出流量(字节):\t${total_net_output_bytes}"
echo -e "缓存命中次数:\t${keyspace_hits}"
echo -e "缓存丢失次数:\t${keyspace_misses}"
