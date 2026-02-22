#!/bin/sh

apt install nginx -y
apt install mariadb-server mariadb-client -y
mysql -u root  -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'fexdelux#11'; FLUSH PRIVILEGES;"
apt install php8.3-cli php8.3-fpm php8.3-common -y
apt install php8.3-curl -y
apt install php8.3-gd 
apt install php8.3-igbinary -y
apt install php8.3-mbstring -y
apt install php8.3-mcrypt -y
apt install php8.3-mysql -y
apt install php8.3-opcache -y
apt install php8.3-readline -y
apt install php8.3-redis -y
apt install php8.3-soap -y
apt install php8.3-xml -y
apt install php8.3-xsl -y
apt install php8.3-zip -y

snap install --classic certbot

ln -s /snap/bin/certbot /usr/bin/certbot

