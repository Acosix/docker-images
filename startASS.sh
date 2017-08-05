#!/bin/sh

set -e

exec /sbin/setuser solr /var/lib/alfresco-search-services/solr/bin/solr start -f >> /var/log/alfresco-search-services/solr.out 2>&1