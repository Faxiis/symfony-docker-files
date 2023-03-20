#!/bin/bash -eH

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Mises à jour
echo -e "${YELLOW}Mises à jour${NC}"
sudo apt update && sudo apt -y upgrade

# Ajout des paquets
echo -e "${YELLOW}Ajout des paquets${NC}"
# Ajout des paquets
echo -e "${YELLOW}Ajout des paquets${NC}"
sudo apt update
sudo apt -y install lsb-release ca-certificates apt-transport-https software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update


# Installation de PHP 8.2
echo -e "${YELLOW}Installation de PHP 8.2${NC}"
sudo apt -y install php8.2-cli

# Installation de composer
echo -e "${YELLOW}Installation de composer (https://getcomposer.org/download/) ${NC}"

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/local/bin/composer


# Installation de symfony-cli
echo -e "${YELLOW}Installation de symfony-cli ()${NC}"
curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
sudo apt install symfony-cli


# Instllation des extensions PHP
echo -e "${YELLOW}Instllation des extensions PHP${NC}"
sudo apt install php8.2-redis php8.2-amqp php8.2-pgsql php8.2-mysql php8.2-dev php8.2-xml php8.2-mbstring php8.2-xsl php8.2-xdebug php8.2-curl php8.2-zip php8.2-gd php8.2-intl -y --allow-unauthenticated

# Installation de nodejs et yarn
echo -e "${YELLOW}Installation de nodejs et yarn${NC}"

# Instllation de nvm
echo -e "${YELLOW}Instllation de nvm${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Installation de nodejs
echo -e "${YELLOW}Installation de nodejs${NC}"
command -v nvm || echo -e "${RED}Erreur : nvm n'est pas installé.${NC}"
nvm ls-remote

echo -e "${GREEN}Entrez la version de node à installer :${NC}"
read node_version

nvm install $node_version
nvm use $node_version
# Installation de Yarn
echo -e "${YELLOW}Installation de Yarn${NC}"
npm install --global yarn

# Vérifier que notre environnement nous permet de travailler avec Symfony
echo -e "${YELLOW}Vérifier que notre environnement nous permet de travailler avec Symfony${NC}"
echo -e "${YELLOW}Vérification de l'environnement pour Symfony${NC}"
symfony check:requirements

# Installation des drivers Sql Server

echo -e "${YELLOW}Installation des drivers Sql Server${NC}"

if ! [[ "18.04 20.04 22.04" == *"$(lsb_release -rs)"* ]];
then
    echo "Ubuntu $(lsb_release -rs) is not currently supported.";
    exit;
fi

sudo su -c "curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -"

sudo sh -c "curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | tee /etc/apt/sources.list.d/mssql-release.list >/dev/null"

sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
# optional: for bcp and sqlcmd
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18
echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
source ~/.bashrc
# optional: for unixODBC development headers
sudo apt-get install -y unixodbc-dev




if ! pecl list | grep -q 'sqlsrv'; then
    sudo pecl install sqlsrv
fi

if ! pecl list | grep -q 'pdo_sqlsrv'; then
    sudo pecl install pdo_sqlsrv
fi

sudo sh -c 'echo "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.2/mods-available/sqlsrv.ini'
sudo sh -c 'echo "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.2/mods-available/pdo_sqlsrv.ini'


echo -e "${YELLOW}Installation des extensions PHP pour Sql Server${NC}"
sudo phpenmod -v 8.2 sqlsrv pdo_sqlsrv

echo -e "${GREEN}Le script est terminé !${NC}"

database_ip=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
echo "Adresse du serveur pour la base de données : $database_ip"

echo "isql -v -k \"DRIVER={ODBC Driver 18 for SQL Server};SERVER=$database_ip;UID=sa;PWD=sql2019;TrustServerCertificate=Yes\""
