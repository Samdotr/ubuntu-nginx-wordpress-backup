#/bin/bash

SOURCE="other-server"

DIRECTORY="/root/website-backups"
DB1="website1"
DB2="website2"

apt install -y nginx mysql-server
mysql_secure_installation
apt install -y php-fpm php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip
systemctl restart php7.4-fpm

# pull the files from Teams using rclone
rclone -vv --tpslimit 1 sync website-backups:General/daily/`date +\%a`/ $DIRECTORY/

# stop nginx and php
systemctl stop nginx php7.4-fpm

# website files
tar -xvf $DIRECTORY/$SOURCE-www.tar.gz -C /var/

# nginx configuration files
tar -xvf $DIRECTORY/$SOURCE-nginx.tar.gz -C /etc/

# php config file
cp $DIRECTORY/$SOURCE-php.ini /etc/php/7.4/fpm/php.ini

# paid SSL certificates
tar -xvf $DIRECTORY/$SOURCE-certs.tar.gz -C /root/

# free letsencrypt SSL certificates
tar -xvf $DIRECTORY/$SOURCE-letsencrypt.tar.gz -C /etc/

# main school website database
mysql -e'CREATE DATABASE '$DB1';'
mysql --verbose $DB1 < $DIRECTORY/$SOURCE-$DB1.sql

# summer school website database
mysql -e'CREATE DATABASE '$DB2';'
mysql --verbose $DB2 < $DIRECTORY/$SOURCE-$DB2.sql

# mysql users
mysql --verbose mysql < $DIRECTORY/$SOURCE-users.sql

# privileges
mysql -e'GRANT ALL PRIVILEGES ON '$DB1'.* TO '$DB1'@localhost;'
mysql -e'GRANT ALL PRIVILEGES ON '$DB2'.* TO '$DB2'@localhost;'
mysql -e'flush privileges;'

# start nginx and php
systemctl start nginx php7.4-fpm

