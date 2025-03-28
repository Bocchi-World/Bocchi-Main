#!/bin/bash

CONFIG_KEY="BUY-KEY-ROKID"
CONFIG_SERVER_VIP="CHILL"
CONFIG_WEBHOOK_LINK="CHILL"
CONFIG_WEBHOOK_NAME="CHILL"
CONFIG_WEBHOOK_MINUTE="CHILL"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --key)
            CONFIG_KEY="$2"
            shift 2
            ;;
        --server)
            CONFIG_SERVER_VIP="$2"
            shift 2
            ;;
        --webhook_link)
            CONFIG_WEBHOOK_LINK="$2"
            shift 2
            ;;
        --webhook_name)
            CONFIG_WEBHOOK_NAME="$2"
            shift 2
            ;;
        --webhook_minute)
            CONFIG_WEBHOOK_MINUTE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

set_config() {
  echo "[BOCCHI WORLD] Kaitun Rokid - Config!"
  
  read -p "Server VIP (current: $CONFIG_SERVER_VIP): " input_server
  [ -n "$input_server" ] && CONFIG_SERVER_VIP="$input_server"
  
  read -p "Webhook Discord (current: $CONFIG_WEBHOOK_LINK): " input_webhook_link
  [ -n "$input_webhook_link" ] && CONFIG_WEBHOOK_LINK="$input_webhook_link"
  
  read -p "Webhook Name (current: $CONFIG_WEBHOOK_NAME): " input_webhook_name
  [ -n "$input_webhook_name" ] && CONFIG_WEBHOOK_NAME="$input_webhook_name"
  
  read -p "Webhook Minute (current: $CONFIG_WEBHOOK_MINUTE): " input_webhook_minute
  [ -n "$input_webhook_minute" ] && CONFIG_WEBHOOK_MINUTE="$input_webhook_minute"
  
  read -p "Key Rokid (current: $CONFIG_KEY): " input_key
  [ -n "$input_key" ] && CONFIG_KEY="$input_key"

  echo "✅ Successfully updated config!"
}

termux-change-repo <<< "OK" <<< "OK"
pkg update -y && pkg upgrade -y
echo "y" | termux-setup-storage
pkg install -y python tsu libexpat openssl git
pip install requests pytz pyjwt pycryptodome rich colorama flask psutil

curl -o /sdcard/Download/campuchia.py "https://raw.githubusercontent.com/username/repo/main/campuchia.py"

su -c "cd /sdcard/Download && export PATH=\$PATH:/data/data/com.termux/files/usr/bin && python ./campuchia.py" <<EOF
$CONFIG_KEY
4
14
$CONFIG_SERVER_VIP
6
$CONFIG_WEBHOOK_LINK
$CONFIG_WEBHOOK_NAME
$CONFIG_WEBHOOK_MINUTE
11
1
1
300
EOF

echo "[BOCCHI WORLD] Kaitun Rokid - Done!"