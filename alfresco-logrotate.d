/var/log/tomcat7/.alfresco-logrotate-dummy {
	su tomcat7 tomcat7
	rotate 0
	daily
	ifempty
	missingok
	create 640 tomcat7 tomcat7
	lastaction
		/usr/bin/find /var/lib/tomcat7/logs/alfresco.log.*.gz -daystart -mtime +26 -delete
		/usr/bin/find /var/lib/tomcat7/logs/alfresco.log.????-??-?? -daystart -mtime +1 -exec gzip -q '{}' \;
	endscript
}