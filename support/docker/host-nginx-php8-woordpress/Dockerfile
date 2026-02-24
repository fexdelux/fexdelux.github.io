FROM alpine:3.19

# Configurar timezone
ENV TZ=America/Sao_Paulo

# Instalar Nginx, PHP 8.3 FPM e extensões necessárias
RUN apk add --no-cache \
        tzdata \
        curl \
        tar \
        nginx \
        php83 \
        php83-fpm \
        php83-cli \
        php83-curl \
        php83-gd \
        php83-mbstring \
        php83-mysqli \
        php83-mysqlnd \
        php83-opcache \
        php83-pecl-redis \
        php83-soap \
        php83-xml \
        php83-xsl \
        php83-zip \
        php83-intl \
        php83-bcmath \
        php83-dom \
        php83-simplexml \
        php83-xmlreader \
        php83-xmlwriter \
        php83-session \
        php83-tokenizer \
        php83-ctype \
        php83-fileinfo \
        php83-iconv \
        php83-phar && \
    # Criar symlinks para php e php-fpm
    ln -sf /usr/bin/php83 /usr/bin/php && \
    ln -sf /usr/sbin/php-fpm83 /usr/sbin/php-fpm && \
    # Configurar timezone
    cp /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    echo "America/Sao_Paulo" > /etc/timezone && \
    apk del tzdata

# Configurar Nginx e diretórios
RUN mkdir -p /var/www/html /run/php /run/nginx /var/cache/nginx/fastcgi && \
    rm -f /etc/nginx/http.d/default.conf && \
    chown -R nginx:nginx /var/www/html /var/lib/nginx /var/cache/nginx && \
    chmod -R 755 /var/www/html

# Copiar arquivos de configuração
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-wordpress.conf /etc/nginx/http.d/wordpress.conf
COPY php-fpm-www.conf /etc/php83/php-fpm.d/www.conf
COPY docker-entrypoint.sh /usr/local/bin/

# Criar diretório de logs do PHP-FPM e diretório SSL para certificados
RUN mkdir -p /var/log/php-fpm /etc/nginx/ssl && \
    chown nginx:nginx /var/log/php-fpm && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80 443
WORKDIR /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]


