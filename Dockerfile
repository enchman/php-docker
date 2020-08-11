FROM php:7.4.9-apache

ENV APACHE_CERTIFICATE="/etc/ssl/private/ssl-cert-snakeoil.key"
ENV APACHE_CERTIFICATE_PRIVATE="/etc/ssl/certs/ssl-cert-snakeoil.pem"
ENV APACHE_DOCUMENT_ROOT="/var/www/html"
# Make directory writable by www-data
ENV APACHE_DATA_ROOT="/var/www/data"

# Install PHP extensions and PECL modules.
RUN buildDeps=" \
        default-libmysqlclient-dev \
        libbz2-dev \
        libmemcached-dev \
        libsasl2-dev \
    " \
    runtimeDeps=" \
        curl \
        git \
        libfreetype6-dev \
        libicu-dev \
        libjpeg-dev \
        libldap2-dev \
        libmemcachedutil2 \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
    " \
    && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $buildDeps $runtimeDeps \
    && docker-php-ext-install bcmath bz2 calendar iconv intl mbstring mysqli opcache pdo_mysql pdo_pgsql pgsql soap zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-install exif \
    && docker-php-ext-install xmlrpc \
    && pecl install memcached redis \
    && docker-php-ext-enable memcached.so redis.so \
    && apt-get purge -y --auto-remove $buildDeps \
    && rm -r /var/lib/apt/lists/* \
    && a2enmod rewrite

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer
ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1

# Configure SSL
RUN a2enmod rewrite
RUN a2ensite default-ssl
RUN a2enmod ssl

# Replace Document root with Environment Variables
RUN php -r "file_put_contents('/etc/apache2/sites-available/000-default.conf', preg_replace('#DocumentRoot[\t ]+\\/var\\/www\\/html#', 'DocumentRoot \\\${APACHE_DOCUMENT_ROOT}', file_get_contents('/etc/apache2/sites-available/000-default.conf')));"
RUN php -r "file_put_contents('/etc/apache2/sites-available/default-ssl.conf', preg_replace('#DocumentRoot[\t ]+\\/var\\/www\\/html#', 'DocumentRoot \\\${APACHE_DOCUMENT_ROOT}', file_get_contents('/etc/apache2/sites-available/default-ssl.conf')));"

# Replace SSL config with Environments Variables
# Such as APACHE_CERTIFICATE and APACHE_CERTIFICATE_PRIVATE
RUN php -r "file_put_contents('/etc/apache2/sites-available/default-ssl.conf', preg_replace('#SSLCertificateFile[\t ]+[a-zA-Z0-9\\.\\/\\_\\-]+#', 'SSLCertificateFile \\\${APACHE_CERTIFICATE}', file_get_contents('/etc/apache2/sites-available/default-ssl.conf')));"
RUN php -r "file_put_contents('/etc/apache2/sites-available/default-ssl.conf', preg_replace('#SSLCertificateKeyFile[\t ]+[a-zA-Z0-9\\.\\/\\_\\-]+#', 'SSLCertificateKeyFile \\\${APACHE_CERTIFICATE_PRIVATE}', file_get_contents('/etc/apache2/sites-available/default-ssl.conf')));"

# Create directory
RUN mkdir -p $APACHE_DOCUMENT_ROOT
RUN mkdir -p $APACHE_DATA_ROOT

# Permission
RUN chown -R root:www-data $APACHE_DOCUMENT_ROOT
RUN chown -R root:www-data $APACHE_DATA_ROOT
RUN chmod -R 750 $APACHE_DOCUMENT_ROOT
RUN chmod -R 775 $APACHE_DATA_ROOT
RUN chmod -R g+s $APACHE_DOCUMENT_ROOT
RUN chmod -R g+s $APACHE_DATA_ROOT

WORKDIR ${APACHE_DOCUMENT_ROOT}

# Open HTTP port
EXPOSE 80
# Open TLS port
EXPOSE 443
