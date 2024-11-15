# Composer Dependencies
FROM composer AS composer-build

WORKDIR /var/www/html

COPY composer.json composer.lock /var/www/html/

RUN mkdir /var/www/html/database{factories,seeds} \
    && composer install --no-dev --no-scripts --no-autoloader --no-progress --ignore-platform-reqs


# NPM Dependencies
FROM node:22 AS npm-build

WORKDIR /var/www/html

COPY package.json package-lock.json vite.config.js /var/www/html/
COPY resources /var/www/html/resources/
COPY public /var/www/html/public/

RUN npm ci
RUN npm run build


# Production Image
FROM php:8.3-fpm

WORKDIR /var/www/html

RUN apt-get update \
    && apt-get install --quiet --yes --no-install-recommends \
        libzip-dev \
        unzip \
    && docker-php-ext-install opcache zip pdo pdo_mysql \
    && pecl install -o -f redis-7.4 \
    && docker-php-ext-enable redis

RUN mv $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
COPY .docker/php/opcache.ini $PHP_INI_DIR/conf.d/

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY --chown=www-data --from=composer-build /var/www/html/vendor /var/www/html/vendor
COPY --chown=www-data --from=npm-build /var/www/html/public /var/www/html/public
COPY --chown=www-data . /var/www/html

RUN composer dump -o \
    && composer check-platform-reqs \
    && rm -f /usr/bin/composer
