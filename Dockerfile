FROM php:8.1-fpm

# Instalações necessárias
RUN apt-get update && apt-get install -y \
    libpq-dev \
    git \
    unzip \
    nodejs \
    npm \
    netcat-openbsd \
    supervisor \
    && docker-php-ext-install pdo_pgsql

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Diretório de trabalho
WORKDIR /var/www/html/src

# Copiar o script de inicialização
COPY ./src/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Copiar a configuração do supervisord
COPY ./src/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Permissão para o script de inicialização
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expor a porta 8000 se necessário
EXPOSE 8000

# Script de inicialização
ENTRYPOINT ["docker-entrypoint.sh"]
