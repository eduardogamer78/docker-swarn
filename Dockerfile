ARG PHP_VERSION
FROM php:${PHP_VERSION}

## Diretório da aplicação
ARG APP_DIR=/var/www/app
ARG EXTERNAL_APP_DIR=./../../

## Versão da Lib do Redis para PHP
ARG REDIS_LIB_VERSION=5.3.7

### apt-utils é um extensão de recursos do gerenciador de pacotes APT
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    apt-utils \ 
    supervisor

# dependências recomendadas de desenvolvido para ambiente linux
RUN apt-get update && apt-get install -y \ 
    zlib1g-dev \
    libzip-dev \
    zip \
    unzip \
    libpng-dev \
    libpq-dev \
    libxml2-dev \
    curl \
    libhiredis-dev

RUN docker-php-ext-install mysqli pdo pdo_mysql pdo_pgsql pgsql session xml

# habilita instalação do Redismysql-client
RUN pecl install redis-${REDIS_LIB_VERSION} \
    && docker-php-ext-enable redis 

RUN docker-php-ext-install iconv simplexml pcntl gd

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

### Arquivos de configuração
COPY --chown=www-data:www-data ./docker/supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY --chown=www-data:www-data ./docker/php/extra-php.ini "$PHP_INI_DIR/conf.d/99_extra.ini"

WORKDIR $APP_DIR
COPY --chown=www-data:www-data . .
RUN cd $APP_DIR

### Limpeza e otimização da construção
RUN rm -rf /var/lib/apt/lists/* docker Dockerfile .env \
    && apt-get autoremove -y \
    && apt-get clean

RUN apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt update -y && apt install nano git -y

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]