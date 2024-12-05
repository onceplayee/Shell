#!/bin/bash

N=1
LINE_1=$(df -Th | grep -v "^tmpfs" | sed '1d' | awk '{print $6}' | sed 's/%//g' | wc -l) #定义LINE_1储存df -Th的除去第一行和过滤掉tmpfs的行数
LINE=$((${LINE_1} + 1)) #行数加一为head使用
#{1..$LINE_1} $linu_1是多少就循环几次
for i in $(seq 1 $LINE_1) 
#循环开始
do 
#定义head命令的-n参数
HEAD=$(($LINE - $N)) 
#N++
N=$((${N}+1))
#查看当前$LINE_1行截取的过滤tmpfs和百分号的磁盘使用率
DISK=$(df -Th | grep -v "^tmpfs" | sed '1d' | awk '{print $6}' | sed 's/%//g' | head -n ${HEAD} | tail -n 1 ) 
#正常为绿色
RESULT_GREEN="${DISK}%\t$(df -Th | grep -v "^tmpfs" | sed '1d'  | awk '{print $1}' | sed 's/%//g' | head -n ${HEAD} | tail -n 1)\t\033[32mIS NORMAL\033[0m"
#超过70%为红色
RESULT_RED="${DISK}%\t$(df -Th | grep -v "^tmpfs" |sed '1d' | awk '{print $1}' | sed 's/%//g' | head -n ${HEAD} | tail -n 1)\t\033[31mWARRING!!!\033[0m"
#if条件判断 $DISK 是否大于70
	#是输出 $RESULT_RED
    if [ ${DISK} -gt 70 ];then
	echo -e  "${RESULT_RED}"
	#不是则输出 $RESUTLE_GREEN
    else
	echo -e  "${RESULT_GREEN}"
    fi;
#循环结束
done
