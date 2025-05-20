FROM php:8.2-apache

# Installation des bibliothèques système nécessaires
RUN apt-get update && apt-get install -y \
    git unzip zip libzip-dev libicu-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install \
        zip \
        mysqli \
        pdo_mysql \
        mbstring \
        intl \
        ctype \
        fileinfo \
        gd \
        opcache \
        bcmath \
        tokenizer \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug

# Active mod_rewrite pour Apache
RUN a2enmod rewrite

# Copie des fichiers de configuration
COPY xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY 99-dev.ini /usr/local/etc/php/conf.d/99-dev.ini
