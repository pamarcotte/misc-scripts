#!/bin/bash
cd /usr/local/src


# Check for CentOS 7
if [[ $(grep -c 'CentOS Linux release 7' /etc/centos-release 2>/dev/null) -eq 0 ]]; then
  exit 1
fi


# Nginx, YAY!
cat << EOF > /etc/yum.repos.d/nginx.repo
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/7/\$basearch/
gpgcheck=0
enabled=1
EOF


# Install a bunch of stuff, cause it's totally missing on minimal installs.
yum -y install nginx wget bc bzip2-devel curl ftp gcc gcc-c++ gzip libxml2-devel libzip libzip-devel mariadb mariadb-server mariadb-devel mariadb-embedded mariadb-libs systemd-devel xmlrpc-c-devel zip zlib-devel


# We need these for mcrypt. Too bad C7 repositories are fail..... still.
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/l/libmcrypt-2.5.8-13.el7.x86_64.rpm
rpm -ivh http://dl.fedoraproject.org/pub/epel/7/x86_64/l/libmcrypt-devel-2.5.8-13.el7.x86_64.rpm


# Get PHP, extract it.
/bin/wget --content-disposition http://php.net/get/php-5.6.9.tar.gz/from/this/mirror
/bin/tar -xzf php-5.6.9.tar.gz
cd php-5.6.9


# Configure for some basic/common things.
./configure --prefix=/opt/php56 --enable-fpm --with-fpm-systemd --with-libdir=lib64 --with-bz2 --with-openssl --enable-bcmath --enable-calendar --with-curl --enable-ftp --enable-mbstring --with-mcrypt --with-mysql=/usr --with-mysql-sock=/var/lib/mysql/mysql.sock --with-pdo-mysql=/usr --with-zlib-dir --with-mysqli --enable-opcache --enable-soap --enable-sockets --with-xmlrpc --enable-zip && make && make install


# Unlink old files, add symlinks for 'default' PHP to run from /opt
for i in php php-cgi php-config phpize pear pecl phar; do
  if [ -L /usr/bin/$i ]; then
    /usr/bin/unlink /usr/bin/$i
  elif [ -f /usr/bin/$i ]; then
    /bin/mv -fv /usr/bin/$i /usr/bin/$i-$(date +%s)
  fi
  /bin/ln -sv /opt/php56/bin/$i /usr/bin/$i
done


# Make sure php-fpm is symlinked
if [ -L /usr/sbin/php-fpm ]; then
  /usr/bin/unlink /usr/sbin/php-fpm
elif [ -f /usr/sbin/php-fpm ]; then
  /bin/mv -fv /usr/sbin/php-fpm /usr/sbin/php-fpm-$(date +%s)
fi
/bin/ln -sv /opt/php56/sbin/php-fpm /usr/sbin/php-fpm


# Copy our configs into place. Eventually we'll have a proper config.
/bin/cp -fv php.ini-production /opt/php56/lib/php.ini
/bin/cp -fv /opt/php56/etc/php-fpm.conf.default /opt/php56/etc/php-fpm.conf


# Hurr durr i'ma systemd service
cat << EOF > /usr/lib/systemd/system/php-fpm.service
[Unit]
Description=The PHP FastCGI Process Manager
After=nginx.service

[Service]
Type=forking
PIDFile=/run/php-fpm.pid
ExecStart=/usr/sbin/php-fpm --pid /run/php-fpm.pid --fpm-config /opt/php56/etc/php-fpm.conf
ExecStop=/bin/kill -s QUIT \$MAINPID

[Install]
WantedBy=multi-user.target
EOF


mkdir -pv /opt/php56/etc/pool.d/
/bin/wget -O /opt/php56/etc/pool.d/www.conf http://lanyx.net/scripts/www.conf.txt
/bin/wget -O /opt/php56/etc/php-fpm.conf http://lanyx.net/scripts/php-fpm.conf.txt


# Now enable our services.
systemctl enable nginx.service
systemctl enable php-fpm.service


# And start them?
systemctl start nginx.service
systemctl start php-fpm.service


# And the person running this should know where things are...
echo -e "\n\nInstall dir: /opt/php56\nFPM Config: /opt/php56/etc/php-fpm.conf\nPool configs should go in: /opt/php56/etc/pool.d/*.conf\n\nOutput of /usr/bin/php -v:\n$(/usr/bin/php -v)\n\nCOMPLETE"
