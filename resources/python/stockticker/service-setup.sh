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
pip install requests
pip install schedule
pip install yfinance


########## Parse and run each Stock Ticker ##########
# Create an array to store PIDs
pids=()

IFS=';' read -ra TICKERS <<< "$STOCK_TICKERS"
for stock in "${TICKERS[@]}"; do
    IFS=':' read -ra STOCK <<< "$stock"
    SYMBOL=${STOCK[0]}
    THRESHOLD=${STOCK[1]:-10}  # Default if not specified: 10 US-Dollar
    INTERVAL=${STOCK[2]:-60}  # Default if not specified: every minute

    python -u stock_notifications.py "$SYMBOL" "$TELEGRAM_TOKEN" "$TELEGRAM_CHAT" "$THRESHOLD" "$INTERVAL" &
    pids+=($!)
done

# Handle signals properly
trap "kill ${pids[*]}" SIGTERM SIGINT


########## Keep service running ##########
wait ${pids[@]}
