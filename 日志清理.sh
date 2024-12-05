#!/bin/bash
# 获取当前时间戳
NOW_TIME=$(date +%s)
# 遍历/var/log目录下的所有以.log结尾的文件
for LOG in $(find /var/log -type f  -name "*.log"); do
	# 获取文件的创建时间戳
	LOG_CREATE_TIME=$(stat -c %Y "${LOG}")

	# 计算当前时间与文件创建时间的差值
	TIME_DIFF=$((NOW_TIME - LOG_CREATE_TIME))
	# 如果差值大于259200（3天），则删除文件
	if [ ${TIME_DIFF} -gt 259200 ];then
		rm -f ${LOG}
		echo "三日之前的日志文件${LOG}成功删除"
	# 否则，输出未找到三日之前的日志文件，并跳出循环
	else	
		echo "未找到三日之前的日志文件"
		break
	fi;
done
