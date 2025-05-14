FROM php:8.2-apache

RUN apt-get update && apt-get install -y \ 
    git unzip zip libzip-dev &&     docker-php-ext-install zip &&     pecl install xdebug &&     docker-php-ext-enable xdebug

RUN a2enmod rewrite

COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini
