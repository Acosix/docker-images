#!/bin/bash

set -e

LO_PORT=8100
TOMCAT7_USER=tomcat7

# otherwise for will also cut on whitespace
IFS=$'\n'
for i in `env`
do
	if [[ $i == "GLOBAL_ooo.port" ]]
	then
		LO_PORT=`echo "$i" | cut -d '=' -f 2-`
	fi
done

exec /sbin/setuser $TOMCAT7_USER /usr/bin/libreoffice --nologo --norestore --invisible --headless --accept='socket,host=0,port=${LO_PORT},tcpNoDelay=1;urp;'