#!/bin/bash

set -e

DEBUG=${DEBUG:=false}
PROXY_NAME=${PROXY_NAME:=localhost}
PROXY_PORT=${PROXY_PORT:=80}
ENABLE_SSL_PROXY=${ENABLE_SSL_PROXY:=false}
PROXY_SSL_PORT=${PROXY_SSL_PORT:=443}
JAVA_OPTS=${JAVA_OPTS:=''}

JMX_ENABLED=${JMX_ENABLED:=false}
JMX_RMI_HOST=${JMX_RMI_HOST:=127.0.0.1}
JMX_RMI_PORT=${JMX_RMI_PORT:=5000}

JAVA_XMS=${JAVA_XMS:=512M}
JAVA_XMX=${JAVA_XMX:-$JAVA_XMS}

JAVA_OPTS_JMX_CHECK='-Dcom\.sun\.management\.jmxremote(\.(port|authenticate|local\.only|ssl|rmi\.port)=[^\s]+)?'

MIN_CON_THREADS=${MIN_CON_THREADS:=10}
MAX_CON_THREADS=${MAX_CON_THREADS:=200}

if [ ! -f '/var/lib/tomcat7/.tomcatInitDone' ]
then

	if [[ $JMX_ENABLED == true && ! $JAVA_OPTS =~ $JAVA_OPTS_JMX_CHECK ]]
	then
		JAVA_OPTS="${JAVA_OPTS} -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=${JMX_RMI_PORT} -Dcom.sun.management.jmxremote.rmi.port=${JMX_RMI_PORT}"
		if [[ ! $JAVA_OPTS =~ '-Djava.rmi.server.hostname=[^\s]+' ]]
		then
			JAVA_OPTS="${JAVA_OPTS} -Djava.rmi.server.hostname=${JMX_RMI_HOST}"
		fi
	fi
	
	if [[ ! $JAVA_OPTS =~ '-Xmx\d+[gGmM]' ]]
	then
		JAVA_OPTS="${JAVA_OPTS} -Xmx${JAVA_XMX}"
	fi
	
	if [[ ! $JAVA_OPTS =~ '-Xms\d+[gGmM]' ]]
	then
		JAVA_OPTS="${JAVA_OPTS} -Xms${JAVA_XMS}"
	fi
	
	if [[ ! $JAVA_OPTS =~ '-XX:\+Use(G1|ConcMarkSweep|Serial|Parallel|ParallelOld|ParNew)GC' ]]
	then
		JAVA_OPTS="${JAVA_OPTS} -XX:+UseG1GC"
	fi

	# need to encode any forward slahes in JAVA_OPTS
	JAVA_OPTS=$(echo "${JAVA_OPTS}" | sed -r "s/(\/)/\\\\\1/g")

	sed -i "s/%JAVA_OPTS%/${JAVA_OPTS}/" /etc/default/tomcat7
	sed -i "s/%PROXY_NAME%/${PROXY_NAME}/g" /etc/tomcat7/server.xml
	sed -i "s/%PROXY_PORT%/${PROXY_PORT}/g" /etc/tomcat7/server.xml
	sed -i "s/%PROXY_SSL_PORT%/${PROXY_SSL_PORT}/g" /etc/tomcat7/server.xml
	sed -i "s/%MIN_CONNECTOR_THREADS%/${MIN_CON_THREADS}/g" /etc/tomcat7/server.xml
	sed -i "s/%MAX_CONNECTOR_THREADS%/${MAX_CON_THREADS}/g" /etc/tomcat7/server.xml
	
	if [[ $ENABLE_SSL_PROXY == true ]]
	then
		sed -i "s/<!--%SSL_PROXY%//g" /etc/tomcat7/server.xml
		sed -i "s/%SSL_PROXY%-->//g" /etc/tomcat7/server.xml
	fi
	
	touch /var/lib/tomcat7/.tomcatInitDone
fi