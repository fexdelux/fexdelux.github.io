#!/bin/sh
set -e

# Criar diretórios necessários
mkdir -p /run/php /run/nginx /var/www/html

# Variáveis de ambiente padrão para WordPress
WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST:-mysql}"
WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
WORDPRESS_DB_USER="${WORDPRESS_DB_USER:-wordpress}"
WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wordpress123}"
WORDPRESS_TABLE_PREFIX="${WORDPRESS_TABLE_PREFIX:-wp_}"
WORDPRESS_DEBUG="${WORDPRESS_DEBUG:-false}"

# Verificar se WordPress já existe
if [ ! -f /var/www/html/wp-config.php ] && [ ! -f /var/www/html/index.php ]; then
    echo "WordPress não encontrado. Baixando última versão..."
    
    cd /tmp
    curl -o wordpress.tar.gz -fSL "https://wordpress.org/latest.tar.gz"
    echo "Extraindo WordPress..."
    tar -xzf wordpress.tar.gz
    
    echo "Copiando arquivos para /var/www/html..."
    cp -r wordpress/* /var/www/html/
    
    echo "Limpando arquivos temporários..."
    rm -rf wordpress wordpress.tar.gz
    
    echo "WordPress instalado com sucesso!"
fi

# Criar ou atualizar wp-config.php se não existir
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Criando wp-config.php..."
    
    # Gerar salt keys
    SALT_KEYS=$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/)
    
    cat > /var/www/html/wp-config.php <<EOF
<?php
/**
 * WordPress Configuration
 * Generated automatically by container entrypoint
 */

// ** Database settings ** //
define( 'DB_NAME', '${WORDPRESS_DB_NAME}' );
define( 'DB_USER', '${WORDPRESS_DB_USER}' );
define( 'DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}' );
define( 'DB_HOST', '${WORDPRESS_DB_HOST}' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

// ** Authentication Unique Keys and Salts ** //
${SALT_KEYS}

// ** WordPress Database Table prefix ** //
\$table_prefix = '${WORDPRESS_TABLE_PREFIX}';

// ** WordPress debugging mode ** //
define( 'WP_DEBUG', ${WORDPRESS_DEBUG} );

// Redis cache configuration (if Redis is available)
if ( getenv('REDIS_HOST') ) {
    define( 'WP_REDIS_HOST', getenv('REDIS_HOST') );
    define( 'WP_REDIS_PORT', getenv('REDIS_PORT') ?: 6379 );
    if ( getenv('REDIS_PASSWORD') ) {
        define( 'WP_REDIS_PASSWORD', getenv('REDIS_PASSWORD') );
    }
    define( 'WP_CACHE', true );
}

// Additional PHP settings
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '512M' );

// Security settings
define( 'DISALLOW_FILE_EDIT', true );
define( 'FORCE_SSL_ADMIN', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOF

    echo "wp-config.php criado com sucesso!"
fi

# Aplicar configuração PHP customizada se existir ConfigMap montado
if [ -f /etc/php-config/php-custom.ini ]; then
    echo "Aplicando configurações PHP customizadas..."
    cp /etc/php-config/php-custom.ini /etc/php83/conf.d/99-custom.ini
fi

# Aplicar configuração PHP-FPM pool customizada se existir
if [ -f /etc/php-config/php-fpm-www.conf ]; then
    echo "Aplicando configurações PHP-FPM pool customizadas..."
    cp /etc/php-config/php-fpm-www.conf /etc/php83/php-fpm.d/www.conf
fi

# Ajustar permissões
echo "Ajustando permissões..."
chown -R nginx:nginx /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Iniciar PHP-FPM em background
echo "Iniciando PHP-FPM 8.3..."
php-fpm83 -F &

# Aguardar PHP-FPM iniciar
sleep 2

# Iniciar Nginx em foreground
echo "Iniciando Nginx..."
exec nginx -g "daemon off;"
