#!/bin/sh
# Installed by Ansible (roles/letsencrypt) into
# /etc/letsencrypt/renewal-hooks/deploy/. certbot runs it after each
# successful renewal, as root. nginx only reads certificates at startup and on
# reload, so without this a renewed certificate is not served until something
# else happens to reload nginx.
#
# Test the config first: if it is broken, leave the running nginx alone (it
# keeps serving the old certificate) and fail, so certbot reports the error.
set -eu

/usr/sbin/nginx -t -q -c /home/nginx/conf/nginx.conf
systemctl reload nginx
