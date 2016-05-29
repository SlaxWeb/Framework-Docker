#!/bin/bash
DIRROOT=/var/www/framework.dev
FPMCONF=/etc/php/7.0/fpm/pool.d/www.conf
USER=www-user

service php7.0-fpm start
service nginx start
