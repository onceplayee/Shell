#!/bin/bash

USER="root"
PASSWD="Mqt3090786752!"
LIST_NUM=$(mysql -u$USER --password=${PASSWD} -e "SHOW PROCESSLIST" 2> /dev/null | sed '1d' | wc -l)

echo "当前连接数为 $LIST_NUM"

if [ ${LIST_NUM} -gt 10 ];then
	echo "警告！连接数超过10！"
else 
	echo "一切正常！"
fi
