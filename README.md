# Symfony Docker

## Installation
`docker-compose up -d --build`

### Check Requirements
`docker compose run --rm php symfony check:requirements` # Check requirements
### Le projet est automatiquement créé s'il n'y a pas de composer.json 
`docker compose run --rm php composer --help`

`sudo chown -R test:test .` # Change owner of the project directory

Visiter : https://localhost

## bundles à installer : 
- `docker compose run --rm php composer require --dev symfony/profiler-pack` # Pour le front
- `docker compose run --rm php composer require symfony/maker-bundle --dev`   # Création de code
- `docker compose run --rm php composer require symfony/twig-bundle`  # Twig
- `docker compose run --rm php composer require symfony/orm-pack`  # Doctrine
- `docker compose run --rm php composer require symfony/mailer`  # Mailer
- `docker compose run --rm php composer require symfony/security-bundle`  # Security
- `docker compose run --rm php composer require symfony/webpack-encore-bundle`  # Webpack
- `docker compose run --rm php composer require symfony/asset`  # Asset
- `docker compose run --rm php composer require symfony/validator`  # Validator
- `docker compose run --rm php composer require symfony/serializer-pack`  # Serializer
- `docker compose run --rm php composer require symfony/translation`  # Translation
- `docker compose run --rm php composer require symfony/monolog-bundle`  # Monolog
- `docker compose run --rm php composer require symfony/lock`  # Lock
- `docker compose run --rm php composer require symfony/messenger`  # Messenger
- `docker compose run --rm php composer require symfony/mercure-bundle`  # Mercure


## Makers
`docker compose run --rm php bin/console make:controller` # Création d'un controller


# Modifications apportées au projet dunglas 
Original : https://github.com/dunglas/symfony-docker
1. Suppression automatique de l'exécution de composer à chaque execution
2. Ajout des drivers MSSQL
3. Ajout de SQL Server
4. Ajout de "host.docker.internal:host-gateway" pour se connecter à SQL Server sur L'hôte
5. Ajout du binaire symfony-cli

### Sql Server DATABASE_URL

Voici les chaînes de connection SQL Server :
#Si Sql Server dans Docker
#DATABASE_URL=sqlsrv://sa:SQLServerPasw0rd@sqlserver-db/Commandes
#Si connexion à la BDD sur l'host
#DATABASE_URL=sqlsrv://sa:sql2019@host.docker.internal/Commande
