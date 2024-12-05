#!/bin/bash

NGINX_CMD=/usr/local/nginx/sbin/nginx		#定义变量NGINX_CMD来存储nginx服务的可执行文件路径
NGINX_PID=/usr/local/nginx/logs/nginx.pid	#定义变量NGINX_PID来存储nginx服务的进程id
if [ -z $1 ];then	#if条件判断开始，判断参数是否存在
		echo "help: $0 <start|stop|status|restart|reload>"	#不存在则输出帮助信息
	exit 99		#以99状态码退出
else

case $1 in	#case条件判断开始，当第一个参数等于......
#启动服务，查看/usr/local/nginx/logs/nginx.pid文件是否存在
    start)
	if [ -z ${NGINX_PID} ];then	#如果存在输出已经启动
		echo "nginx服务已经启动"
	else
	$NGINX_CMD &> /dev/null		#否则执行 /usr/local/nginx/sbin/nginx 来启动nginx服务
		echo "nginx服务启动完成"
	fi
;;
#停止服务，使用ps命令查看进程是否存在
     stop)
	if ps -elf | grep nginx | grep -v "grep" &> /dev/null ;then	#if条件判断，进程存在为真
	${NGINX_CMD} -s stop	#关闭nginx服务
		echo "nginx服务关闭成功"
	else
		echo "nginx服务已经关闭"
	fi
;;
#重启，检查语法是否正确
  restart)
	if $NGINX_CMD -t &> /dev/null ;then	#语法正确为真
        ${NGINX_CMD} -s restart &> /dev/null
        echo "nginx服务重启完成"
        else
            $NGINX_CMD -t	#语法错误状态码返回不为0
                if [ $? -ne 0  ];then
                        echo "请检查语法是否正确"
                fi
        fi

;;
#查看状态，使用ps查看进程，判断是否运行
   status)
	if ps -elf | grep nginx | grep -v "grep" &> /dev/null ;then #if条件判断，进程存在为真
		echo "nginx服务运行中"
	else
		echo "nginx服务未启动"
	fi
;;
#重载，检查语法正确与否
   reload) 	
	if $NGINX_CMD -t &> /dev/null ;then	#if条件判断。语法正确为真
	${NGINX_CMD} -s reload &> /dev/null
	echo "nginx.conf重载完成"
	else
	    $NGINX_CMD -t
		if [ $? -ne 0  ];then		#语法错误为假
			echo "请检查语法是否正确"
		fi
	fi
;;
#其他情况，输出帮助
       	*)
	echo "$0 <start|stop|restart|status|reload>"
;;
esac	#case条件判断结束
fi	#if条件判断结束
