FROM ubuntu:20.04

LABEL maintainer="Rafael Meira <rafaelmeira@me.com>"

ENV DEBIAN_FRONTEND=noninteractive

# UPDATE AND INSTALL INITIAL PACKAGES
RUN apt-get update && \
    apt-get install software-properties-common -y && \
    add-apt-repository ppa:ondrej/php -y && apt-get update

# INSTALL PACKAGES
RUN apt-get install -y \
    nginx \
    curl \
    git \
    wget \
    vim \
    cron \
    unzip \
    zip \
    libssl-dev \
    supervisor \
    php7.4-cli \
    php7.4-fpm \
    php7.4-bcmath \
    php7.4-bz2 \
    php7.4-common \
    php7.4-curl \
    php7.4-dba \
    php7.4-dev \
    php7.4-enchant \
    php7.4-gd \
    php7.4-gmp \
    php7.4-imap \
    php7.4-intl \
    php7.4-json \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-mysql \
    php7.4-odbc \
    php7.4-opcache \
    php7.4-pgsql \
    php7.4-soap \
    php7.4-xml \
    php7.4-xmlrpc \
    php7.4-xsl \
    php7.4-zip \
    php7.4-redis

# INSTALL COMPOSER
RUN curl -s https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# INSTALL MSSQL
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list >/etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 && ACCEPT_EULA=Y apt-get install -y mssql-tools && \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >>~/.bash_profile && \
    echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >>~/.bashrc && \
    apt-get install unixodbc-dev && apt-get -y install php-pear php7.4-dev && \
    pecl install sqlsrv && pecl install pdo_sqlsrv && \
    echo "extension=sqlsrv.so" >/etc/php/7.4/mods-available/sqlsrv.ini && \
    echo "extension=pdo_sqlsrv.so" >/etc/php/7.4/mods-available/pdo_sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/sqlsrv.ini /etc/php/7.4/cli/conf.d/20-sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/pdo_sqlsrv.ini /etc/php/7.4/cli/conf.d/20-pdo_sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/sqlsrv.ini /etc/php/7.4/fpm/conf.d/20-sqlsrv.ini && \
    ln -s /etc/php/7.4/mods-available/pdo_sqlsrv.ini /etc/php/7.4/fpm/conf.d/20-pdo_sqlsrv.ini

# COPY NGINX CONFIG
COPY nginx/mime.types /etc/nginx/mime.types
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# COPY PHP CONFIGS
COPY php/php.ini /etc/php/7.4/fpm/php.ini
COPY php/php-fpm.conf /etc/php/7.4/fpm/php-fpm.conf
COPY php/www.conf /etc/php/7.4/fpm/pool.d/www.conf
RUN mkdir /var/run/php && mkdir /var/log/php

# COPY CRONTAB CONFIGS
COPY crontabs/crontab /etc/crontab

# COPY SUPERVISOR CONFIG
COPY supervisor/supervisord.conf /etc/supervisord.conf

# CLEAN DIRECTORY AND AJUST PERMISSIONS
RUN rm -Rf /var/www/* && chmod -R 755 /var/www

# DEFINE WORKDIR
WORKDIR /var/www

# FINAL CLEAN UP 
RUN apt-get upgrade -y && apt-get autoremove -y && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

# EXPOSE PORTS
EXPOSE 80

# COPY SHELLSCRIPT
COPY scripts/init.sh /scripts/init.sh
RUN chmod +x /scripts/init.sh

# FINAL POINT
ENTRYPOINT ["/scripts/init.sh"]