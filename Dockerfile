FROM acosix/baseimage-tomcat7:latest

LABEL vendor="Acosix GmbH" \
	  de.acosix.version="0.0.1-SNAPSHOT" \
	  de.acosix.is-beta="" \
	  de.acosix.is-production="" \
	  de.acosix.release-date="2017-08-27" \
	  de.acosix.maintainer="axel.faust@acosix.de"

ENV ENABLE_PROXY=false

EXPOSE 8080

RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update -q \
	&& apt-get upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	&& apt-get install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		libreoffice \
		hyphen-fr \
		hyphen-de \
		hyphen-en-us \
		hyphen-it \
		hyphen-ru \
		fonts-noto \
		fonts-dustin \
		fonts-f500 \
		fonts-fanwood \
		fonts-freefont-ttf \
		fonts-lmodern \
		fonts-lyx \
		fonts-texgyre \
		fonts-tlwg-purisa \
		wget \
	&& adduser --home=/opt/libreoffice --disabled-password --gecos "" --shell=/bin/bash libreoffice \
	&& wget -O /tmp/jod-webapp.zip 'http://sourceforge.net/projects/jodconverter/files/JODConverter/2.2.2/jodconverter-webapp-2.2.2.zip/download' \
	&& unzip /tmp/jod-webapp.zip -d /tmp/webapp \
	&& unzip /tmp/webapp/jodconverter-webapp-2.2.2/jodconverter-webapp-2.2.2.war WEB-INF/applicationContext.xml -d /tmp/webapp-contents \
	&& sed -i 's/4194304/104857600/' /tmp/webapp-contents/WEB-INF/applicationContext.xml \
	&& sed -i 's/4MB/100MiB/' /tmp/webapp-contents/WEB-INF/applicationContext.xml \
	&& cd /tmp/webapp-contents \
	&& zip -r /tmp/webapp/jodconverter-webapp-2.2.2/jodconverter-webapp-2.2.2.war . \
	&& mv /tmp/webapp/jodconverter-webapp-2.2.2/jodconverter-webapp-2.2.2.war /var/lib/tomcat7/webapps/jodconverter.war \
	&& rm -rf /tmp/webapp /tmp/webapp-contents /tmp/jod-webapp.zip \
	&& apt-get autoremove -q -y \
		libreoffice-gnome \
		wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY startLibreoffice.sh /tmp/

RUN mkdir -p /etc/service/libreoffice \
	&& mv /tmp/startLibreoffice.sh /etc/service/libreoffice/run \
	&& chmod 755 /etc/service/libreoffice/run