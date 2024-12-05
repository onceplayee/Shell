#!/bin/bash

ZM=$(cat /dev/urandom | tr -dc 'A-Z' | head -c 1)
case $ZM in
A)
	echo "WTF"
;;

B)
	echo "WTF"
;;

c)
	echo "WTF"
;;

D)
	echo "WTF"
;;

E)
	echo "WTF"
;;


esac
