#!/bin/bash

if [ -z $1  ];then
	echo "帮助信息：请在$0后键入IO或者SQL"
	exit 99
else 
	USER="root"
	PASSWORD="$Mqt3090786752!"

STATE=$(mysql -u${USER} --password=${PASSWORD} -e "show slave status\G" 2> /dev/null | grep -w "Slave_${1}_Running:" | awk '{print $2}')

case $STATE in
	Yes)
		echo 1 
		;;	
  	 No)
      		echo 0
      	 	;;
    	 *)
      	   	echo "404 NOT FOUND"
		;;
esac

fi
