#!/bin/bash

set -e

ENABLED_CORES=${ENABLED_CORES:=alfresco,archive}

SOLR_HOST=${SOLR_HOST:=localhost}
SOLR_PORT=${SOLR_PORT:=8983}

REPOSITORY_HOST=${REPOSITORY_HOST:=localhost}
REPOSITORY_PORT=${REPOSITORY_PORT:=80}
ACCESS_REPOSITORY_VIA_SSL=${ACCESS_REPOSITORY_VIA_SSL:=false}
REPOSITORY_SSL_PORT=${REPOSITORY_SSL_PORT:=443}

ASS_VERSION=${ASS_VERSION:=1.0.0}

IFS=',' read -ra CORE_LIST <<< "$ENABLED_CORES"

# a base image does may pre-package ASS to keep the image light
if [ ! -d '/var/lib/alfresco-search-services' ]
then
	wget -P /tmp "https://artifacts.alfresco.com/nexus/service/local/repositories/releases/content/org/alfresco/alfresco-search-services/${ASS_VERSION}/alfresco-search-services-${ASS_VERSION}.zip"
	unzip "/tmp/alfresco-search-services-${ASS_VERSION}.zip" -d /var/lib/

	sed -i 's/^#SOLR_HOME=/SOLR_HOME=\/srv\/alfresco-search-services\/solrhome/' /var/lib/alfresco-search-services/solr.in.sh
	sed -i 's/^SOLR_LOGS_DIR=.*/SOLR_LOGS_DIR=\/var\/log\/alfresco-search-services/' /var/lib/alfresco-search-services/solr.in.sh
	sed -i 's/^LOG4J_PROPS=.*/LOG4J_PROPS=\/var\/lib\/alfresco-search-services\/logs\/log4j.properties/' /var/lib/alfresco-search-services/solr.in.sh
	sed -i '/-remove_old_solr_logs/d' /var/lib/alfresco-search-services/solr/bin/solr
	sed -i '/-archive_gc_logs/d' /var/lib/alfresco-search-services/solr/bin/solr
	sed -i '/-archive_console_logs/d' /var/lib/alfresco-search-services/solr/bin/solr
	sed -i '/-rotate_solr_logs/d' /var/lib/alfresco-search-services/solr/bin/solr
	sed -i '/set that as the rmi server hostname/,/fi/ s/SOLR_HOST/JMX_HOST/' /var/lib/alfresco-search-services/solr/bin/solr
	sed -i 's/rootLogger=WARN, file, CONSOLE/rootLogger=WARN, file/' /var/lib/alfresco-search-services/logs/log4j.properties
	sed -i 's/\.RollingFileAppender$/.DailyRollingFileAppender/' /var/lib/alfresco-search-services/logs/log4j.properties
	sed -i 's/MaxFileSize=4MB$/DatePattern='.'yyyy-MM-dd/' /var/lib/alfresco-search-services/logs/log4j.properties
	sed -i 's/MaxBackupIndex=9$/Append=true/' /var/lib/alfresco-search-services/logs/log4j.properties
	sed -i 's/yyyy-MM-dd HH:mm:ss.SSS/ISO8601/' /var/lib/alfresco-search-services/logs/log4j.properties
	mkdir -p /srv/alfresco-search-services/solrhome /srv/alfresco-search-services/contentstore /var/log/alfresco-search-services
	mv /var/lib/alfresco-search-services/solrhome/* /srv/alfresco-search-services/solrhome/
	rm -rf /var/lib/alfresco-search-services/solr/docs /var/lib/alfresco-search-services/solrhome
	sed -i 's/solr\.host=localhost/solr.host=%PUBLIC_SOLR_HOST%/' /srv/alfresco-search-services/solrhome/conf/shared.properties
	sed -i 's/#solr\.port=8983/solr.port=%PUBLIC_SOLR_PORT%/' /srv/alfresco-search-services/solrhome/conf/shared.properties
	chown -R solr:solr /var/lib/alfresco-search-services /srv/alfresco-search-services/solrhome /srv/alfresco-search-services/contentstore /var/log/alfresco-search-services

	# define additional parameters so that our initialisation will allow overriding them
	echo "#JMX_HOST=" >> /var/lib/alfresco-search-services/solr.in.sh
fi

if [ ! -f '/var/lib/alfresco-search-services/.assInitDone' ]
then
	sed -i "s/%PUBLIC_SOLR_HOST%/${SOLR_HOST}/g" /srv/alfresco-search-services/solrhome/conf/shared.properties
	sed -i "s/%PUBLIC_SOLR_PORT%/${SOLR_PORT}/g" /srv/alfresco-search-services/solrhome/conf/shared.properties

	CUSTOM_APPENDER_LIST=''

	# otherwise for will also cut on whitespace
	IFS=$'\n'
	for i in `env`
    do
		value=`echo "$i" | cut -d '=' -f 2-`
        if [[ $i == LOG4J-APPENDER_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			appenderName=`echo $key | cut -d '.' -f 1`
			if grep --quiet "^${key}=" /var/lib/alfresco-search-services/logs/log4j.properties; then
				sed -i "s/^log4j\.appender\.${key}=.*/log4j.appender.${key}=${value}/" /var/lib/alfresco-search-services/logs/log4j.properties
			else
				echo "log4j.appender.${key}=${value}" >> /var/lib/alfresco-search-services/logs/log4j.properties
			fi

			if [[ ! $CUSTOM_APPENDER_LIST =~ "^,([^,]+,)*${appenderName}(,[^,$]+)*$" ]]
			then
				CUSTOM_APPENDER_LIST="${CUSTOM_APPENDER_LIST},${appenderName}"
			fi
		elif [[ $i == LOG4J-LOGGER_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			if grep --quiet "^${key}=" /var/lib/alfresco-search-services/logs/log4j.properties; then
				sed -i "s/^log4j\.logger\.${key}=.*/log4j.logger.${key}=${value}/" /var/lib/alfresco-search-services/logs/log4j.properties
			else
				echo "log4j.logger.${key}=${value}" >> /var/lib/alfresco-search-services/logs/log4j.properties
			fi
		elif [[ $i == LOG4J-ADDITIVITY_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			if grep --quiet "^${key}=" /var/lib/alfresco-search-services/logs/log4j.properties; then
				sed -i "s/^log4j\.additivity\.${key}=.*/log4j.additivity.${key}=${value}/" /var/lib/alfresco-search-services/logs/log4j.properties
			else
				echo "log4j.additivity.${key}=${value}" >> /var/lib/alfresco-search-services/logs/log4j.properties
			fi
		else
			# we only handle properties already defined in solr.in.sh - otherwise we'd end up adding arbitrary config not meant for SOLR
			DEF_COUNT=$(grep "${i}=" /var/lib/alfresco-search-services/solr.in.sh | wc -l)
			if [[ DEF_COUNT == 1 ]]
			then
				sed -i "s/^#?\s*${i}=.*/${i}=${value}/" /var/lib/alfresco-search-services/solr.in.sh
			elif [[ DEF_COUNT != 0 ]]
			then
				echo "${i}=\"\${${i}} ${value}\"" >> /var/lib/alfresco-search-services/solr.in.sh
			fi
		fi
    done
	sed -i "s/rootLogger=WARN, file/rootLogger=WARN, file, ${CUSTOM_APPENDER_LIST}/" /var/lib/alfresco-search-services/logs/log4j.properties

	NEW_CORE_LIST=''
	for core in "${CORE_LIST[@]}"
	do
		if [[ ! -d "/srv/alfresco-search-services/coreConfigs/${core}" || ! -f "/srv/alfresco-search-services/coreConfigs/${core}/core.properties" ]]
		then
			echo "Setting up Alfresco Search Services core ${core}"
			cp -r /srv/alfresco-search-services/solrhome/templates/rerank "/srv/alfresco-search-services/coreConfigs/${core}"
			echo "name=${core}" >> "/srv/alfresco-search-services/coreConfigs/${core}/core.properties"
			ln -s "/srv/alfresco-search-services/coreConfigs/${core}" "/srv/alfresco-search-services/solrhome/${core}"

			sed -i "s/#data\.dir\.root=.*/data.dir.root=\/srv\/alfresco-search-services\/index/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"
			sed -i "s/#data\.dir\.store=.*/data.dir.store=${core}/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"
			sed -i "s/host=.*/host=${REPOSITORY_HOST}/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"
			sed -i "s/port=.*/port=${REPOSITORY_PORT}/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"
			sed -i "s/port\.ssl=.*/port.ssl=${REPOSITORY_SSL_PORT}/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"

			if [[ $ACCESS_REPOSITORY_VIA_SSL == true ]]
			then
				sed -i "s/secureComms=.*/secureComms=https/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"
			fi

			if [[ ${core} == 'alfresco' ]]
			then
				sed -i "s/#alfresco\.stores=.*/alfresco.stores=workspace:\/\/SpacesStore/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"
			fi
			if [[ ${core} == 'archive' ]]
			then
				sed -i "s/#alfresco\.stores=.*/alfresco.stores=archive:\/\/SpacesStore/" "/srv/alfresco-search-services/solrhome/${core}/conf/solrcore.properties"
			fi

			if [[ $NEW_CORE_LIST ]]
			then
				NEW_CORE_LIST="${NEW_CORE_LIST},${core}"
			else
				NEW_CORE_LIST=${core}
			fi
		elif [[ ! -d "/srv/alfresco-search-services/solrhome/${core}" ]]
		then
			echo "Linking existing Alfresco Search Services core ${core}"
			ln -s "/srv/alfresco-search-services/coreConfigs/${core}" "/srv/alfresco-search-services/solrhome/${core}"
		fi
	done

	for i in `env`
    do
        if [[ $i == CORE_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			coreName=`echo $key | cut -d '.' -f 1`
			valueKey=`echo $key | cut -d '.' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`

			# we only apply settings for core configs we created in this run
			if [[ $NEW_CORE_LIST =~ "^([^,]+,)*${coreName}(,[^,$]+)*$" ]]
			then
				if grep --quiet "^${key}=" "/srv/alfresco-search-services/solrhome/${coreName}/conf/solrcore.properties"
				then
					sed -i "s/^${valueKey}=.*/${valueKey}=${value}/" "/srv/alfresco-search-services/solrhome/${coreName}/conf/solrcore.properties"
				else
					echo "${valueKey}=${value}" >> "/srv/alfresco-search-services/solrhome/${coreName}/conf/solrcore.properties"
				fi
			fi
		fi
		if [[ $i == SHARED_* ]]
		then
			key=`echo "$i" | cut -d '=' -f 1 | cut -d '_' -f 2-`
			value=`echo "$i" | cut -d '=' -f 2-`
			if grep --quiet "^${key}=" "/srv/alfresco-search-services/solrhome/conf/shared.properties"
			then
				sed -i "s/^${key}=.*/${key}=${value}/" "/srv/alfresco-search-services/solrhome/conf/shared.properties"
			else
				echo "${key}=${value}" >> "/srv/alfresco-search-services/solrhome/conf/shared.properties"
			fi
		fi
	done

	# all files/folders should belong to solr user to ensure proper access
	chown -R solr:solr /srv/alfresco-search-services

	touch /var/log/alfresco-search-services/.solr-logrotate-dummy
	touch /var/lib/alfresco-search-services/.assInitDone
fi