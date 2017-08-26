FROM acosix/baseimage-alfresco-repository:latest

LABEL vendor="Acosix GmbH" \
	  de.acosix.version="0.0.1-SNAPSHOT" \
	  de.acosix.is-beta="" \
	  de.acosix.is-production="" \
	  de.acosix.release-date="2017-08-26" \
	  de.acosix.maintainer="axel.faust@acosix.de"
	  
# Add local transformation tooling
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update -q \
	&& apt-get upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	&& apt-get install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		ghostscript \
		imagemagick \
		libreoffice \
		wget \
	&& wget -P /tmp https://artifacts.alfresco.com/nexus/service/local/repositories/releases/content/org/alfresco/alfresco-pdf-renderer/1.0/alfresco-pdf-renderer-1.0-linux.tgz \
	&& tar xzf /tmp/alfresco-pdf-renderer-1.0-linux.tgz \
	&& mv alfresco-pdf-renderer /usr/bin/ \
	&& rm /tmp/alfresco-pdf-renderer-1.0-linux.tgz \
	&& chmod 755 /usr/bin/alfresco-pdf-renderer \
	&& apt-get autoremove -q -y \
		wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# add prepared files that would be too awkward to handle via RUN / sed
COPY shared-classes /tmp/

RUN cp -r /tmp/alfresco/* /var/lib/tomcat7/shared/classes/alfresco/ \
	&& rm -rf /tmp/alfresco