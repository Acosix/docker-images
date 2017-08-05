FROM acosix/baseimage-alfresco-repository:latest

LABEL vendor="Acosix GmbH" \
	  de.acosix.version="0.0.1-SNAPSHOT" \
	  de.acosix.is-beta="" \
	  de.acosix.is-production="" \
	  de.acosix.release-date="2017-06-29" \
	  de.acosix.maintainer="axel.faust@acosix.de"

ENV GLOBAL_img.root=/usr/bin \
	GLOBAL_img.exe=\${img.root}/convert \
	GLOBAL_ooo.exe=/usr/lib/libreoffice/program/soffice

# Add local transformation tooling
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update -q \
	&& apt-get upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	&& apt-get install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		ghostscript \
		imagemagick \
		libreoffice \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*