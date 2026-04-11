FROM php:8.2-apache

# Extensions système requises
RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip zip \
        libzip-dev libicu-dev libpng-dev libonig-dev libxml2-dev \
    && docker-php-ext-install \
        zip mysqli pdo_mysql mbstring intl ctype fileinfo gd opcache bcmath \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && rm -rf /var/lib/apt/lists/*

# mod_rewrite pour les URLs propres
RUN a2enmod rewrite

# Les fichiers de configuration (xdebug.ini, 99-dev.ini) sont injectés
# via des volumes depuis le dossier php/ du projet — voir docker-compose.yml
