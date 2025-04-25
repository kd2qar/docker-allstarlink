#!/bin/sh
which nginx
#nginx -h

chown allmon3:allmon3 /etc/allmon3 /etc/allmon3/*

HTTPD=httpd
if [ -f /bin/httpd ]; then
  HTTPD="httpd -D FOREGROUND"
fi
if [ -f /usr/sbin/nginx ]; then
  ## TEST CONFIGURATION
  /usr/sbin/nginx -t -q -g 'daemon on; master_proces on;'
fi
cd /

## ASL3 OneBoot Task
# I think this is actually pointless in a Docker container
#/usr/bin/asl3-boot-oneshot

## RUN ASTERISK IN BACKGROUND
/usr/sbin/asterisk  -g -f -p -U asterisk &

## RUN CRON
cron &

if [ 1 = 1 ]; then
  ## Run nginx in the foreground
  echo "HTTPD IN FOREGROUND"
  runuser -g allmon3 -u allmon3  allmon3 &
  if [ -f /usr/sbin/nginx ]; then
    nginx -g 'daemon off; master_process on;'
    fg
  else
    httpd -D FOREGROUND
  fi
else
  ## Run allmon3 in the foreground
  ## So far ... not able to make this work
  echo "ALLMON3 IN FOREGROUND"
  if [ -f /usr/bin/nginx ]; then
	/usr/bin/nginx -g 'daemon on; master_process on;'
  else
    $HTTPD &
  fi
  runuser -g allmon3 -u allmon3 allmon3
fi


