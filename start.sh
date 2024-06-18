#!/bin/bash

set -e

# Limpar o diretório se não estiver vazio

if [ "$(ls -A ./src)" ]; then
    echo "Limpando diretório existente em ./src ..."
    sudo rm -rf ./src/*
    rm -f ./src/.env
    rm -f ./src/.env.example
    rm -f ./src/.editorconfig
    rm -f ./src/.gitattributes
    rm -f ./src/.gitignore
    rm -f ./src/.docker-project-created
fi

echo "adicionando o supervisord e docker-entrypoint"

cp docker-entrypoint.sh ./src
cp supervisord.conf ./src

sudo docker-compose down && sudo docker-compose up --build -d

# Função para esperar até que o arquivo indicando a criação do projeto seja criado
wait_for_project_creation() {
    local momento
    while [ ! -f ./src/.docker-project-created ]; do
        momento=$(date +'%d/%m/%Y %H:%M:%S')
        echo "$momento Aguardando criação do projeto Laravel..."
        sleep 2
    done

    rm -f ./src/.docker-project-created

    sleep 4
    sudo chmod 777 -R ./src/storage
    sudo chown dev:dev ./src -R
}


# Chamar a função para esperar até que o projeto Laravel seja criado
wait_for_project_creation