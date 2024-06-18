# -*- coding: utf-8 -*-

# Limpar o diretório se não estiver vazio
if (Test-Path ./src/*) {
    Write-Output "Limpando diretório existente em ./src ..."
    Remove-Item -Path ./src/* -Recurse -Force
}

Write-Output "adicionando o docker-entrypoint"

Copy-Item -Path .\docker-entrypoint.sh -Destination .\src

docker-compose down
docker-compose up --build -d

# Função para esperar até que o arquivo indicando a criação do projeto seja criado
function Wait-ForProjectCreation {
    while (!(Test-Path ./src/.docker-project-created)) {
        $momento = Get-Date -Format 'dd/MM/yyyy HH:mm:ss'
        Write-Output "$momento Aguardando criação do projeto Laravel..."
        Start-Sleep -Seconds 2
    }

    Remove-Item -Path ./src/.docker-project-created -Force

    Start-Sleep -Seconds 4
    # Ajustes de permissões, se necessário
    docker exec -it laravel_webserver powershell -Command "chown www-data:www-data storage/ -R"
}

# Chamar a função para esperar até que o projeto Laravel seja criado
Wait-ForProjectCreation
