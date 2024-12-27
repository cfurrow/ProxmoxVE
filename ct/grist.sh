#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Source: https://www.getgrist.com/product/self-managed/
# Source: https://github.com/gristlabs/grist-core
# Install: bash -c "$(wget -qLO - https://github.com/cfurrow/ProxmoxVE/raw/grist-spreadsheets/ct/grist.sh)"

# App Default Values
APP="Grist"
var_tags="database;spreadsheet"
var_cpu="1"
var_ram="1024"
var_disk="4"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/grist ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  RELEASE=$(wget -q https://github.com/gristlabs/grist-core/releases/latest -O - | grep "title>Release" | cut -d " " -f 5)
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then

    msg_info "Stopping ${APP} Service"
    systemctl stop grist
    msg_ok "Stopped ${APP} Service"

    msg_info "Updating ${APP} to ${RELEASE}"
    cd /opt
    rm -rf grist_bak
    mv grist grist_bak
    wget -q https://github.com/gristlabs/grist-core/releases/download/v$RELEASE.zip
    unzip -q v$RELEASE.zip -d grist
    cd grist
    yarn install >/dev/null 2>&1
    yarn run build:prod >/dev/null 2>&1
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${RELEASE}"

    msg_info "Starting ${APP} Service"
    systemctl start grist
    msg_ok "Started ${APP} Service"

    msg_info "Cleaning up"
    rm -rf v$RELEASE.zip
    msg_ok "Cleaned"

    msg_ok "Updated Successfully!\n"
  else
    msg_ok "No update required. ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Grist: http://${IP}:8484${CL}"
