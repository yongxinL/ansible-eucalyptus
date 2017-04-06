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
service_id="010"
service_source_root="/build_scripts/services/syslog-ng"

# install cron daemon
apt-get install -y --no-install-recommends syslog-ng-core;
mkdir -p "${unit_services_root}"/"${service_id}"-syslog-ng;
cp "${service_source_root}"/syslog-ng.runit "${unit_services_root}"/"${service_id}"-syslog-ng/run;
chmod +x "${unit_services_root}"/"${service_id}"-syslog-ng/run;
touch /var/log/syslog;
chmod u=rw,g=r,o= /var/log/syslog;
cp "${service_source_root}"/syslog_ng_default /etc/default/syslog-ng;

# install syslog-ng to docker logs forwarder
mkdir "${unit_services_root}"/"${service_id}"-syslog-forwarder
cp "${service_source_root}"/syslog-forwarder.runit "${unit_services_root}"/"${service_id}"-syslog-forwarder/run;
chmod +x "${unit_services_root}"/"${service_id}"-syslog-forwarder/run

# install logrotate
apt-get install -y --no-install-recommends logrotate;
cp "${service_source_root}"/logrotate.conf /etc/logrotate.conf
cp "${service_source_root}"/logrotate_syslogng /etc/logrotate.d/syslog-ng