#!/bin/bash

set -e

# Limpar o diretório se não estiver vazio
if [ "$(ls -A /var/www/html/src)" ]; then
  echo "Limpando diretório existente em /var/www/html/src ..."
  rm -rf /var/www/html/src/*
fi

echo "Criando novo projeto Laravel..."

# Criar novo projeto Laravel
composer create-project laravel/laravel /var/www/html/src || {
  echo "Erro ao criar projeto Laravel"
  exit 1
}

echo "Projeto Laravel criado com sucesso."

# Esperar até que o arquivo artisan esteja disponível
while [ ! -f /var/www/html/src/artisan ]; do
  echo "Aguardando criação do projeto Laravel..."
  sleep 2
done

# Configurar a variável de ambiente APP_ENV para local
export APP_ENV=local

# Configurar a chave de aplicativo do Laravel se ainda não estiver configurada
if ! grep -q 'APP_KEY=' /var/www/html/src/.env; then
  php artisan key:generate --ansi
fi

echo "Instalando Breeze..."

# Definir variável COMPOSER para modo não interativo
export COMPOSER_NON_INTERACTIVE=1

# Instalar Breeze sem interações
cd /var/www/html/src
composer require --dev laravel/breeze || {
  echo "Erro ao instalar Laravel Breeze"
  exit 1
}

echo "Laravel Breeze instalado com sucesso."

# Substituir configurações do banco de dados no .env
sed -i "s/DB_HOST=127.0.0.1/DB_HOST=db/" /var/www/html/src/.env
sed -i "s/DB_CONNECTION=mysql/DB_CONNECTION=pgsql/" /var/www/html/src/.env
sed -i "s/DB_PORT=3306/DB_PORT=5432/" /var/www/html/src/.env
sed -i "s/DB_DATABASE=laravel/DB_DATABASE=laravel/" /var/www/html/src/.env
sed -i "s/DB_USERNAME=root/DB_USERNAME=laravel/" /var/www/html/src/.env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=secret/" /var/www/html/src/.env

# Atualizar o APP_URL para http://localhost:8000
sed -i "s/APP_URL=http:\/\/localhost/APP_URL=http:\/\/localhost:8000/" /var/www/html/src/.env

# Ajustar permissões dos diretórios storage e bootstrap/cache
echo "Ajustando permissões dos diretórios..."
chmod -R 775 /var/www/html/src/storage
chmod -R 775 /var/www/html/src/bootstrap/cache
echo "Permissões ajustadas com sucesso."

# Executar o comando breeze:install com o stack desejado
if php artisan breeze:install --ansi --quiet --dark --pest livewire; then
  echo "Laravel Breeze instalado com sucesso."
else
  echo "Erro ao executar php artisan breeze:install"
  exit 1
fi

# Esperar o banco de dados estar disponível
echo "Aguardando banco de dados estar disponível..."
while ! nc -z db 5432; do
  sleep 1
done

echo "Executando migrações..."

# Executar migrações e seeder
php artisan migrate --force || {
  echo "Erro ao executar migrações"
  exit 1
}
php artisan db:seed --force || {
  echo "Erro ao executar seeders"
  exit 1
}

# crie um arquivo para indicar que o projeto foi criado
touch /var/www/html/src/.docker-project-created

echo "Migrações e seeders executados com sucesso."
php-fpm
