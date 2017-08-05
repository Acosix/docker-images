/var/log/tomcat7/catalina.out {
	su tomcat7 tomcat7
	copytruncate
	daily
	rotate 28
	dateext
	compress
	missingok
	create 640 tomcat7 tomcat7
}

/var/log/tomcat7/.access-logrotate-dummy {
	su tomcat7 tomcat7
	rotate 0
	daily
	ifempty
	missingok
	create 640 tomcat7 tomcat7
	lastaction
		/usr/bin/find /var/lib/tomcat7/logs/localhost_access_log.*.txt.gz -daystart -mtime +26 -delete
		/usr/bin/find /var/lib/tomcat7/logs/localhost_access_log.????-??-??.txt -daystart -mtime +1 -exec gzip -q '{}' \;
	endscript
}