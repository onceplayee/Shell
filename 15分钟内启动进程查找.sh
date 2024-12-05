#!/bin/bash

# 获取所有进程的PID，并保存到/root/shell/PID.txt文件中
ps -eo pid | sed '1d' > /root/shell/PID.txt

# 逐行读取/root/shell/PID.txt文件中的PID
while read LINE;do

# 获取当前时间戳
NOW_TIME=$(date +%s)
# 获取进程启动时间戳
PRS_TIME=$(date -d "$(ps -p ${LINE} -o lstart | grep -v "STARTED" )" +%s)
# 计算时间差
TIME_DIFF=$((NOW_TIME - PRS_TIME))

# 如果时间差小于900秒（15分钟），则输出进程信息
	if [ ${TIME_DIFF} -lt 900 ];then
	    # 获取进程名称
	    PNAME=$(ps -p ${LINE} -o comm=)
	    # 获取最近一次启动时间
	    LSTART_TIME=$(date -d @$(date -d "$(ps -p ${LINE} -o lstart | grep -v "STARTED")" +%s) +%F_%T)
	    # 输出进程信息
	    echo -e  "十五分钟内启动的进程为\033[32m：${PNAME}\033[0m\nPID：\033[33m${LINE}\033[0m\n最近一次启动时间为\033[31m${LSTART_TIME}\033[0m\n"
	
    	fi;

done < /root/shell/PID.txt
