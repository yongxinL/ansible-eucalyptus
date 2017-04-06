#!/usr/bin/env bash
# =============================================================================
#
# - Copyright (C) 2017     George Li <yongxinl@outlook.com>
#
# - This is part of docker library project.
#   This is script is use to install required packages in target debian/ubuntu
#
# - This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# =============================================================================

set -e

## Variables -----------------------------------------------------------------
source /build_scripts/build_config;
service_id="011"
service_source_root="/build_scripts/services/cron"

# install cron daemon
apk add --no-cache dcron

mkdir -p "${unit_services_root}"/"${service_id}"-cron
cp "${service_source_root}"/cron.runit "${unit_services_root}"/"${service_id}"-cron/run
chmod +x "${unit_services_root}"/"${service_id}"-cron/run
mkdir -p /var/log/cron
mkdir -m 0644 -p /var/spool/cron/crontabs
touch /var/log/cron/cron.log
mkdir -m 0644 -p /etc/cron.d
