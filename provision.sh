#!/bin/bash

# Instala o repositório Zabbix
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo apt update -y
# Instala o servidor Zabbix, frontend, agente
sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Instala o banco de dados MariaDB e configura
sudo apt install -y mariadb-server mariadb-client
sudo mysql -uroot -p <<MYSQL_SCRIPT
CREATE DATABASE zabbix character set utf8mb4 collate utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY 'zabbix';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
QUIT;
MYSQL_SCRIPT

sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -pzabbixs zabbix

sudo mysql -uroot -p <<MYSQL_SCRIPT
SET GLOBAL log_bin_trust_function_creators = 0;
QUIT;
MYSQL_SCRIPT

# Configura o servidor Zabbix
sudo echo "DBPassword=zabbix" >> /etc/zabbix/zabbix_server.conf

# Reinicia o serviço do servidor e agente Zabbix
sudo systemctl restart zabbix-server zabbix-agent

# Habilita o serviço do servidor e agente Zabbix na inicialização do sistema
sudo systemctl enable zabbix-server zabbix-agent

# Configura o fuso horário no PHP
sudo sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/8.1/apache2/php.ini

# Reinicia o servidor web Apache para aplicar as alterações
sudo systemctl restart apache2
