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

# cleanup
echo "cleanup APT repository cache and unused packages ..."
apt-get --yes autoremove
apt-get --yes purge
apt-get --yes clean

echo -n "cleanup unnecessary files ..."
rm -rf /usr/share/doc-base/*
rm -rf /usr/share/man/*
rm -rf /usr/share/man-db/*
rm -rf /usr/share/groff/*
rm -rf /usr/share/info/*
rm -rf /usr/share/lintian/*
rm -rf /usr/share/linda/*
rm -rf /var/cache/man/*
rm -rf /var/lib/initramfs-tools
rm -rf /var/share/initramfs-tools
rm -rf /usr/lib/initramfs-tools
rm -rf /etc/initramfs-tools
echo "done!"

echo -n "cleanup unnecessary locale files ..."
find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en' |xargs rm -rf
find /usr/share/i18n/charmaps -mindepth 1 -maxdepth 1 |xargs rm -r
echo "done!"

echo -n "cleanup unnecessary APT cache and compress files ..."
echo -n > /var/lib/apt/extended_states
rm -rf /var/cache/apt/archives/*.deb
rm -rf /var/cache/apt/*cache.bin
rm -rf /var/cache/apt-show-versions/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/lib/{cache,log}
rm -rf /var/log/apt
rm -rf /var/log/apt-cacher-ng
rm -rf /var/log/mysql
rm -rf /usr/src/*
echo "done!"

echo -n "cleanup all extra Log files and zero out the rest ..."
find /var/log -regex '.*?[0-9].*?' -exec rm -v {} \;
find /var/log -type f | while read file
do
    #cat /dev/null | tee $file  // zero out the file
    rm -f $file
done
echo "done!"

echo -n "cleanup build scripts files ..."
# rm -rf /build_scripts;
echo "done!"
