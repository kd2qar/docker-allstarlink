# docker-allstarlink
AllStarLink running in a docker container.

Current (4/2025) allstarlink working with Debian 12 (bookworm)

Up and running 

All in one container for now. Need to split out each service 
in separate containers.

Rename dot.env to .env and edit for your location

It will create a copy of the default settins for the following folders:
/etc/asterisk
/etc/allmon3
/usr/share/asl13

And packages them in a tar ball at:
/srv/srv_allstarlink.tar.gz

The compose file binds these volumes to your local system folders.

Unpack that tarball in your /srv folder (or wherever you want) and make modifications
to the config files for your setup

You may only need to run the asl-menu setup program which runs the setup in the container and changes the configurations in the bind volumes.

So far it will build and run in the container and seems to be working.
More work to be done but could be a jumpstart if you want to take it from here.

Still a WIP
Have fun and
Wear a Helmet...
