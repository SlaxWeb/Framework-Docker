#!/bin/bash
# check if app is bound to a subdir
DIRROOT=/var/www/html
APACHECONF=/etc/httpd/conf/httpd.conf
USER=www-user

if [ -n $APPDIR ]; then
    sed -i -e "s/\"\/var\/www\/html.*\"/\"\/var\/www\/html\/$APPDIR\"/g" $APACHECONF
    DIRROOT="$DIRROOT/$APPDIR"
else
    sed -i -e "s/\"\/var\/www\/html.*\"/\"\/var\/www\/html\"/g" $APACHECONF
fi

# Check document ownership and create user if needed. Hacky as all hell
DIRROOTUSER=`stat -c "%U" $DIRROOT`
if [ "$DIRROOTUSER" == "UNKNOWN" ]; then
    DIRROOTUSER=`stat -c "%u" $DIRROOT`
    groupadd --gid $DIRROOTUSER $USER
    adduser --uid $DIRROOTUSER --gid $DIRROOTUSER $USER
    chown -R root:www-user /var/lib/php/session/
else
    chown -R root:$DIRROOTUSER /var/lib/php/session/
    DIRROOTGROUP=`stat -c "%G" $DIRROOT`
    sed -i -e "s/User $USER/User $DIRROOTUSER/g" $APACHECONF
    sed -i -e "s/Group $USER/Group $DIRROOTGROUP/g" $APACHECONF
    USER=$DIRROOTUSER
fi

# Run URL Rewrite script
if [ -n $URLREWRITE ]; then
    su -c "bash /load-urls-tao.bash $URLREWRITE $DIRROOT/url-rewrites-tao.tsv" $USER
fi

# create self-signed cert for domain
if [ -z $NOSSL ]; then
    if [ -z $APPDOMAIN ]; then
        APPDOMAIN=$APPDIR
    fi
    if [ -n $APPDOMAIN ]; then
        openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
            -subj "/C=AT/S=Styria/L=Graz/O=ACL Advanced Commerce Labs GmbH/CN=$APPDOMAIN" \
            -keyout ca.key -out ca.crt
        cp ca.crt /etc/pki/tls/certs/ca.crt
        cp ca.key /etc/pki/tls/private/ca.key
        mv /etc/httpd/conf.d/ssl.conf.disabled /etc/httpd/conf.d/ssl.conf
    fi
else
    mv /etc/httpd/conf.d/ssl.conf /etc/httpd/conf.d/ssl.conf.disabled
fi

# Start apache in foreground to prevent container from shutting down
/usr/sbin/httpd -D FOREGROUND
