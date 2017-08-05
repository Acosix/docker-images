FROM phusion/baseimage:0.9.22

LABEL vendor="Acosix GmbH" \
	  de.acosix.version="0.0.1-SNAPSHOT" \
	  de.acosix.is-beta="" \
	  de.acosix.is-production="" \
	  de.acosix.release-date="2017-06-03" \
	  de.acosix.maintainer="axel.faust@acosix.de"

EXPOSE 5432

RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update -q \
	&& apt-get upgrade -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
	&& apt-get install -q -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
		postgresql \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/postgresql

COPY initPostgreSQL.sh startPostgreSQL.sh postgresql-logrotate.d /tmp/
	  
RUN mv /tmp/postgresql-logrotate.d /etc/logrotate.d/postgresql \
	&& mkdir -p /etc/my_init.d \
	&& mv /tmp/initPostgreSQL.sh /etc/my_init.d/20_initPostgreSQL.sh \
	&& chmod +x /etc/my_init.d/20_initPostgreSQL.sh \
	&& mkdir /etc/service/postgresql \
	&& mv /tmp/startPostgreSQL.sh /etc/service/postgresql/run \
	&& chmod +x /etc/service/postgresql/run
	
VOLUME ["/srv/postgresql"]