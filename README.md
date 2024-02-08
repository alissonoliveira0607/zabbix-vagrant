# Aplicação Vagrant para Zabbix

Este é um ambiente Vagrant pré-configurado para executar o servidor Zabbix em uma máquina virtual Ubuntu 22.04.

## Requisitos

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/) ou outro provedor Vagrant compatível

## Configuração

1. Clone este repositório para o seu ambiente local:

    ```bash
    git clone https://github.com/alissonoliveira0607/zabbix-vagrant.git
    cd <NOME_DO_REPOSITORIO>
    ```

2. Inicialize e provisione a máquina virtual usando Vagrant:

    ```bash
    vagrant up
    ```

3. Acesse a máquina virtual via SSH:

    ```bash
    vagrant ssh
    ```

    Após acessar a máquina virtual, você estará dentro do ambiente Ubuntu configurado.

4. Acesse o frontend do Zabbix em seu navegador web do host:

    ```
    http://<IP_DA_VM>:80/zabbix
    ```

## Detalhes da Configuração

### Máquina Virtual

- Box: `generic/ubuntu2204`
- Memória: 4096 MB
- CPUs: 2
- Nome: ZABBIX

### Provisão

O arquivo `provision.sh` é responsável por instalar e configurar o servidor Zabbix, frontend, agente e banco de dados MariaDB.