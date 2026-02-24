# Instalação de Servidor PHP - Script Automatizado

Script para instalação e configuração automática de um servidor web completo com Nginx, MariaDB, PHP 8.3 e Certbot.

## O que é instalado

- **Nginx** - Servidor web
- **MariaDB** - Banco de dados (MySQL)
- **PHP 8.3** - Interpretador PHP com extensões essenciais
- **Certbot** - Gerador de certificados SSL Let's Encrypt

### Extensões PHP incluídas

- `php8.3-cli` - Interface de linha de comando
- `php8.3-fpm` - FastCGI Process Manager
- `php8.3-common` - Arquivos comuns
- `php8.3-curl` - Cliente HTTP
- `php8.3-gd` - Manipulação de imagens
- `php8.3-igbinary` - Serialização binária
- `php8.3-mbstring` - Manipulação de strings multibyte
- `php8.3-mcrypt` - Criptografia
- `php8.3-mysql` - Conector MySQL/MariaDB
- `php8.3-opcache` - Cache de bytecode
- `php8.3-readline` - Interface readline
- `php8.3-redis` - Cliente Redis
- `php8.3-soap` - Cliente/Servidor SOAP
- `php8.3-xml` - Parser XML
- `php8.3-xsl` - Transformações XSL
- `php8.3-zip` - Manipulação de arquivos ZIP

## Pré-requisitos

- Sistema operacional: Ubuntu/Debian
- Usuário com privilégios sudo/root
- Conexão com internet

## Uso

### Executar diretamente da internet

```bash
curl -s https://fexdelux.github.io/support/scripts/install_php_server.sh | sudo bash
```

Ou usando `wget`:

```bash
wget -qO- https://fexdelux.github.io/support/scripts/install_php_server.sh | sudo bash
```

### Executar localmente

```bash
# 1. Baixar o script
curl -O https://fexdelux.github.io/support/scripts/install_php_server.sh

# 2. Dar permissão de execução
chmod +x install_php_server.sh

# 3. Executar como root
sudo ./install_php_server.sh
```

## Configuração Pós-Instalação

### 1. MariaDB

A senha padrão do root é definida como: `fexdelux#11`

**IMPORTANTE**: Altere a senha após a instalação:

```bash
sudo mysql -u root -p
```

Dentro do MySQL:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED BY 'SUA_SENHA_FORTE';
FLUSH PRIVILEGES;
EXIT;
```

Execute o script de segurança:
```bash
sudo mysql_secure_installation
```

### 2. Nginx

Verificar status:
```bash
sudo systemctl status nginx
```

Editar configuração padrão:
```bash
sudo nano /etc/nginx/sites-available/default
```

Testar configuração:
```bash
sudo nginx -t
```

Reiniciar:
```bash
sudo systemctl restart nginx
```

### 3. PHP-FPM

Verificar status:
```bash
sudo systemctl status php8.3-fpm
```

Editar configuração:
```bash
sudo nano /etc/php/8.3/fpm/php.ini
```

Reiniciar:
```bash
sudo systemctl restart php8.3-fpm
```

### 4. Certbot (Certificado SSL)

Gerar certificado para um domínio:
```bash
sudo certbot --nginx -d seudominio.com -d www.seudominio.com
```

Renovação automática (já configurada):
```bash
sudo certbot renew --dry-run
```

## Exemplo de Configuração Nginx + PHP

Criar um novo site em `/etc/nginx/sites-available/meusite`:

```nginx
server {
    listen 80;
    server_name meudominio.com www.meudominio.com;
    root /var/www/meusite;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
```

Ativar o site:
```bash
sudo ln -s /etc/nginx/sites-available/meusite /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## Verificação da Instalação

### Verificar versões instaladas

```bash
# Nginx
nginx -v

# MariaDB
mysql --version

# PHP
php -v

# Certbot
certbot --version
```

### Testar PHP

Criar arquivo de teste:
```bash
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
```

Acessar: `http://seu-ip/info.php`

**IMPORTANTE**: Remova após testar:
```bash
sudo rm /var/www/html/info.php
```

### Testar MariaDB

```bash
sudo mysql -u root -p -e "SELECT VERSION();"
```

## Portas Utilizadas

- **80** - HTTP (Nginx)
- **443** - HTTPS (Nginx com SSL)
- **3306** - MariaDB
- **9000** - PHP-FPM (socket Unix por padrão)

## Firewall

Se estiver usando UFW, libere as portas:

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow 3306
sudo ufw enable
sudo ufw status
```

## Troubleshooting

### Nginx não inicia

```bash
# Verificar logs
sudo tail -f /var/log/nginx/error.log

# Verificar sintaxe
sudo nginx -t

# Verificar se a porta 80 está em uso
sudo netstat -tlnp | grep :80
```

### PHP-FPM não funciona

```bash
# Verificar logs
sudo tail -f /var/log/php8.3-fpm.log

# Verificar socket
ls -la /run/php/php8.3-fpm.sock

# Reiniciar serviço
sudo systemctl restart php8.3-fpm
```

### MariaDB não conecta

```bash
# Verificar status
sudo systemctl status mariadb

# Verificar logs
sudo tail -f /var/log/mysql/error.log

# Reiniciar serviço
sudo systemctl restart mariadb
```

### Certbot falha

```bash
# Verificar se a porta 80 está acessível
curl http://seudominio.com

# Verificar DNS
nslookup seudominio.com

# Logs do certbot
sudo certbot certificates
sudo tail -f /var/log/letsencrypt/letsencrypt.log
```

## Segurança

### Boas práticas após instalação

1. **Alterar senha do MariaDB root**
2. **Remover arquivo phpinfo.php**
3. **Configurar firewall (UFW)**
4. **Desabilitar listagem de diretórios no Nginx**
5. **Manter sistema atualizado**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```
6. **Configurar SSL/TLS com Certbot**
7. **Criar usuário MySQL específico para cada aplicação**
8. **Limitar acesso remoto ao MariaDB** (se não necessário)

### Hardening MariaDB

```bash
# Executar script de segurança
sudo mysql_secure_installation

# Respostas recomendadas:
# - Set root password? [Y/n] Y
# - Remove anonymous users? [Y/n] Y
# - Disallow root login remotely? [Y/n] Y
# - Remove test database? [Y/n] Y
# - Reload privilege tables now? [Y/n] Y
```

## Desinstalação

Para remover todos os componentes:

```bash
sudo apt remove --purge nginx mariadb-server mariadb-client php8.3-* -y
sudo apt autoremove -y
sudo snap remove certbot
sudo rm -rf /var/www/html/*
sudo rm -rf /var/lib/mysql
sudo rm -rf /etc/nginx
sudo rm -rf /etc/php
```

**ATENÇÃO**: Isso removerá todos os dados, bancos e configurações!

## Personalização do Script

Para adicionar parâmetros personalizáveis (senha, versão PHP, etc), modifique o script:

```bash
#!/bin/sh

# Parâmetros
DB_ROOT_PASSWORD=${1:-"senha_padrao"}
PHP_VERSION=${2:-"8.3"}

# Use as variáveis no script
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}'; FLUSH PRIVILEGES;"
```

Execução:
```bash
./install_php_server.sh "minha_senha_forte" "8.3"
```
