#!/usr/bin/env bash

# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gristlabs/grist-core

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  make \
  gnupg \
  ca-certificates \
  mc
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Installed Node.js"

msg_info "Installing yarn"
$STD npm install -g yarn
msg_ok "Installed yarn $(yarn --version)"

msg_info "Installing Grist"
RELEASE=$(curl -s https://github.com/gristlabs/grist-core/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
cd /opt
wget -q https://github.com/gristlabs/grist-core/archive/refs/tags/v${RELEASE}.zip
unzip -q v$RELEASE.zip -d grist
cd grist
$STD yarn install
$STD yarn run build:prod
$STD yarn run install:python
echo "${RELEASE}" >/opt/${APPLICATION}_version.txt

cat <<EOF >/opt/grist/.env
NODE_ENV=production
EOF

msg_ok "Installed Grist"

cat <<EOF >/etc/systemd/system/grist.service
[Unit]
Description=Grist
After=network.target

[Service]
Type=exec
WorkingDirectory=/opt/grist 
ExecStart=/usr/bin/yarn run start:prod
EnvironmentFile=-/opt/grist/.env

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now grist.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
rm -rf /opt/v$RELEASE.zip
$STD apt-get -y autoclean
msg_ok "Cleaned"
