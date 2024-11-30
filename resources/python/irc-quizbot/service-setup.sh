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
apt-get update && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*
pip install typing
pip install twisted

# Configure git for better HTTPS handling
git config --global http.sslVerify false


########## Clone the quizbot repository if it doesn't exist ##########
if [ ! -d "/usr/src/q/.git" ]; then
    git clone --depth 1 https://github.com/oliveratgithub/q.git /usr/src/q
else
    echo "Repository exists. Pulling latest changes..."
    git -C "/usr/src/q" pull --force
fi


########## Overwrite with custom quizbot files ##########
cp -f /usr/quizbot/config.py /usr/src/q/config.py
cp -f /usr/quizbot/questions.py /usr/src/q/questions.py
cp -f /usr/quizbot/strings.py /usr/src/q/strings.py


########## Run the quizbot ##########
cd /usr/src/q
exec python q
