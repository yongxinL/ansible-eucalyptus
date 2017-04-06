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
apt-get install -y --no-install-recommends cron;
mkdir -p "${unit_services_root}"/"${service_id}"-cron
chmod 600 /etc/crontab
cp "${service_source_root}"/cron.runit "${unit_services_root}"/"${service_id}"-cron/run
chmod +x "${unit_services_root}"/"${service_id}"-cron/run
sed -i 's/^\s*session\s\+required\s\+pam_loginuid.so/# &/' /etc/pam.d/cron

# remove useless cron entries.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.weekly/fstrim
