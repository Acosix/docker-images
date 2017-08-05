#!/bin/bash

set -e

DEBUG=${DEBUG:=false}

REPOSITORY_HOST=${REPOSITORY_HOST:=localhost}
REPOSITORY_PORT=${REPOSITORY_PORT:=80}
ACCESS_REPOSITORY_VIA_SSL=${ACCESS_REPOSITORY_VIA_SSL:=false}
REPOSITORY_SSL_PORT=${REPOSITORY_SSL_PORT:=443}

PUBLIC_REPOSITORY_HOST=${PUBLIC_REPOSITORY_HOST:-$REPOSITORY_HOST}
PUBLIC_REPOSITORY_PORT=${PUBLIC_REPOSITORY_PORT:-$REPOSITORY_PORT}
ACCESS_PUBLIC_REPOSITORY_VIA_SSL=${ACCESS_PUBLIC_REPOSITORY_VIA_SSL:-$ACCESS_REPOSITORY_VIA_SSL}
PUBLIC_REPOSITORY_SSL_PORT=${PUBLIC_REPOSITORY_SSL_PORT:-$REPOSITORY_SSL_PORT}

PROXY_NAME=${PROXY_NAME:=localhost}
PROXY_PORT=${PROXY_PORT:=80}
PROXY_SSL_PORT=${PROXY_SSL_PORT:=443}
PUBLIC_SHARE_HOST=${PUBLIC_SHARE_HOST:-${PROXY_NAME}}
PUBLIC_SHARE_PORT=${PUBLIC_SHARE_PORT:-${PROXY_PORT}}
PUBLIC_SHARE_SSL_PORT=${PUBLIC_SHARE_SSL_PORT:-${PROXY_SSL_PORT}}

KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD:=alfresco-system}
TRUSTSTORE_PASSWORD=${TRUSTSTORE_PASSWORD:=password}

# TODO Kerberos and other global config
ACTIVATE_SSO=${ACTIVATE_SSO:=false}

if [ ! -f '/var/lib/tomcat7/.shareInitDone' ]
then
	
	sed -i "s/%DEBUG%/${DEBUG}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	if [[ $DEBUG == true ]]
	then
		sed -i "s/%MODE%/development/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	else
		sed -i "s/%MODE%/production/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	fi
	
	sed -i "s/%REPOSITORY_HOST%/${REPOSITORY_HOST}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	sed -i "s/%REPOSITORY_PORT%/${REPOSITORY_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	sed -i "s/%REPOSITORY_SSL_PORT%/${REPOSITORY_SSL_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	
	sed -i "s/%PUBLIC_REPOSITORY_HOST%/${PUBLIC_REPOSITORY_HOST}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	sed -i "s/%PUBLIC_REPOSITORY_PORT%/${PUBLIC_REPOSITORY_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	sed -i "s/%PUBLIC_REPOSITORY_SSL_PORT%/${PUBLIC_REPOSITORY_SSL_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	
	PUBLIC_SHARE_HOST_PATTERN=`echo $PUBLIC_SHARE_HOST | sed -e "s/\./\\./g"`
	sed -i "s/%PUBLIC_SHARE_HOST_PATTERN%/${PUBLIC_SHARE_HOST_PATTERN}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	if [[ $PUBLIC_SHARE_PORT != 80 || $PUBLIC_SHARE_SSL_PORT != 443 ]]
	then
		sed -i "s/%PUBLIC_SHARE_PORT_PATTERN%/(:(${PUBLIC_SHARE_PORT}|${PUBLIC_SHARE_SSL_PORT}))?/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	else
		sed -i "s/%PUBLIC_SHARE_PORT_PATTERN%//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	fi
	
	sed -i "s/%KEYSTORE_PASSWORD%/${KEYSTORE_PASSWORD}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	sed -i "s/%TRUSTSTORE_PASSWORD%/${TRUSTSTORE_PASSWORD}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml

	if [[ $ACCESS_REPOSITORY_VIA_SSL == true && -f '/var/lib/tomcat7/shared/classes/alfresco/web-extension/alfresco-system.p12' && -f '/var/lib/tomcat7/shared/classes/alfresco/web-extension/ssl-truststore' ]]
	then
		sed -i "s/<!--%ACCESS_REPOSITORY_VIA_SSL%//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
		sed -i "s/%ACCESS_REPOSITORY_VIA_SSL%-->//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
		
		if [[ $ACTIVATE_SSO == true ]]
		then
			sed -i "s/<!--%ACTIVATE_SSO_VIA_SSL%//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
			sed -i "s/%ACTIVATE_SSO_VIA_SSL%-->//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
		fi
	fi
	
	if [[ $ACTIVATE_SSO == true ]]
	then
		sed -i "s/<!--%ACTIVATE_SSO%//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
		sed -i "s/%ACTIVATE_SSO%-->//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	fi
	
	if [[ $ACCESS_PUBLIC_REPOSITORY_VIA_SSL == true ]]
	then
		sed -i "s/<!--%ACCESS_PUBLIC_REPOSITORY_VIA_SSL%//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
		sed -i "s/%ACCESS_PUBLIC_REPOSITORY_VIA_SSL%-->//g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/share-config-custom.xml
	fi
	
	CUSTOM_APPENDER_LIST='';

	# otherwise for will also cut on whitespace
	IFS=$'\n'
	for i in `env`
    do
        if [[ $i == GLOBAL_* ]]
		then
            key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`
			
			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/share-global.properties; then
				sed -i "s/^${key}=.*/${key}=${value}/" /var/lib/tomcat7/shared/classes/share-global.properties
			else
				echo "${key}=${value}" >> /var/lib/tomcat7/shared/classes/share-global.properties
			fi
        fi
		
		if [[ $i == LOG4J-APPENDER_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			appenderName=`echo $key | cut -d '.' -f 1`
			value=`echo "$i" | cut -d '=' -f 2-`
			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties; then
				sed -i "s/^log4j\.appender\.${key}=.*/log4j.appender.${key}=${value}/" /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties
			else
				echo "log4j.appender.${key}=${value}" >> /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties
			fi
			
			if [[ ! $CUSTOM_APPENDER_LIST =~ "^,([^,]+,)*${appenderName}(,[^,]+)*$" ]]
			then
				CUSTOM_APPENDER_LIST="${CUSTOM_APPENDER_LIST},${appenderName}"
			fi
		fi
		
		if [[ $i == LOG4J-LOGGER_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`
			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties; then
				sed -i "s/^log4j\.logger\.${key}=.*/log4j.logger.${key}=${value}/" /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties
			else
				echo "log4j.logger.${key}=${value}" >> /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties
			fi
		fi

		if [[ $i == LOG4J-ADDITIVITY_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`
			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties; then
				sed -i "s/^log4j\.additivity\.${key}=.*/log4j.additivity.${key}=${value}/" /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties
			else
				echo "log4j.additivity.${key}=${value}" >> /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties
			fi
		fi
    done
	sed -i "s/#customAppenderList#/${CUSTOM_APPENDER_LIST}/g" /var/lib/tomcat7/shared/classes/alfresco/web-extension/dev-log4j.properties
	
	if [ ! -f '/var/lib/tomcat7/webapps/share.war' ]
	then
		if [[ -d '/srv/alfresco/defaultArtifacts' ]]
		then
			# in case folder is empty we have to suppress error code
			cp /srv/alfresco/defaultArtifacts/* /tmp/ 2>/dev/null || :
		fi
		jjs -scripting /var/lib/tomcat7/prepareWarFiles.js -- /tmp
		mv /tmp/*.war /var/lib/tomcat7/webapps/
		rm -f /tmp/*.jar /tmp/*.amp /tmp/*.war*
	fi
	
	# adapt insensible default logger configuration
	unzip /var/lib/tomcat7/webapps/share.war WEB-INF/classes/log4j.properties -d /tmp/share
	sed -i 's/rootLogger=error, Console/rootLogger=error/' /tmp/share/WEB-INF/classes/log4j.properties
	sed -i 's/File=share\.log/File=\${catalina.base}\/logs\/share.log/' /tmp/share/WEB-INF/classes/log4j.properties
	sed -i 's/yyyy-MM-dd HH:mm:ss.SSS/ISO8601/' /tmp/share/WEB-INF/classes/log4j.properties
	cd /tmp/share
	zip -r /var/lib/tomcat7/webapps/share.war .
	cd /
	rm -rf /tmp/share

	# Share has issues when WAR files are not unpacked
	sed -i 's/unpackWARs="false"/unpackWARs="true"/' /etc/tomcat7/server.xml
	
	touch /var/lib/tomcat7/.shareInitDone
fi