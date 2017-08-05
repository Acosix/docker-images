FROM acosix/baseimage-apache

LABEL vendor="Acosix GmbH" \
	  de.acosix.version="0.0.1-SNAPSHOT" \
	  de.acosix.is-beta="" \
	  de.acosix.is-production="" \
	  de.acosix.release-date="2017-08-05" \
	  de.acosix.maintainer="axel.faust@acosix.de"

EXPOSE 80 443

VOLUME ["/srv/apache2/ssl"]

COPY docker-and-portus.host.conf docker-and-portus.host.ssl.conf /tmp/

RUN	mv /tmp/docker-and-portus.host.conf /etc/apache2/sites-available/host.conf \
	&& mv /tmp/docker-and-portus.host.ssl.conf /etc/apache2/sites-available/host.ssl.conf