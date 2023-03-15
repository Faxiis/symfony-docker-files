# Mise en place de Symfony Docker

## Création des conteneur (ce n'est pas nécessaire)
Sans -d on ne veux plus que les conteneur soit lancé en permanence

    docker-compose up   

## Création des alias
Dans ~/.bashrc

    #symfony alias
    alias composer="docker compose run --rm -u symfony php composer"
    alias server-start="docker-compose run --rm --service-ports php symfony server:start"
    alias php="docker compose run --rm -u symfony  php php"
    alias phproot="docker compose run --rm  php php"
    alias symfony="docker compose run --rm -u symfony  php symfony"
    alias yarn="docker-compose run --rm encore yarn"


## Création du projet symfony
Il suffit de lancer le conteneur php (ici juste une demande de version) pour que si le fichier composer.json est absent pour que ça lance l'installation de symfony

    php -v


## Lancer le serveur :
    server-start


## Installation des bundles :
    composer require symfony/monolog-bundle &&
    composer require --dev symfony/profiler-pack &&
    composer require symfony/maker-bundle --dev &&
    composer require symfony/twig-bundle  &&
    composer require symfony/orm-pack  &&
    composer require symfony/mailer  &&
    composer require symfony/webpack-encore-bundle &&
    composer require symfony/asset  &&
    composer require symfony/form  &&
    composer require symfony/validator &&
    composer require --dev orm-fixtures

## Ajout de la chaine de connexion dans le .env
    DATABASE_URL=sqlsrv://sa:sql2019@host.docker.internal/CommandeSymfony

### Sql Server DATABASE_URL

Voici les chaînes de connection SQL Server :
#### Si Sql Server dans Docker
    DATABASE_URL=sqlsrv://sa:SQLServerPasw0rd@sqlserver-db/Commandes
#### Si connexion à la BDD sur l'host
    DATABASE_URL=sqlsrv://sa:sql2019@host.docker.internal/Commande

### Modification du dbal dans config/packages/doctirne.yaml

    dbal:
        url: '%env(resolve:DATABASE_URL)%'
        charset: UTF-8
        options:
            TrustServerCertificate: 1

### suppression des éléments docker pour la database postgres

Dans le fichier docker-compose.yml

    #docker:
    #    image: postgres:13
    #    environment:
    #        POSTGRES_PASSWORD: symfony
    #        POSTGRES_USER: symfony
    #        POSTGRES_DB: symfony
    #    volumes:
    #        - ./docker/postgres/data:/var/lib/postgresql/data
    #    ports:
    #        - 5432:5432

Dans le ficheir docker.compose.override.yml

    #docker:
    #    ports:
    #        - 5432:5432


## Création de la BDD
    phproot bin/console doctrine:database:create

## Création des entités
    php bin/console make:entity

## Migrations :
    php bin/console make:migration
    php bin/console d:m:m

## Création des Fixtures

## Création du Purger
Récupérer les fichiers MSSQLPurger.php  MSSQLPurgerFactory.php et les ajouter dans src/Purger

Mofifier le fichier config/services.yaml pour :

    App\Purger\MSSQLPurgerFactory:
    tags:
    - { name: 'doctrine.fixtures.purger_factory', alias: 'purger_mssql' }

## Installation des packages npm
    yarn install

### Installation de bootstrap
    yarn add bootstrap --dev
    yarn add bootstrap-icons

### Installation de popperjs
    yarn add @popperjs/core

### Installation de sass-loader
yarn add sass-loader@^13.0.0 sass --dev

### Mise en place de Bootstrap
#### ajouter dans app.js
    import './styles/bootstrap.scss';
    import './styles/app.scss';
    
    // start the Stimulus application
    import './bootstrap';
    
    // const $ = require('jquery');
    require('bootstrap');


Créer fichier bootstrap.scss avec :
    @import "bootstrap/scss/functions";
    @import "variables";
    
    
    @import "bootstrap/scss/variables";
    @import "bootstrap/scss/mixins";
    
    @import "~bootstrap/scss/bootstrap";
    @import "bootstrap-icons";

#### modifier webpack.config.js et décommenter
    .enableSassLoader()

### Compilation des assets dans public/build
    yarn encore dev
    yarn encore dev --watch

## Création d'un controller
    php bin/console make:controller



# Modifications apportées au projet dunglas 
Original : https://github.com/dunglas/symfony-docker
1. Suppression automatique de l'exécution de composer à chaque execution
2. Ajout des drivers MSSQL
3. Ajout de SQL Server
4. Ajout de "host.docker.internal:host-gateway" pour se connecter à SQL Server sur L'hôte
5. Ajout du binaire symfony-cli
