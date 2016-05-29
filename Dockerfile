FROM debian:testing
MAINTAINER Tomaz Lovrec <tomaz.lovrec@gmail.com>

# Install packages
RUN apt-get update
RUN apt-get install -y \
    php-common \
    php-pear \
    php-xml \
    php7.0-cli \
    php7.0-common \
    php7.0-dev \
    php7.0-fpm \
    php7.0-intl \
    php7.0-json \
    php7.0-mysql \
    php7.0-opcache \
    php7.0-pgsql \
    php7.0-readline \
    php7.0-xml \
    php7.0-curl \
    nginx \
    git

# Create www-user user
RUN adduser www-user

# Create directories
RUN mkdir /var/www/framework.dev

# Configure web server (nginx)
ADD vhost.conf /etc/nginx/sites-available/framework.dev.conf
RUN ln -s /etc/nginx/sites-available/framework.dev.conf /etc/nginx/sites-enabled/framework.dev.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Install swoole php extension
RUN pecl install swoole
ADD 20-swoole.ini /etc/php/7.0/fpm/conf.d/20-swoole.ini
RUN ln -s /etc/php/7.0/fpm/conf.d/20-swoole.ini /etc/php/7.0/cli/conf.d/20-swoole.ini

# Add PHP FPM Pool config
ADD fpm-pool.conf /etc/php/7.0/fpm/pool.d/www.conf
RUN mkdir /run/php/

# Install composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php -r "if (hash_file('SHA384', 'composer-setup.php') === '92102166af5abdb03f49ce52a40591073a7b859a86e8ff13338cf7db58a19f7844fbc0bb79b2773bf30791e935dbd938') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php composer-setup.php
RUN php -r "unlink('composer-setup.php');"
RUN chmod +x composer.phar && \
    mv composer.phar /usr/local/bin/ && \
    ln -s /usr/local/bin/composer.phar /usr/local/bin/composer

# Add start script
ADD start.sh /start.sh
RUN chmod +x /start.sh

# Expose ports
EXPOSE 80 9051

# Start it
ENTRYPOINT ["/start.sh"]
