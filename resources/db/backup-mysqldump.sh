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


# NOTE: Don't forget to make me executable: chmod +x backup-mysqldump.sh


######## Check and Load dependencies ##########
if [ $# -lt 1 ]; then
    echo "Usage: $0 <backup-directory> [path-to-env-file]"
    exit 1
fi

BACKUP_DIR="$1"
# Remove trailing slash if present
BACKUP_DIR="${BACKUP_DIR%/}"
ENV_FILE="$2"

if [ ! -d "$BACKUP_DIR" ]; then
    mkdir -p "$BACKUP_DIR"
fi

# If ENV_FILE not provided, try ./.env
if [ -z "$ENV_FILE" ]; then
    if [ -f "./.env" ]; then
        ENV_FILE="./.env"
    else
        echo "Error: No .env file provided and ./.env not found"
        exit 1
    fi
elif [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi


############### Assign Variables ##############
source "$ENV_FILE"
DOCKER_STACK="Docker"
[ -n "$COMPOSE_PROJECT_NAME" ] && DOCKER_STACK="$COMPOSE_PROJECT_NAME Docker"
[ -n "$TELEGRAM_BOT_SERVICEALERTS_TOKEN" ] && BOT_TOKEN="$TELEGRAM_BOT_SERVICEALERTS_TOKEN"
[ -n "$TELEGRAM_BOT_SERVICEALERTS_CHATID" ] && CHAT_ID="$TELEGRAM_BOT_SERVICEALERTS_CHATID"
[ -n "$TELEGRAM_BOT_SERVICEALERTS_CHATTOPICID" ] && CHAT_TOPIC_ID="$TELEGRAM_BOT_SERVICEALERTS_CHATTOPICID"

# Database variables from .env
DB_NAME=""
if [ -z "$DATABASE_NAME" ]; then
    echo "Error: Database name not found in .env file"
    exit 1
else
    DB_NAME="$DATABASE_NAME"
fi
[ -n "$DATABASE_USER" ] && DB_USER="$DATABASE_USER"
[ -n "$DATABASE_PASSWORD" ] && DB_PASS="$DATABASE_PASSWORD"
[[ -n "$MARIADB_ROOT_PASSWORD" && "$MARIADB_DISABLE_ROOT_PASSWORD" = 'yes' ]] && DB_USER="root"
[[ "$DB_USER" = 'root' && -n "$MARIADB_ROOT_PASSWORD" ]] && DB_PASS="${MARIADB_ROOT_PASSWORD}"
[[ "$DB_USER" = 'root' && "$MARIADB_DISABLE_ROOT_PASSWORD" = 'yes' ]] && DB_PASS=

# Container name based on project
CONTAINER="$COMPOSE_PROJECT_NAME-mariadb"

# Backup file name with date and database name
DATE=$(date +%F-%H_%M_%S)
OUTFILE="${BACKUP_DIR}/backup-${DB_NAME}-${DATE}.sql"

# Messages
MESSAGE_START="⚙️ STARTING: *$CONTAINER* backup of DB \`$DB_NAME\`…"
MESSAGE_BACKUP="☑️ *SUCCESSFULLY* mariadb-dump'ed *$DB_NAME* to\n> \`$OUTFILE\`"
MESSAGE_ERRBACKUP="⚠️ *FAILED* to backup $DB_NAME, please investigate: "
MESSAGE_FINISH="✅ ALL DONE: *$CONTAINER* DB backup finished!"

send_telegram_message() {
    # [_*[\]()~`>#+\-=|{}.!]/\\&
    local STATUSMESSAGE="$1"
    # Obfuscate critical information
    STATUSMESSAGE="${STATUSMESSAGE//$DB_PASS/********}"
    # Escape special characters
    STATUSMESSAGE="${STATUSMESSAGE//\"/\\\"}" # Escape literal "
    STATUSMESSAGE="${STATUSMESSAGE//\'/\\\'}" # Escape literal '
    STATUSMESSAGE="${STATUSMESSAGE//-/\\\-}" # Escape "-" (Character is reserved)
    STATUSMESSAGE="${STATUSMESSAGE//_/\\\_}" # Escape "_" (Character is reserved)
    STATUSMESSAGE="${STATUSMESSAGE//./\\\.}" # Escape "." (Character is reserved)
    STATUSMESSAGE="${STATUSMESSAGE//+/\\\+}" # Escape "+" (Character is reserved)
    STATUSMESSAGE="${STATUSMESSAGE//=/\\\=}" # Escape "=" (Character is reserved)
    STATUSMESSAGE="${STATUSMESSAGE//(/\\\(}" # Escape "(" (Character is reserved)
    STATUSMESSAGE="${STATUSMESSAGE//)/\\\)}" # Escape ")" (Character is reserved)

    # Only send if both token and chat_id are set and message is not empty
    if [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" && -n "$STATUSMESSAGE" ]]; then
        local THREAD_PART=""
        if [[ -n "$CHAT_TOPIC_ID" ]]; then
            THREAD_PART=" \"message_thread_id\": \"$CHAT_TOPIC_ID\","
        fi
        curl -sS --fail -X POST \
          -H "Content-Type: application/json" \
          -d "{\"parse_mode\": \"MarkdownV2\", \"chat_id\": \"$CHAT_ID\",$THREAD_PART \"text\": \"${STATUSMESSAGE}\"}" \
          "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" 2>&1 || true
    fi
}


########## Start the backup ##########
send_telegram_message "$MESSAGE_START"
sleep 15 # Wait 15 seconds to let the message be sent

set +x
MYSQLDUMP_PW_PARAM="${DB_PASS:+--password=$DB_PASS}"
if ! DOCKER_ERROR=$( { docker exec -i "$CONTAINER" mariadb-dump \
  --user="$DB_USER" "$MYSQLDUMP_PW_PARAM" \
  --no-tablespaces \
  --databases "$DB_NAME" > "$OUTFILE"; } 2>&1 ); then
        # Failed - use captured error
        MESSAGE_ERROR="${MESSAGE_ERRBACKUP}
> ${DOCKER_ERROR}"
        send_telegram_message "$MESSAGE_ERROR"
        exit 1
else
    # Successful
    send_telegram_message "$MESSAGE_BACKUP"
fi
set -x


#### Remove old backups (>1 year) ####
find "$BACKUP_DIR" -type f -mtime +365 -name "*.sql" -exec rm -f {} \;


############# Finalising #############
send_telegram_message "$MESSAGE_FINISH"
exit 0
