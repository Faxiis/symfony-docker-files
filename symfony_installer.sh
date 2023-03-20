#!/bin/bash -eH

# Define colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define versions
PHP_VERSION=8.2
NODE_VERSION=18

# Mises à jour
echo -e "${YELLOW}Mises à jour${NC}"
sudo apt update && sudo apt -y upgrade

# Ajout des paquets
echo -e "${YELLOW}Ajout des paquets${NC}"
sudo apt update
sudo apt -y install lsb-release ca-certificates apt-transport-https software-properties-common


# Ajout du dépôt PHP
echo -e "${YELLOW}Ajout du dépôt PHP${NC}"
if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    sudo add-apt-repository -y ppa:ondrej/php
    sudo apt update
fi


# Installation de PHP
echo -e "${YELLOW}Installation de PHP ${PHP_VERSION}${NC}"
if ! command -v php${PHP_VERSION} >/dev/null; then
    sudo apt -y install php${PHP_VERSION}-cli
fi

# Installation de composer
echo -e "${YELLOW}Installation de composer (https://getcomposer.org/download/) ${NC}"
if ! command -v composer >/dev/null; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    sudo mv composer.phar /usr/local/bin/composer
fi


# Installation de symfony-cli
echo -e "${YELLOW}Installation de symfony-cli ()${NC}"
if ! command -v symfony >/dev/null; then
    curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | sudo -E bash
    sudo apt install symfony-cli
fi


# Installation des extensions PHP
echo -e "${YELLOW}Installation des extensions PHP${NC}"
sudo apt -y install php${PHP_VERSION}-redis php${PHP_VERSION}-amqp php${PHP_VERSION}-pgsql php${PHP_VERSION}-mysql php${PHP_VERSION}-dev php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring php${PHP_VERSION}-xsl php${PHP_VERSION}-xdebug php${PHP_VERSION}-curl php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-intl



# Installation de nodejs et yarn
echo -e "${YELLOW}Installation de nodejs et yarn${NC}"

# Instllation de nvm
echo -e "${YELLOW}Instllation de nvm${NC}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# Install Node.js
echo -e "${YELLOW}Installing Node.js ${NODE_VERSION}${NC}"
nvm install ${NODE_VERSION}
nvm use ${NODE_VERSION}

# Installation de Yarn
echo -e "${YELLOW}Installation de Yarn${NC}"
npm install --global yarn


# Verify environment for Symfony
echo -e "${YELLOW}Verifying environment for Symfony${NC}"
symfony check:requirements

# Installation des drivers Sql Server
echo -e "${YELLOW}Installation des drivers Sql Server${NC}"
if ! [[ "18.04 20.04 22.04" == *"$(lsb_release -rs)"* ]];
then
    echo "Ubuntu $(lsb_release -rs) is not currently supported.";
    exit;
fi
# Ajout de la clé de signature pour Microsoft
sudo su -c "curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -"
# Ajout du référentiel de paquets pour les drivers SQL Server
sudo sh -c "curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | tee /etc/apt/sources.list.d/mssql-release.list >/dev/null"
# Mise à jour des informations des paquets
sudo apt-get update

# Installation des drivers SQL Server ODBC
if ! dpkg -s msodbcsql18 > /dev/null 2>&1; then
    sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
fi

# Installation des outils bcp et sqlcmd pour SQL Server
if ! dpkg -s mssql-tools18 > /dev/null 2>&1; then
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18
fi

# Ajout du répertoire bin des outils SQL Server à la variable PATH
if ! grep -q '/opt/mssql-tools18/bin' ~/.bashrc; then
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
    source ~/.bashrc
fi

# Installation des en-têtes de développement unixODBC
if ! dpkg -s unixodbc-dev > /dev/null 2>&1; then
    sudo apt-get install -y unixodbc-dev
fi

# Installation des extensions SQL Server pour PHP s'ils ne sont pas déjà installés
if ! pecl list | grep -q 'sqlsrv'; then
    sudo pecl install sqlsrv
fi

if ! pecl list | grep -q 'pdo_sqlsrv'; then
    sudo pecl install pdo_sqlsrv
fi

# Configuration des extensions SQL Server pour PHP
if [ ! -f /etc/php/{PHP_VERSION}/mods-available/sqlsrv.ini ]; then
    sudo sh -c 'echo "; priority=20\nextension=sqlsrv.so\n" > /etc/php/{PHP_VERSION}/mods-available/sqlsrv.ini'
fi

if [ ! -f /etc/php/{PHP_VERSION}/mods-available/pdo_sqlsrv.ini ]; then
    sudo sh -c 'echo "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/{PHP_VERSION}/mods-available/pdo_sqlsrv.ini'
fi




echo -e "${YELLOW}Installation des extensions PHP pour Sql Server${NC}"
sudo phpenmod -v ${PHP_VERSION} sqlsrv pdo_sqlsrv

echo -e "${GREEN}Le script est terminé !${NC}"

database_ip=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
echo -e "Adresse du serveur pour la base de données : ${RED}$database_ip${NC}"

echo -e "\n ${RED}Executer cette commande pour tester la base de données : ${NC}"

echo -e "${GREEN}isql -v -k \"DRIVER={ODBC Driver 18 for SQL Server};SERVER=$database_ip;UID=sa;PWD=sql2019;TrustServerCertificate=Yes\" ${NC}"
