FROM phusion/baseimage:0.9.22

LABEL vendor="Acosix GmbH" \
	  de.acosix.version="0.0.1-SNAPSHOT" \
	  de.acosix.is-beta="" \
	  de.acosix.is-production="" \
	  de.acosix.release-date="2017-08-04" \
	  de.acosix.maintainer="axel.faust@acosix.de"

EXPOSE 80 443

# we expect file mounts for /etc/apache2/sites-available/host.conf and /etc/apache2/sites-available/host.ssl.conf 
VOLUME ["/srv/apache2/ssl"]

RUN export DEBIAN_FRONTEND=noninteractive \
	&& add-apt-repository -y ppa:certbot/ubuntu/certbot \
	&& apt-get update -q \
	&& apt-get upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	&& apt-get install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		apache2 \
		certbot \
		python-certbot-apache \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096

# add prepared files that would be too awkward to handle via RUN / sed
COPY initApache.sh startApache.sh /tmp/

RUN	sed -i 's/SSLCipherSuite HIGH:!aNULL/SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:ECDHE-RSA-AES128-SHA:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4/' /etc/apache2/mods-available/ssl.conf \
	&& sed -i 's/#SSLHonorCipherOrder on/SSLHonorCipherOrder on/' /etc/apache2/mods-available/ssl.conf \
	&& sed -i 's/SSLProtocol all -SSLv3/SSLProtocol all -SSLv3 -TLSv1/' /etc/apache2/mods-available/ssl.conf \
	&& sed -i '/<\/IfModule>/i 	SSLUseStapling On' /etc/apache2/mods-available/ssl.conf \
	&& sed -i '/<\/IfModule>/i 	SSLStaplingCache "shmcb:${APACHE_RUN_DIR}/ssl_stapling(32768)"' /etc/apache2/mods-available/ssl.conf \
	&& sed -i '/<\/IfModule>/i 	SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"' /etc/apache2/mods-available/ssl.conf \
	&& mkdir -p /etc/my_init.d \
	&& mv /tmp/initApache.sh /etc/my_init.d/20_initApache.sh \
	&& chmod +x /etc/my_init.d/20_initApache.sh \
	&& mkdir /etc/service/apache2 \
	&& mv /tmp/startApache.sh /etc/service/apache2/run \
	&& chmod +x /etc/service/apache2/run

RUN a2enmod \
		proxy \
		proxy_http \
		proxy_html \
		xml2enc \
		expires \
		cache \
		cache_disk \
		rewrite \
		deflate \
		headers \
	&& a2disconf \
		serve-cgi-bin \
		other-vhosts-access-log \
	&& a2dissite \
		000-default
