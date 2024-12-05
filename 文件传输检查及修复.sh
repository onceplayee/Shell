#!/bin/bash

# 提示用户输入源目录
read -p "请输入源目录：" DIR1
# 提示用户输入目的目录
read -p "请输入目的目录：" DIR2

# 判断源目录和目的目录是否存在
if [ ! -d ${DIR1} ] && [ ! -d ${DIR2} ];then
	echo -e "\033[31m目录 ${DIR1} 和 ${DIR2} 不存在，请检查是否存在输入错误\033[0m"
# 判断源目录是否存在
elif [ ! -d ${DIR1} ];then
	echo -e "\033[31m目录 ${DIR1} 不存在，请检查是否存在输入错误\033[0m"
# 判断目的目录是否存在
elif [ ! -d ${DIR2} ];then
	echo -e "\033[31m目录 ${DIR2} 不存在，请检查是否存在输入错误\033[0m"
# 判断源目录和目的目录都存在
elif [ -d ${DIR1} ] && [ -d ${DIR2} ];then

# 查找源目录下的所有文件，并排除隐藏文件，将结果保存到FILE_INFO1.txt文件中
find ${DIR1} -type f -not -name ".*" | sed "s|${DIR1}||" > /root/shell/FILE_INFO1.txt
      while read -r LINE;do
	# 将源目录和目的目录拼接成完整的文件路径
	FILE_INFO1="${DIR1}${LINE}"
	FILE_INFO2="${DIR2}${LINE}"
	# 判断目的目录下是否存在该文件
	if [ -f ${FILE_INFO2} ];then	
	   # 计算源文件和目的文件的MD5值
	   MD5_FILE1=$(md5sum ${FILE_INFO1} | awk '{print $1}')
           MD5_FILE2=$(md5sum ${FILE_INFO2} | awk '{print $1}')
		# 判断MD5值是否相同
		if [ "${MD5_FILE1}" == "${MD5_FILE2}" ];then
			echo -e "\033[32m${FILE_INFO2}文件传输无误\033[0m"
		else
			echo -e "\033[31m${FILE_INFO2}文件传输存在错误\033[0m"
			echo "正在进行修复工作"
			# 使用rsync命令修复文件
			rsync -a ${FILE_INFO1} ${FILE_INFO2} &> /dev/null
			      if [ $? -eq 0 ];then
				 echo "修复完成"
			      else
				 echo "修复失败，请手动修复"
			      fi 
		fi
	else
		echo -e "\033[31m${FILE_INFO2}不存在于${DIR2}\033[0m"		
		echo "正在进行修复工作"
		# 使用cp命令修复文件
		cp -r ${FILE_INFO1} ${DIR2} &> /dev/null
		      if [ $? -eq 0 ];then
			 echo "修复完成"
		      else
			 echo "修复失败，请手动修复"
		      fi 
	fi
done < /root/shell/FILE_INFO1.txt  
fi
