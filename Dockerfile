FROM php:8.3-fpm

WORKDIR /var/www/html

RUN apt-get update \
    && apt-get install --quiet --yes --no-install-recommends \
        libzip-dev \
        unzip \
    && docker-php-ext-install zip pdo pdo_mysql \
    && pecl install -o -f redis-7.4 \
    && docker-php-ext-enable redis

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN groupadd --gid 1000 appuser \
    && useradd --uid 100 -g appuser \
        -G www-data,root --shell /bin/bash \
        --create-home appuser

USER appuser
