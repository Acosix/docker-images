#!/bin/sh

# Based on tomcat7 startup script from the APT tomcat7 package
# Since baseimage my_init system requires a non-forking script
# for our tomcat daemon this adapted script uses run instead
# of start, and does away with some of the flexibility of an
# init.d script

set -e

PG_DATA=${PG_DATA:-/srv/postgresql/data}
# determine installed version
PG_VERSION="$(ls -A --ignore=.* /usr/lib/postgresql)"

exec /sbin/setuser postgres "/usr/lib/postgresql/${PG_VERSION}/bin/postgres" -D "${PG_DATA}" > "/var/log/postgresql/postgresql-${PG_VERSION}-main.log" 2>&1