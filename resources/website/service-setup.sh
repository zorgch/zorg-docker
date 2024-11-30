#!/bin/bash

set -ex

########## Print GNU GPLv3 LICENSE notices ##########
echo '
                                                              ██████   ██████   ██████ ██   ██ ███████ ██████
  ███████  ██████  ████    ██████       ██████  ████   ██     ██   ██ ██    ██ ██      ██  ██  ██      ██   ██
     ███  ██    ██ ██  ██ ██           ██    ██ ██ ██  ██     ██   ██ ██    ██ ██      █████   █████   ██████
   ███    ██    ██ ██     ██   ███     ██    ██ ██  ██ ██     ██   ██ ██    ██ ██      ██  ██  ██      ██   ██
  ███████  ██████  ██      ██████       ██████  ██   ████     ██████   ██████   ██████ ██   ██ ███████ ██   ██
Portable, Server independent, Docker-based code to get the zorg Websites and Services up, running, and hosted.
Copyright (C) 2024  zorg Verein <https://github.com/zorgch>

  This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

  This program comes with ABSOLUTELY NO WARRANTY; for details read the README.
This is free software, and you are welcome to redistribute it
under certain conditions; see the LICENSE.'


########## Install libraries & extensions ##########
# Note: some are required due to dependencies = always installed!
apt-get update && apt-get install -y \
    cron git msmtp apache2-dev libmaxminddb0 libmaxminddb-dev libzip-dev \
    ${INSTALL_APT_GET:-} \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions: configure and install (faster)
# * required = always installed!
# Docu: https://github.com/mlocati/docker-php-extension-installer
#   @composer *  Installs Composer
#   exif         For reading image metadata
#   gd           Required for image manipulations
#   mysqli *     Required for MySQLi support
#   pdo_mysql    Required for PDO MySQL support
#   zip *        Needed for Composer
curl -sSLf \
        -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    IPE_KEEP_SYSPKG_CACHE=1 IPE_GD_WITHOUTAVIF=1 \
    install-php-extensions @composer mysqli zip ${INSTALL_PHP_EXTENSIONS:-${DEVELOPMENT_MODE:+xdebug}}

# MaxMind for apache2: install mod_maxminddb from source
cd /tmp && \
    if [ ! -d "mod_maxminddb" ]; then
        git clone --depth 1 https://github.com/maxmind/mod_maxminddb.git
    else
        cd mod_maxminddb && git pull --force
    fi && \
    cd mod_maxminddb && \
    ./bootstrap && \
    ./configure && \
    make && \
    make install && \
    echo "LoadModule maxminddb_module /usr/lib/apache2/modules/mod_maxminddb.so" > /etc/apache2/mods-available/maxminddb.load && \
    touch /etc/apache2/mods-available/maxminddb.conf
# GeoLite2-City DB: auto-download & install (https://dev.maxmind.com/geoip/updating-databases/#directly-downloading-databases)
if [ -n "${MAXMIND_LICENSE}" ] && [ ! -f "/usr/share/GeoIP/GeoLite2-City/GeoLite2-City.mmdb" ]; then
    # Create required directories
    mkdir -p /tmp/maxmind /usr/share/GeoIP/GeoLite2-City
    # Download and extract in one go
    curl -L -u "${MAXMIND_ACCOUNT}:${MAXMIND_LICENSE}" \
        'https://download.maxmind.com/geoip/databases/GeoLite2-City/download?suffix=tar.gz' \
        | tar xz -C /tmp/maxmind
    # Move just the .mmdb file to final location (using find to handle dynamic folder name)
    find /tmp/maxmind -name 'GeoLite2-City.mmdb' -exec mv {} /usr/share/GeoIP/GeoLite2-City/ \;
    # Cleanup
    rm -rf /tmp/maxmind
fi


# PHP.ini: depending on the environment, copy the correct file
if [ -n "${DEVELOPMENT_MODE}" ]; then
    cp -f /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
else
    cp -f /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
fi

# msmtp: configure
if [ -f "/tmp/msmtprc" ]; then
    cp -f /tmp/msmtprc /etc/msmtprc
    chown www-data:www-data /etc/msmtprc
    chmod 600 /etc/msmtprc

    mkdir -p /var/log/msmtp
    chown www-data:www-data /var/log/msmtp
    chmod 755 /var/log/msmtp
fi
echo "sendmail_path = /usr/bin/msmtp -t" > /usr/local/etc/php/conf.d/mail.ini

# apache2: enable modules
a2enmod headers
a2enmod rewrite
a2enmod maxminddb


########## Clone the repository if it doesn't exist ##########
git config --global http.sslVerify false
git config --global safe.directory '*'
if [ ! -d "${APACHE_PHP_ROOT:-/var/www}/html/.git" ]; then
    git clone --depth 1 -b ${GIT_BRANCH:-main} ${GIT_REPO:?Error GIT_REPO is required} /tmp/repo
    mv /tmp/repo/.git "${APACHE_PHP_ROOT:-/var/www}/html/.git"
    rm -rf /tmp/repo
    git -C "${APACHE_PHP_ROOT:-/var/www}/html" reset --hard HEAD
else
    # Repository exists. Pulling latest changes...
    git -C "${APACHE_PHP_ROOT:-/var/www}/html" pull origin ${GIT_BRANCH:-main} --force
fi


########## Install Composer if it is not already installed ##########
# Navigate to the website directory
cd "${APACHE_PHP_ROOT:-/var/www}/html"
# Install dependencies to the APACHE_PHP_ROOT/vendor directory
if [ -n "${DEVELOPMENT_MODE}" ]; then
    composer update --optimize-autoloader --prefer-dist --working-dir="${APACHE_PHP_ROOT:-/var/www}/html"
else
    composer install --no-dev --prefer-dist --optimize-autoloader --working-dir="${APACHE_PHP_ROOT:-/var/www}/html"
fi


########## Fix permissions from root -> apache (www-data:www-data) ##########
# Create cache directories if they don't exist
mkdir -p "${APACHE_PHP_ROOT:-/var/www}/caches/smarty_templates_compiled"
mkdir -p "${APACHE_PHP_ROOT:-/var/www}/caches/smarty_templates_cache"
if [ -f "/tmp/.env" ]; then
    # Copy website .env file to the right location
    cp -f /tmp/.env ${APACHE_PHP_ROOT:-/var/www}/html/.env
elif [ -f "${APACHE_PHP_ROOT:-/var/www}/html/.env.example" ]; then
    # Or instead copy an EXAMPLE .env file to the right location
    cp -f ${APACHE_PHP_ROOT:-/var/www}/html/ ${APACHE_PHP_ROOT:-/var/www}/html/.env
fi

# Set ownership & permissions for all directories and files under /var/www/*
chown -R www-data:www-data ${APACHE_PHP_ROOT:-/var/www}
find ${APACHE_PHP_ROOT:-/var/www} -type d -exec chmod 755 {} \; # (755 = drwxr-xr-x)
find ${APACHE_PHP_ROOT:-/var/www} -type f -exec chmod 644 {} \; # (644 = -rw-r--r--)


########## Start the cron service & keep service running ##########
crontab /etc/cron.d/custom
service cron start


########## Start Apache in the foreground ##########
exec apache2-foreground
