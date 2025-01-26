#!/bin/bash

# Tratamento de erros global
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variáveis
KEYS=("ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDbC7fGQkGTjXERSAwLq7co5QXvahoXdG93m/Zx/+W1v+eme1ZohTCyi41MkcAJDr2KHSibwo6PE7WWjgYFAsZg/PNE6igI0D5VzC63T48tsK6ffxGFYy3rl0B/VyvHdfqe/vcw44zn6HRjF2q01DXV2NeSBZuJL+diclAcB+2jhrjha9iHWxxkJuxwFl76bAfhVdtNE6yC0It+aUtJLPT1ppcviGKpIyN1w6pGvWxk1pV+Pf6CdqU1FK05FeSPK+f34bSgIOin/DCNN6oBFgX2V5H/+Gf290bmlT9YGVSNZ0Y/HCK3Cetl3A+1j4YtbyANA3ju5mWeKeG8svzfphVRuOlKtwL+pVSrcnJuLIJqf4Nsq3PBAaPt9xzHk5vkmVfaMftQU0OXrgYhP2455SuuhpJe4LG3uyncRAXCK1AX7OoDI5jY6C4pZM00Vv+FOu5BYZLn28vr73B/rHBMzjnOCiouLbrYiCSL9VGtLcPTx4haoTWbm7fZSakyUhITI6M= alissonoliveira@ALISSON" "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD3FP9QVQjtyisZgoI3mVqjVrj2foF4qx+m8Z6/elOLW4sCfd1yZQf2aoYMXh6cZrTaCf4rzjKi30W+G7OETDOvPJq12K5/Sim8uQEGhrkxLpZtINEn2HGpHEmv30Fl0GhHm00ATLz0xu5JJcC0T7kRrTDLVUitM9oEcfGLL5ttZlvyqxg7n7nlS1/igXMAjleOWOiIddAa8KzMYpxjnLhA6Ytdl2fuHVhi3IkUVlY/1l773Coka7+kAevqyjrLm79bveIEAKQCguNzuhQQJkFFn30J7h4EazojY0CyHksMPK3h3y3bWPNWm9oi+DHaL1Bg6Oo6qwf/UTlYGIG3H1cjdxSFbOoFkHsc/mHFOEtoo2zvW0smJ18gWZYxbT2/7rVXenrZbPBxjFM7OlJHaErmFbRXTWKsqliQ+nzuSOS3UzANFN8YAsRxKHg0KRxIhV0EVfIciaMU60BgOZAPzplaFxCtvWnlUlhM5dIXk7MuYNgGI6L1w8tS6clvODuuQJiV06xhPMBbfAGtFumSt1/Cw3I9k6To1jl/VGCCFCkOJLxngGXQG4JtX/y3AEMRH0uDvQJcl9xteyvHv5Uieca9rPJ6FH3bQpW8m20k7vSN39+SDYLKZ6otAAkaRqRWwpMX/3lIvvMYp79MDbThtrr+JsxKJyvD1w36KQ8d7q9oew== root@ubuntu2204.localdomain")
USERS=("devops" "ansible" "zabbix")
HOST="zabbix"
# Variáveis
PACKAGES="mysql-server mysql-client"

ZABBIX_PACKAGES="zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent"

# Funções de log
log_info() { echo -e "${GREEN}[✔] INFO: $1${NC}"; }
log_warn() { echo -e "${YELLOW}[⚠] WARNING: $1${NC}"; }
log_error() { echo -e "${RED}[✖] ERROR: $1${NC}"; }

main() {
    # Verificação de root
    if [ "$EUID" -ne 0 ]; then 
        log_error "Este script precisa ser executado como root"
        exit 1
    fi

    check_connectivity
    backup_configs
    update_fstab
    install_packages
    setup_users
    configure_sudoers
    configure_ssh
    clone_ssh
    configure_hostname
    install_zabbix
    configure_zabbix
    update_configs_zabbix
}

check_connectivity() {
    log_info "🌐 Verificando conectividade de rede..."
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_error "Sem conexão com a internet"
        exit 1
    fi
}

backup_configs() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    log_info "📦 Criando backup das configurações..."
    for file in /etc/sudoers.d/* /etc/hostname; do
        [ -f "$file" ] && cp "$file" "${file}.bak_${timestamp}"
    done
}

update_fstab() {
    if grep -q -i "swap" /etc/fstab; then
        log_info "Desabilitando a swap no fstab"
        sed -i 's/^\([^#]*\bswap\b\)/#\1/g' /etc/fstab
        swapoff -a
    else
        log_info "Swap já está desabilitada no fstab"
    fi
}

install_packages() {
    log_info "📦 Instalando pacotes..."
    apt-get update -y
    apt-get install -y ${PACKAGES}
}

setup_users() {
    for user in "${USERS[@]}"; do
        if ! id -u "$user" >/dev/null 2>&1; then
            log_info "👤 Criando usuário $user..."
            useradd -m -d /home/$user -s /bin/bash "$user" || { log_error "Falha ao criar usuário $user"; exit 1; }
        else
            log_warn "👤 Usuário $user já existe"
        fi
    done
}

configure_sudoers() {
    for user in "${USERS[@]}"; do
        if [ ! -f "/etc/sudoers.d/$user" ]; then
            log_info "🔑 Configurando sudo para $user..."
            echo "$user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$user"
            chmod 440 "/etc/sudoers.d/$user"
            
            if ! visudo -c -f "/etc/sudoers.d/$user"; then
                log_error "Arquivo sudoers inválido para $user"
                rm -f "/etc/sudoers.d/$user"
                exit 1
            fi
        else
            log_warn "📝 Configuração sudo para $user já existe"
        fi
    done
}

configure_ssh() {
    log_info "🔑 Configurando chaves SSH..."
    for key in "${KEYS[@]}"; do
        if ! grep -q "$key" /home/vagrant/.ssh/authorized_keys 2>/dev/null; then
            echo "$key" >> /home/vagrant/.ssh/authorized_keys
        fi
    done
}

clone_ssh() {
    for user in "${USERS[@]}"; do
        local ssh_dir="/home/$user/.ssh"
        log_info "🔄 Configurando SSH para $user..."
        
        if [ ! -d "$ssh_dir" ]; then
            install -d -m 700 -o "$user" -g "$user" "$ssh_dir"
            cp /home/vagrant/.ssh/authorized_keys "$ssh_dir/"
            chown "$user":"$user" "$ssh_dir/authorized_keys"
            chmod 600 "$ssh_dir/authorized_keys"
        else
            log_warn "📝 Diretório SSH para $user já existe"
        fi
    done
}

configure_hostname() {
    log_info "🖥️ Configurando hostname..."
    hostnamectl set-hostname "$HOST" || { log_error "Falha ao configurar hostname"; exit 1; }
}

install_zabbix() {
    log_info "📦 Instalando Zabbix..."
    wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu20.04_all.deb
    dpkg -i zabbix-release_6.0-4+ubuntu20.04_all.deb
    apt update -y
    apt install -y ${ZABBIX_PACKAGES}
}

configure_zabbix() {
    log_info "⚙️ Configurando Zabbix..."
    
    mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS zabbix character set utf8mb4 collate utf8mb4_bin;
CREATE USER IF NOT EXISTS 'zabbix'@'localhost' IDENTIFIED BY 'zabbix';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
MYSQL_SCRIPT

    # Only import if the database is empty
    if [ $(mysql -N -s -u root zabbix -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='zabbix';") -eq 0 ]; then
        zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -pzabbix zabbix
    fi

    mysql -u root <<MYSQL_SCRIPT
SET GLOBAL log_bin_trust_function_creators = 0;
MYSQL_SCRIPT


    
    IP=$(ip addr show | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | tail -n 1)
    log_info "✨ Instalação concluída! IP do servidor: $IP"
}

update_configs_zabbix() {
    log_info "🔄 Atualizando configurações do Zabbix..."
    if grep -q DBPassword /etc/zabbix/zabbix_server.conf; then
        sed -i 's/DBPassword=/DBPassword=zabbix/' /etc/zabbix/zabbix_server.conf
    fi
    if grep -q date.timezone /etc/php/*/apache2/php.ini; then
        sed -i 's/;date.timezone =/date.timezone = America\/Sao_Paulo/' /etc/php/*/apache2/php.ini
    fi
    if grep -q DBHost /etc/zabbix/zabbix_server.conf; then
        sed -i "s/DBHost=localhost/DBHost=$HOST/" /etc/zabbix/zabbix_server.conf
    fi
    if grep -q DBName /etc/zabbix/zabbix_server.conf; then
        sed -i "s/DBName=zabbix/DBName=zabbix/" /etc/zabbix/zabbix_server.conf
    fi
    if grep -q DBUser /etc/zabbix/zabbix_server.conf ]; then
        sed -i "s/DBUser=zabbix/DBUser=zabbix/" /etc/zabbix/zabbix_server.conf
    fi

    sudo systemctl restart zabbix-server zabbix-agent apache2
    IP=$(ip addr show | grep 'inet ' | awk '{print $2}' | cut -d/ -f1 | tail -n 1)
    log_info "✨ Instalação concluída!"
    log_info "🔗 Acesse o Zabbix em http://$IP/zabbix"
    log_info "🔑 Credenciais: Admin/zabbix"
}
    

main