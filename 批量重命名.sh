#!/bin/bash

# 提示用户输入文件目录
read -p "请输入文件目录：" DIR

# 判断输入的目录是否存在
if [ ! -d $DIR ];then
	# 如果目录不存在，输出错误信息并退出
	echo -e "\033[31m无法进入目录${DIR},请检查目录是否存在或拼写是否错误!\033[0m"
	exit 1
fi

# 提示用户输入初始后缀名
read -p "请输入初始后缀名：" OLD_BACK_NAME
# 提示用户输入重命名后缀名
read -p "请输入重命名后缀名：" NEW_BACK_NAME
# 获取当前时间
TIME=$(date +%Y_%m_%d)
# 查找指定目录下所有以初始后缀名结尾的文件，并将结果输出到指定文件
find ${DIR} -name "*.${OLD_BACK_NAME}" > /root/shell/RENAME.txt

# 逐行读取指定文件中的文件名
while read LINE; do
    # 判断文件是否存在
    if [ -f "${LINE}" ]; then
        # 构造新的文件名
        NEW_FILE="${LINE}_${TIME}.${NEW_BACK_NAME}"
        # 重命名文件
        mv "${LINE}" "$NEW_FILE" 
    else
	# 如果文件不存在，输出错误信息并继续
	echo -e  "\033[31m重命名 ${LINE} 失败\033[31m"
	continue
    fi
done < /root/shell/RENAME.txt
