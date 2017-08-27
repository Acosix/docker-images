#!/bin/bash

exec /sbin/setuser libreoffice /usr/bin/libreoffice -env:UserInstallation=file://opt/libreoffice --nologo --norestore --invisible --headless --accept='socket,host=0,port=8100,tcpNoDelay=1;urp;'