#!/bin/sh

LO_PORT=${GLOBAL_ooo.port:=8100}
TOMCAT7_USER=tomcat7

exec /sbin/setuser $TOMCAT7_USER /usr/lib/libreoffice/program/soffice --nologo --norestore --invisible --headless --accept='socket,host=0,port=${LO_PORT},tcpNoDelay=1;urp;'