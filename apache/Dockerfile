FROM php:5.6-apache

RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev libmcrypt-dev zip unzip && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd

RUN a2enmod rewrite expires

RUN docker-php-ext-install mysqli

VOLUME /var/www/html

RUN curl -o subrion.zip -SL http://tools.subrion.org/get/latest.zip \
	&& mkdir /usr/src/subrion \
	&& unzip subrion.zip -d /usr/src/subrion \
	&& rm subrion.zip \
	&& chown -R www-data:www-data /usr/src/subrion

COPY docker-entrypoint.sh /usr/local/bin

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
