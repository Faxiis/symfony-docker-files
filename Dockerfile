#syntax=docker/dockerfile:1.4

# The different stages of this Dockerfile are meant to be built into separate images
# https://docs.docker.com/develop/develop-images/multistage-build/#stop-at-a-specific-build-stage
# https://docs.docker.com/compose/compose-file/#target

# Builder images
FROM composer/composer:2-bin AS composer

FROM mlocati/php-extension-installer:latest AS php_extension_installer



FROM php:8.2-fpm-alpine AS app_php
# Allow to use development versions of Symfony
ARG STABILITY="stable"
ENV STABILITY ${STABILITY}

# Allow to select Symfony version
ARG SYMFONY_VERSION=""
ENV SYMFONY_VERSION ${SYMFONY_VERSION}

ENV APP_ENV=dev

WORKDIR /srv/app

# php extensions installer: https://github.com/mlocati/docker-php-extension-installer
COPY --from=php_extension_installer --link /usr/bin/install-php-extensions /usr/local/bin/

# persistent / runtime deps
RUN apk add --no-cache \
		acl \
		fcgi \
		file \
		gettext \
		git \
    	bash \
#    	gnupg \
#    	less \
#    	libpng-dev \
#    	libzip-dev \
    	su-exec \
#    	unzip
	;

RUN set -eux; \
    install-php-extensions \
    	intl \
    	zip \
    	apcu \
		opcache \
		bcmath \
		ds \
		exif \
		pcntl \
    ;



COPY --link docker/php/conf.d/app.ini $PHP_INI_DIR/conf.d/
COPY --link docker/php/conf.d/app.dev.ini $PHP_INI_DIR/conf.d/

COPY --link docker/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
RUN mkdir -p /var/run/php

COPY --link docker/php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
RUN chmod +x /usr/local/bin/docker-healthcheck

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]

COPY --link docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
#CMD ["php-fpm"]

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="${PATH}:/root/.composer/vendor/bin"

COPY --from=composer --link /composer /usr/bin/composer

# prevent the reinstallation of vendors at every changes in the source code
COPY --link composer.* symfony.* ./

# copy sources
COPY --link  . ./
RUN rm -Rf docker/

### Sql Server Drivers

ENV ACCEPT_EULA=Y

# Install prerequisites required for tools and extensions installed later on.
COPY --link docker/sqlsrv/ /srv/app

# Install prerequisites for the sqlsrv and pdo_sqlsrv PHP extensions.
RUN apk add --allow-untrusted msodbcsql18_18.2.1.1-1_amd64.apk mssql-tools18_18.2.1.1-1_amd64.apk \
    && rm *.apk *.sig

# Retrieve the script used to install PHP extensions from the source container.
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/install-php-extensions

# Install required PHP extensions and all their prerequisites available via apt.


RUN set -eux; \
    install-php-extensions \
		pdo_sqlsrv \
		sqlsrv \
    ;

# Symfony CLI
RUN wget https://get.symfony.com/cli/installer -O - | bash && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

RUN symfony server:ca:install

EXPOSE 8000

ENV APP_ENV=dev XDEBUG_MODE=off
RUN rm -f .env.local.php

RUN addgroup -g 1000 symfony \
    && adduser -G symfony -u 1000 symfony -D



FROM node:18-alpine as encore
WORKDIR /src
ENV NODE_ENV=development
CMD ["nodemon", "bin/www"]
