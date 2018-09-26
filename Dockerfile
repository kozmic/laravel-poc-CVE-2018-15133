FROM php:7.2.10-stretch
MAINTAINER Stale Pettersen <staale@gmail.com>

RUN apt-get update
RUN apt-get install -y autoconf pkg-config libssl-dev wget \
  curl \
  git \
  grep \
  nginx \
  libmemcached-dev \
  libxml2-dev \
  autoconf \
  vim

RUN docker-php-ext-install mysqli mbstring pdo pdo_mysql tokenizer xml

# Install Laravel dependencies
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        zlib1g-dev

RUN docker-php-ext-install iconv mbstring \
    && docker-php-ext-install zip \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd

WORKDIR /var/www/html
COPY composer.phar /var/www/html

# Installs vulnerable version of laravel 5.6.29 (5.6.30 is patched):
RUN git clone https://github.com/laravel/laravel.git && cd laravel && sed -i -e 's/5.7.\*/5.6.29/g' composer.json && php ../composer.phar install

# Setup laravel
RUN cp laravel/.env.example laravel/.env && php laravel/artisan key:generate

# Add a POST route so we can trigger the vulnerability:
RUN echo "Route::post('/', function() {return view('welcome');});" >> /var/www/html/laravel/routes/web.php

# Start webserver dev server (could be nginx, apache etc):
ENTRYPOINT ["/usr/local/bin/php", "/var/www/html/laravel/artisan", "serve", "--host=0.0.0.0"]
