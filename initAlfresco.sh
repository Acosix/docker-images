#!/bin/bash

set -e

DB_USER=${DB_USER:=alfresco}
DB_PW=${DB_PW:=alfresco}
DB_NAME=${DB_NAME:=alfresco}
DB_HOST=${DB_HOST:=localhost}
DB_PORT=${DB_PORT:=-1}

POSTGRES_ENABLED=${POSTGRES_ENABLED:=false}
MYSQL_ENABLED=${MYSQL_ENABLED:=false}
DB2_ENABLED=${DB2_ENABLED:=false}
MSSQL_ENABLED=${MSSQL_ENABLED:=false}
ORACLE_ENABLED=${ORACLE_ENABLED:=false}

ENABLE_SSL_PROXY=${ENABLE_SSL_PROXY:=false}
PROXY_NAME=${PROXY_NAME:=localhost}
PROXY_PORT=${PROXY_PORT:=80}
PROXY_SSL_PORT=${PROXY_SSL_PORT:=443}

ENABLE_SHARE_SSL_PROXY=${ENABLE_SHARE_SSL_PROXY:=false}
SHARE_PROXY_NAME=${SHARE_PROXY_NAME:=localhost}
SHARE_PROXY_PORT=${SHARE_PROXY_PORT:=80}
SHARE_PROXY_SSL_PORT=${SHARE_PROXY_SSL_PORT:=443}

SEARCH_SUBSYSTEM=${SEARCH_SUBSYSTEM:=solr6}
SOLR_HOST=${SOLR_HOST:=localhost}
SOLR_PORT=${SOLR_PORT:=80}
SOLR_SSL_PORT=${SOLR_SSL_PORT:=443}
ACCESS_SOLR_VIA_SSL=${ACCESS_SOLR_VIA_SSL:=false}

PROXY_NAME=${PROXY_NAME:=localhost}
PROXY_NAME_RAW=${PROXY_NAME_RAW:-$PROXY_NAME}
PROXY_PORT_RAW=${PROXY_PORT_RAW:=8082}
PROXY_SSL_PORT_RAW=${PROXY_SSL_PORT_RAW:=8083}

REQUIRED_ARTIFACTS=${MAVEN_REQUIRED_ARTIFACTS:=''}
PLATFORM_VERSION=${ALFRESCO_PLATFORM_VERSION:=5.2.f}
LEGACY_SUPPORT_TOOLS_INSTALLED=${ALFRESCO_SUPPORT_TOOLS_INSTALLED:=false}

INIT_KEYSTORE_FROM_DEFAULT=${INIT_KEYSTORE_FROM_DEFAULT:=true}

if [ ! -f '/var/lib/tomcat7/.alfrescoInitDone' ]
then
	if [ ! -d '/srv/alfresco/data' ]
	then
		echo "Data directory has not been provided / mounted"
		exit 1
	fi

	if [ ! -d '/srv/alfresco/data/contentstore' ]
	then
		mkdir -p /srv/alfresco/data/contentstore
		mkdir -p /srv/alfresco/data/contentstore.deleted
		chown -R tomcat7:tomcat7 /srv/alfresco/data
	fi

	if [[ $POSTGRES_ENABLED == true ]]
	then
		if [[ $MYSQL_ENABLED == true || $DB2_ENABLED == true || $MSSQL_ENABLED == true || $ORACLE_ENABLED == true ]]
		then
			echo "Multiple types of database to use have been configured"
			exit 1
		fi
		DB_ACT_KEY="#usePostgreSQL#"
		if [[ $DB_PORT == -1 ]]
		then
			DB_PORT=5432
		fi
	elif [[ $MYSQL_ENABLED == true ]]
	then
		if [[ $DB2_ENABLED == true || $MSSQL_ENABLED == true || $ORACLE_ENABLED == true ]]
		then
			echo "Multiple types of database to use have been configured"
			exit 1
		fi
		DB_ACT_KEY="#useMySQL#"
		if [[ $DB_PORT == -1 ]]
		then
			DB_PORT=3006
		fi
	elif [[ $DB2_ENABLED == true ]]
	then
		if [[ $MSSQL_ENABLED == true || $ORACLE_ENABLED == true ]]
		then
			echo "Multiple types of database to use have been configured"
			exit 1
		fi
		DB_ACT_KEY="#useDB2#"
		if [[ $DB_PORT == -1 ]]
		then
			DB_PORT=50000
		fi
	elif [[ $MSSQL_ENABLED == true ]]
	then
		if [[ $ORACLE_ENABLED == true ]]
		then
			echo "Multiple types of database to use have been configured"
			exit 1
		fi
		DB_ACT_KEY="#useMSSQL#"
		if [[ $DB_PORT == -1 ]]
		then
			DB_PORT=1433
		fi
	elif [[ $ORACLE_ENABLED == true ]]
	then
		DB_ACT_KEY="#useOracle#"
		if [[ $DB_PORT == -1 ]]
		then
			DB_PORT=1521
		fi
	else
		echo "Type of database to use has not been configured"
        exit 1
	fi
	sed -i "s/${DB_ACT_KEY}//g" /var/lib/tomcat7/shared/classes/alfresco-global.properties

	sed -i "s/%DB_HOST%/${DB_HOST}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%DB_PORT%/${DB_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%DB_NAME%/${DB_NAME}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%DB_USER%/${DB_USER}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%DB_PW%/${DB_PW}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties

	sed -i "s/%SEARCH_SUBSYSTEM%/${SEARCH_SUBSYSTEM}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%SOLR_HOST%/${SOLR_HOST}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%SOLR_PORT%/${SOLR_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%SOLR_SSL_PORT%/${SOLR_SSL_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	
	if [[ $ACCESS_SOLR_VIA_SSL == true ]]
	then
		sed -i "s/%SOLR_COMMS%/https/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	else
		sed -i "s/%SOLR_COMMS%/none/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	fi

	if [[ $ENABLE_SSL_PROXY == true ]]
	then
		sed -i "s/%PROXY_PROTO%/https/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
		sed -i "s/%PROXY_PORT%/${PROXY_SSL_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	else
		sed -i "s/%PROXY_PROTO%/http/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
		sed -i "s/%PROXY_PORT%/${PROXY_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	fi

	if [[ $ENABLE_SHARE_SSL_PROXY == true ]]
	then
		sed -i "s/%SHARE_PROXY_PROTO%/https/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
		sed -i "s/%SHARE_PROXY_PORT%/${SHARE_PROXY_SSL_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	else
		sed -i "s/%SHARE_PROXY_PROTO%/http/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
		sed -i "s/%SHARE_PROXY_PORT%/${SHARE_PROXY_PORT}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	fi

	sed -i "s/%PROXY_NAME%/${PROXY_NAME}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	sed -i "s/%SHARE_PROXY_NAME%/${SHARE_PROXY_NAME}/g" /var/lib/tomcat7/shared/classes/alfresco-global.properties

	CUSTOM_APPENDER_LIST='';

	# otherwise for will also cut on whitespace
	IFS=$'\n'
	for i in `env`
	do
		if [[ $i == GLOBAL_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`

			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/alfresco-global.properties; then
				sed -i "s/^${key}=.*/${key}=${value}/" /var/lib/tomcat7/shared/classes/alfresco-global.properties
			else
				echo "${key}=${value}" >> /var/lib/tomcat7/shared/classes/alfresco-global.properties
			fi

			if [[ $key == hibernate.default_schema ]]
			then
				sed -i "s/#useCustomSchema#//g" /var/lib/tomcat7/shared/classes/alfresco-global.properties
			fi
		fi

		if [[ $i == LOG4J-APPENDER_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			appenderName=`echo $key | cut -d '.' -f 1`
			value=`echo "$i" | cut -d '=' -f 2-`
			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties; then
				sed -i "s/^log4j\.appender\.${key}=.*/log4j.appender.${key}=${value}/" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
			else
				echo "log4j.appender.${key}=${value}" >> /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
			fi

			if [[ ! $CUSTOM_APPENDER_LIST =~ "^,([^,]+,)*${appenderName}(,[^,$]+)*$" ]]
			then
				CUSTOM_APPENDER_LIST="${CUSTOM_APPENDER_LIST},${appenderName}"
			fi
		fi

		if [[ $i == LOG4J-LOGGER_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`
			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties; then
				sed -i "s/^log4j\.logger\.${key}=.*/log4j.logger.${key}=${value}/" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
			else
				echo "log4j.logger.${key}=${value}" >> /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
			fi
		fi

		if [[ $i == LOG4J-ADDITIVITY_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`
			if grep --quiet "^${key}=" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties; then
				sed -i "s/^log4j\.additivity\.${key}=.*/log4j.additivity.${key}=${value}/" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
			else
				echo "log4j.additivity.${key}=${value}" >> /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
			fi
		fi
	done
	sed -i "s/#customAppenderList#/${CUSTOM_APPENDER_LIST}/" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties

	# either the module is installed explicitly, we have an Enterprise Edition version, or a specific flag is set
	if [[ $REQUIRED_ARTIFACTS =~ '^(.+,)*alfresco-support-tools(,.+)*$' || $PLATFORM_VERSION =~ '^(5\.[2-9]\.\d(\.d)?|[6-9]\.\d\.\d(\.d)?)$' || $LEGACY_SUPPORT_TOOLS_INSTALLED == true ]]
	then
		sed -i "s/#withAlfrescoSupportTools#//g" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
	else
		sed -i "s/#withoutAlfrescoSupportTools#//g" /var/lib/tomcat7/shared/classes/alfresco/extension/dev-log4j.properties
	fi

	if [ ! -f '/var/lib/tomcat7/webapps/alfresco.war' ]
	then
		if [[ -d '/srv/alfresco/defaultArtifacts' ]]
		then
			echo "Using default artifacts: $(ls -A /srv/alfresco/defaultArtifacts)"
			# in case folder is empty we have to suppress error code
			cp /srv/alfresco/defaultArtifacts/* /tmp/ 2>/dev/null || :
		fi
		echo "Preparing Repository WARs (including modules)"
		jjs -scripting /var/lib/tomcat7/prepareWarFiles.js -- /tmp
		mv /tmp/*.war /var/lib/tomcat7/webapps/
		rm -f /tmp/*.jar /tmp/*.amp /tmp/*.war*
	fi

	if [[ $INIT_KEYSTORE_FROM_DEFAULT == true && -z "$(ls -A /srv/alfresco/keystore)" ]]
	then
		echo "Initialising keystore from default"
		unzip /var/lib/tomcat7/webapps/alfresco.war WEB-INF/lib/alfresco-repository-*.jar -d /tmp/alfresco
		REPO_JAR=$(ls -A /tmp/alfresco/WEB-INF/lib/alfresco-repository-*.jar)
		unzip "/tmp/alfresco/WEB-INF/lib/${REPO_JAR}" alfresco/keystore/* -d /tmp/alfresco-repo
		cp /tmp/alfresco-repo/alfresco/keystore/* /srv/alfresco/keystore/
		rm -rf /tmp/alfresco /tmp/alfresco-repo
	fi

	if [[ -f '/srv/alfresco/keystore/keystore' && -f '/srv/alfresco/keystore/keystore-passwords.properties' ]]
	then
		echo "Referencing custom keystore"
		sed -i "/^#useCustomKeystore#/d" /var/lib/tomcat7/shared/classes/alfresco-global.properties
	fi

	echo "Setting up raw HTTP connector"
	sed -i '/<Engine/i <Connector executor="tomcatThreadPool" port="8082" protocol="HTTP/1.1"' /etc/tomcat7/server.xml
	sed -i '/<Engine/i connectionTimeout="20000" redirectPort="%PROXY_SSL_PORT_RAW%" URIEncoding="UTF-8" maxHttpHeaderSize="32768"' /etc/tomcat7/server.xml
	sed -i '/<Engine/i proxyName="%PROXY_NAME_RAW%" proxyPort="%PROXY_PORT_RAW%" />' /etc/tomcat7/server.xml

	if [[ -f '/srv/alfresco/keystore/ssl.keystore' && -f '/srv/alfresco/keystore/ssl-keystore-passwords.properties' && -f '/srv/alfresco/keystore/ssl.truststore' && -f '/srv/alfresco/keystore/ssl-truststore-passwords.properties' ]]
	then
		echo "Setting up raw SSL connector and Tomcat users"

		SSL_KEYSTORE_PASSWORD=$(grep 'keystore.password=' /srv/alfresco/keystore/ssl-keystore-passwords.properties | sed -r 's/keystore\.password=(.+)/\1/')
		SSL_TRUSTSTORE_PASSWORD=$(grep 'keystore.password=' /srv/alfresco/keystore/ssl-truststore-passwords.properties | sed -r 's/keystore\.password=(.+)/\1/')

		sed -i '/<Engine/i <Connector executor="tomcatThreadPool" port="8083" protocol="org.apache.coyote.http11.Http11Protocol" SSLEnabled="true"' /etc/tomcat7/server.xml
		sed -i '/<Engine/i proxyName="%PROXY_NAME_RAW%" proxyPort="%PROXY_SSL_PORT_RAW%"' /etc/tomcat7/server.xml
		sed -i '/<Engine/i scheme="https" secure="true"' /etc/tomcat7/server.xml
		sed -i "/<Engine/i keystoreFile=\"/srv/alfresco/keystore/ssl.keystore\" keystorePass=\"${SSL_KEYSTORE_PASSWORD}\" keystoreType=\"JCEKS\"" /etc/tomcat7/server.xml
		sed -i "/<Engine/i truststoreFile=\"/srv/alfresco/keystore/ssl.truststore\" truststorePass=\"${SSL_TRUSTSTORE_PASSWORD}\" truststoreType=\"JCEKS\"" /etc/tomcat7/server.xml
		sed -i '/<Engine/i clientAuth="want" sslProtocol="TLS" connectionTimeout="240000"' /etc/tomcat7/server.xml
		sed -i '/<Engine/i URIEncoding="UTF-8" maxHttpHeaderSize="32768" allowUnsafeLegacyRenegotiation="true" />' /etc/tomcat7/server.xml
		sed -i "s/%SSL_KEYSTORE_PASSWORD%/${SSL_KEYSTORE_PASSWORD}/" /etc/tomcat7/server.xml
		sed -i "s/%SSL_TRUSTSTORE_PASSWORD%/${SSL_TRUSTSTORE_PASSWORD}/" /etc/tomcat7/server.xml

		sed -i '/<\/tomcat-users>/i <user username="CN=Alfresco Repository Client, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB" roles="repoclient" password="null" />' /etc/tomcat7/tomcat-users.xml
	fi
	
	sed -i "s/%PROXY_NAME_RAW%/${PROXY_NAME_RAW}/" /etc/tomcat7/server.xml
	sed -i "s/%PROXY_PORT_RAW%/${PROXY_PORT_RAW}/" /etc/tomcat7/server.xml
	sed -i "s/%PROXY_SSL_PORT_RAW%/${PROXY_SSL_PORT_RAW}/" /etc/tomcat7/server.xml

	touch /var/lib/tomcat7/.alfrescoInitDone
fi