## AllStar currently supports Debian 12 (bookworm)
FROM debian:bookworm-slim AS setup
#FROM httpd:bookworm
## SEE: https://allstarlink.github.io/user-guide/install/#node-configuration

WORKDIR /tmp

RUN apt-get update
## Certificates need to be refreshed to recognize the als repositories
RUN apt-get -y install sudo ca-certificates
RUN update-ca-certificates --fresh

# Install the ASL repositories
ADD https://repo.allstarlink.org/public/asl-apt-repos.deb12_all.deb /tmp/asl-apt-repos.deb12_all.deb
RUN <<-ASL
	dpkg -i asl-apt-repos.deb12_all.deb && \
	apt-get update && \
	apt-get -y install asl3 asl3-update-nodelist asl3-menu allmon3 asl3-tts \
	   asterisk-moh-opsound-gsm
	
	# This installs too much bloat
	#RUN apt-get -y install asl3-pi-appliance
	
	# Not useful in this context
	#RUN apt-get -y install cockpit cockpit-networkmanager cockpit-packagekit \
	#  cockpit-sosreport cockpit-storaged cockpit-system cockpit-ws \
	#  python3-serial # firewalld
	ASL

## Stuff needed by the asl-menu scripts
RUN apt-get -y install wget iputils-ping vim vim-common cron

RUN apt-get -y install nginx

RUN touch /run/utmp

WORKDIR /srv

## Capture original versions of config files to be mounted externally
## copy them locally from the container with 'docker cp /srv/srv_allstarlink.tar.gz .'
RUN <<-CAPTURE
	mkdir allstarlink
	cd allstarlink
	cp -r /etc/asterisk .
	cp -r /etc/almon3 .
	cp -r /var/asl-backups .
	cp -r /usr/share/asl3 .
	cd ..
	tar czvf srv_allstarlink.tar.gz allstarlink
	rm -rf allstarlink
	CAPTURE

## Clean up the debris
RUN apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false;
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/*

## Leave this commented until after you copy the files over from your first
#  run of the container. (see the compose file)
#RUN rm /srv/srv_allstarlink.tar.gz

FROM scratch
COPY --from=setup / /

WORKDIR /root/

## CONFIG FILES
## /ETC/NGINX/SITES-AVAILABLE/NGINX
COPY nginx/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY nginx/allstar /etc/nginx/sites-available/default

## /ETC/ASTERISK
#COPY asterisk/manager.conf /etc/asterisk/manager.conf

## /ETC/ALLMON3
#COPY allmon3/allmon3.ini /etc/allmon3/allmon3.ini
#COPY allmon3/menu.ini    /etc/allmon3/menu.ini
#COPY allmon3/web.ini     /etc/allmon3/web.ini

RUN <<-TOUCH_UP_MENU_FILE
	#which sed
	#grep "REALID=" /usr/bin/asl-menu
	sed -i 's/REALID=$(who am i | awk '"'"'{print $1}'"'"')/REALID=$(whoami)/g' /usr/bin/asl-menu
	#sed -i "s/(who am i |/(whoami |/g" /usr/bin/asl-menu
	sed -i "s/logfile=\/dev\/null/logfile=\/tmp\/asl-menu.log/g" /usr/bin/asl-menu
	#grep "REALID=" /usr/bin/asl-menu
	TOUCH_UP_MENU_FILE
 
MAINTAINER Mark Vincett kd2qar@gmail.com
LABEL org.opencontainers.image.authors="Mark Vincett kd2qar@gmail.com"
 
COPY <<-BASHRC /root/.bashrc
	alias ls='ls --color'
	alias ll='ls -Alh'
	if [ ! -f /usr/bin/locate ]; then
	  #apt-get -qq update;
	  #apt-get -qq -y install aptitude locate
	  #updatedb &
	  (apt-get -qq update >/dev/null 2>&1 && apt-get -qq -y install aptitude locate >/dev/null 2>&1 && updatedb) &
	else
	  updatedb &
	fi
	BASHRC

ADD --chmod=0644 allstarlink.crontab /etc/cron.d/allstarlink
RUN touch /var/log/cron.log
RUN rm -f /etc/cron.daily/apt-compat && rm -f /etc/cron.daily/dpkg && rm -f /etc/cron.d/e2scrub_all
ADD --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
