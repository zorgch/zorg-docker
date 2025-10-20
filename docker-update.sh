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


# NOTE: Don't forget to make me executable: chmod +x docker-update.sh


######## Check and Load dependencies ##########
if [ ! -f docker-compose.yml ]; then
  echo "docker-compose.yml not found"
  exit 1
fi

if [ -f .env ]; then
  source .env
fi


############### Assign Variables ##############
DOCKER_STACK="Docker"
DOCKER_STATUS_URL="the Status Dashboard"
[ -n "$COMPOSE_PROJECT_NAME" ] && DOCKER_STACK="Docker $COMPOSE_PROJECT_NAME"
[[ -n "$DASHBOARD_HOST" && -n "$DOMAINNAME" ]] && DOCKER_STATUS_URL="[Status Dashboard](https://$DASHBOARD_HOST.$DOMAINNAME)"
[ -n "$TELEGRAM_BOT_SERVICEALERTS_TOKEN" ] && BOT_TOKEN="$TELEGRAM_BOT_SERVICEALERTS_TOKEN"
[ -n "$TELEGRAM_BOT_SERVICEALERTS_CHATID" ] && CHAT_ID="$TELEGRAM_BOT_SERVICEALERTS_CHATID"
[ -n "$TELEGRAM_BOT_SERVICEALERTS_CHATTOPICID" ] && CHAT_TOPIC_ID="$TELEGRAM_BOT_SERVICEALERTS_CHATTOPICID"
MESSAGE_ANNOUNCE="ANNOUNCEMENT 🔜 Scheduled updates for *$DOCKER_STACK* in T-15!"
MESSAGE_TIMER_T5="⌛️ In 5 minutes: *$DOCKER_STACK* updating starts!"
#MESSAGE_TIMER_C10="🔟"
#MESSAGE_TIMER_C05="5️⃣"
#MESSAGE_TIMER_C04="4️⃣"
MESSAGE_TIMER_C03="3️⃣"
MESSAGE_TIMER_C02="2️⃣"
MESSAGE_TIMER_C01="1️⃣"
MESSAGE_START="⚙️ STARTING: *$DOCKER_STACK* updates..."
MESSAGE_CLEANUP="🗑️ Removing unused *__STATS__*..."
MESSAGE_UPDATE="📥 Updating *__DOCKERIMAGE__*"
MESSAGE_NOUPDATE="⏩ Skipping *__DOCKERIMAGE__* (no update)"
MESSAGE_ERRUPDATE="⚠️ Something went wrong checking *__DOCKERIMAGE__*, please investigate."
MESSAGE_RESTARTING="🔁 Restarting *${COMPOSE_PROJECT_NAME:+$COMPOSE_PROJECT_NAME-}__DOCKERSERVICE__*..."
MESSAGE_FINISH="✅ ALL DONE: *$DOCKER_STACK* is up-to-date!
> Check $DOCKER_STATUS_URL"

send_telegram_message() {
    local STATUSMESSAGE="$1"
    local STATUSMESSAGE="${STATUSMESSAGE//:/\\:}" # Escape ":"
    local STATUSMESSAGE="${STATUSMESSAGE//-/\\-}" # Escape "-"
    local STATUSMESSAGE="${STATUSMESSAGE//,/\\,}" # Escape ","
    local STATUSMESSAGE="${STATUSMESSAGE//./\\.}" # Escape "."
    local STATUSMESSAGE="${STATUSMESSAGE//!/\\!}" # Escape "!"

    # Only send if both token and chat_id are set and message is not empty
    if [[ -n "$BOT_TOKEN" && -n "$CHAT_ID" && -n "$STATUSMESSAGE" ]]; then
        curl -sS --fail -X POST -H "Content-Type:multipart/form-data" \
         -F chat_id="$CHAT_ID" \
         -F text="$STATUSMESSAGE" \
         -F message_thread_id="$CHAT_TOPIC_ID" \
         -F parse_mode=MarkdownV2 \
         "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" 2>&1 || true
    else
        # Alternatively print to stdout
        echo "$1"
    fi
}


########### Pre-flight Checks ##############
DOCKER_COMPOSE_CONFIG_CHECK=$(docker compose --profile all config 2>&1 > /dev/null)
if [ $? -ne 0 ]; then
    ERROR=" :
\`docker compose --profile all config\`
> ❌ $DOCKER_COMPOSE_CONFIG_CHECK
"
    MESSAGE="${MESSAGE_ERRUPDATE/__DOCKERIMAGE__/$ERROR}"
    send_telegram_message "$MESSAGE"
    exit 1
fi


############ Announcements ###############
send_telegram_message "$MESSAGE_ANNOUNCE"
sleep 600 # Wait now 10 minutes
send_telegram_message "$MESSAGE_TIMER_T5"
sleep 297 # Wait now 4 minutes 57 seconds
#send_telegram_message "$MESSAGE_TIMER_C10"
#sleep 5
# Countdown start
send_telegram_message "$MESSAGE_TIMER_C03"
sleep 1
send_telegram_message "$MESSAGE_TIMER_C02"
sleep 1
send_telegram_message "$MESSAGE_TIMER_C01"
sleep 1
send_telegram_message "$MESSAGE_START"


################# Cleanup unused Docker images #################
UNUSED_IMAGES=$(docker image ls -f "dangling=true" --format '{{.Repository}} {{.Size}}' |
awk '
$1!="<none>"{
  s=$2
  if(s~/GB$/){sub(/GB/,"",s); gb=s+0}
  else if(s~/MB$/){sub(/MB/,"",s); gb=(s+0)/1024}
  else if(s~/kB$/){sub(/kB/,"",s); gb=(s+0)/1024/1024}
  else if(s~/B$/){sub(/B/,"",s); gb=(s+0)/1024/1024/1024}
  sum+=gb; n[$1]=1
}
END{
  printf "%.1fGB: ",sum; sep="";
  for(i in n){printf "%s%s",sep,i; sep=", "}
}')
# Only send message and prune if there are unused images
if [[ ! "$UNUSED_IMAGES" =~ ^0\.0 ]]; then
  MESSAGE="${MESSAGE_CLEANUP/__STATS__/$UNUSED_IMAGES}"
  send_telegram_message "$MESSAGE"
  docker image prune -a -f
  docker builder prune -f
fi


########## Update all Docker images ##########
# Source: https://stackoverflow.com/a/44953583
for image in $(docker compose --profile all config | awk '/image:/ { print $2 }')
do
    # Checking image for update status
    if ! DOCKER_PULL_STATUS=$(docker pull "$image" 2>&1); then
        MESSAGE="${MESSAGE_ERRUPDATE/__DOCKERIMAGE__/$image}"
        send_telegram_message "$MESSAGE"
        continue
    fi

    # New Image available
    if echo "$DOCKER_PULL_STATUS" | grep -q "Downloaded newer image"; then
        MESSAGE="${MESSAGE_UPDATE/__DOCKERIMAGE__/$image}"
        send_telegram_message "$MESSAGE"

        # MESSAGE2="${MESSAGE_RESTARTING/__DOCKERIMAGE__/$image}"
        # send_telegram_message "$MESSAGE2"
        # docker compose up -d --build "$image" 2>&1

    # No udpate needed
    elif echo "$DOCKER_PULL_STATUS" | grep -q "Image is up to date"; then
        MESSAGE="${MESSAGE_NOUPDATE/__DOCKERIMAGE__/$image}"
        send_telegram_message "$MESSAGE"

    # Unknown update status
    else
      MESSAGE="${MESSAGE_ERRUPDATE/__DOCKERIMAGE__/$image}"
      send_telegram_message "$MESSAGE"
    fi
done


################# Restart all running Docker Services #################
for container in $(docker compose ps --services --status=running)
do
    MESSAGE="${MESSAGE_RESTARTING/__DOCKERSERVICE__/$container}"
    send_telegram_message "$MESSAGE"
    docker compose up -d --remove-orphans --build "$container" 2>&1
done


#### Remove old Docker images (that have been updated) ####
docker image prune -a -f


############# Finish ##################
send_telegram_message "$MESSAGE_FINISH"
exit 0
