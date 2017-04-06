#!/bin/ash
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

set -ex

# cleanup
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

echo -n "cleanup unnecessary APT cache and compress files ..."
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
