#!/bin/bash

set -x

########## Print GNU GPLv3 LICENSE notices ##########
echo '
                                                              ██████   ██████   ██████ ██   ██ ███████ ██████
  ███████  ██████  ████    ██████       ██████  ████   ██     ██   ██ ██    ██ ██      ██  ██  ██      ██   ██
     ███  ██    ██ ██  ██ ██           ██    ██ ██ ██  ██     ██   ██ ██    ██ ██      █████   █████   ██████
   ███    ██    ██ ██     ██   ███     ██    ██ ██  ██ ██     ██   ██ ██    ██ ██      ██  ██  ██      ██   ██
  ███████  ██████  ██      ██████       ██████  ██   ████     ██████   ██████   ██████ ██   ██ ███████ ██   ██
Portable, Server independent, Docker-based code to get the zorg Websites and Services up, running, and hosted.
Copyright (C) 2024-2025  zorg Verein <https://github.com/zorgch>

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


########## Create Log directories to prevent read/write errors ##########
if [ ! -d "/var/log/unrealircd" ] || [ ! -d "/var/log/anope" ]; then
    mkdir -p /var/log/unrealircd
    mkdir -p /var/log/anope
fi


########## Symlink the SSL certificates (Bug in UnrealIRCd v4.x) ##########
if [ ! -d "/home/ircd/unrealircd/conf/ssl" ]; then
    # Create SSL directory if it doesn't exist
    mkdir -p /home/ircd/unrealircd/conf/ssl

    # Link the SSL certificates
    # if [ -f "/home/ircd/unrealircd/conf/custom/ssl/curl-ca-bundle.crt" ]; then
    #   cp /home/ircd/unrealircd/conf/custom/ssl/curl-ca-bundle.crt /home/ircd/unrealircd/conf/ssl/
    # fi
    if [ -f "/home/certs/fullchain.cert" ]; then
        cp -f /home/certs/fullchain.cert /home/ircd/unrealircd/conf/ssl/server.cert.pem
        cp -f /home/certs/privkey.key /home/ircd/unrealircd/conf/ssl/server.key.pem
    fi
fi


########## Start IRCd and Anope services ##########
exec ./start_services.sh
