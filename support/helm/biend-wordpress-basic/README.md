# Biend WordPress Basic - Helm Chart v1.0.0

Chart Helm para instalar WordPress com Nginx, PHP 8.3, MySQL/MariaDB e Redis em pods separados no Kubernetes.

## 📋 Pré-requisitos

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner suportado pelo cluster (para persistência)
- **Ingress Controller Nginx** (para acesso externo e HTTP/2)
- **Cert-Manager** (para geração automática de certificados TLS)

### Instalar Pré-requisitos

#### 1. Nginx Ingress Controller
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.enableHttp2=true
```

#### 2. Cert-Manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0
```

📖 **Ver guia completo**: [CERT_MANAGER_SETUP.md](./CERT_MANAGER_SETUP.md)

### 🔒 Certificado TLS Autoassinado no Pod

Este chart cria automaticamente um **Issuer** e um **Certificate** no namespace para gerar um certificado TLS autoassinado que é usado pelo Nginx dentro do pod. Isso permite:
- ✅ **HTTPS no pod** com certificado autoassinado
- ✅ **HTTP/2** habilitado (requer TLS)
- ✅ **Renovação automática** pelo cert-manager (1 ano, renova 30 dias antes)
- ✅ **Redirect HTTP → HTTPS** automático no Nginx

> **Nota:** O certificado autoassinado é ideal para ambientes internos, desenvolvimento e comunicação segura dentro do cluster. Para produção com domínio público, configure Let's Encrypt no **Ingress Controller** (separadamente do pod).

📖 **V� **TLS/HTTPS no pod** - Certificado autoassinado gerado automaticamente
   - �er guia completo**: [CERTIFICATE_SETUP.md](./CERTIFICATE_SETUP.md)

## 🎯 Componentes

Este chart implanta os seguintes componentes em pods separados:

1. **WordPress (Nginx + PHP 8.3)** - Servidor web e aplicação
   - ✨ Auto-instalação do WordPress (última versão oficial)
   - ✨ Auto-configuração via variáveis de ambiente
   - ✨ Criação automática do wp-config.php
   - ✨ Geração de salt keys únicos de segurança
   - ✨ Suporte automático a Redis (se habilitado)
   - 🚀 **HTTP/2 ready** - Otimizado para máxima performance
   - 💨 **Gzip compression** - Compressão automática
   - 🎯 **Cache otimizado** - Headers de cache configurados
2. **MySQL/MariaDB 10.11** - Banco de dados (opcional)
3. **Redis 7** - Cache de objetos (opcional)

### 🚀 Performance HTTP/2

O WordPress está otimizado para HTTP/2 quando deployado com Ingress + TLS:
- ✅ **Multiplexing** - Múltiplas requisições na mesma conexão
- ✅ **Header Compression** - HPACK compression
- ✅ **Server Push ready** - Headers preparados para push
- ✅ **Gzip compression** - Redução de 40-70% no tamanho
- ✅ **Cache optimizations** - Cache de 1 ano para assets estáticos

**Ganho esperado**: 60-70% de redução no tempo de carregamento

## 🚀 Instalação Rápida

### Instalação com componentes padrão (WordPress + MySQL + Redis)

```bash
# Adicionar o repositório (se disponível)
helm repo add biend https://charts.biend.com
helm repo update

# Instalar
helm install my-wordpress biend/biend-wordpress-basic

# OU instalar do diretório local
helm install my-wordpress ./biend-wordpress-basic
```

### Instalação customizada

```bash
# Instalar apenas WordPress (sem MySQL e Redis)
helm install my-wordpress ./biend-wordpress-basic \
  --set mysql.enabled=false \
  --set redis.enabled=false

# Instalar com valores customizados
helm install my-wordpress ./biend-wordpress-basic \
  --values my-custom-values.yaml

# Instalar com domínio customizado
helm install my-wordpress ./biend-wordpress-basic \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=wordpress.example.com
```

## ⚙️ Configuração

### Parâmetros Principais

#### Componentes (Habilitar/Desabilitar)

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `wordpress.enabled` | Habilita o pod WordPress | `true` |
| `mysql.enabled` | Habilita o pod MySQL | `true` |
| `redis.enabled` | Habilita o pod Redis | `true` |

#### WordPress

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `wordpress.replicaCount` | Número de réplicas | `1` |
| `wordpress.image.repository` | Imagem Docker | `your-registry/wordpress-nginx-php8` |
| `wordpress.image.tag` | Tag da imagem | `latest` |
| `wordpress.service.type` | Tipo de serviço | `ClusterIP` |
| `wordpress.service.port` | Porta HTTP do serviço | `80` |
| `wordpress.service.httpsPort` | Porta HTTPS do serviço | `443` |

#### Certificado TLS (Autoassinado)

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `certificate.enabled` | Habilita criação de certificado | `true` |
| `certificate.commonName` | Nome comum (CN) do certificado | `wordpress.local` |
| `certificate.organization` | Organização (O) do certificado | `BiendIT` |
| `certificate.dnsNames` | SANs (Subject Alternative Names) | `["*.wordpress.local", "localhost"]` |

#### Configurações PHP

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `wordpress.php.uploadMaxFilesize` | Tamanho máximo de upload | `64M` |
| `wordpress.php.postMaxSize` | Tamanho máximo de POST | `64M` |
| `wordpress.php.maxExecutionTime` | Tempo máximo de execução | `300` |
| `wordpress.php.memoryLimit` | Limite de memória | `256M` |
| `wordpress.php.maxInputVars` | Máximo de variáveis de input | `3000` |
| `wordpress.php.pmMaxChildren` | PHP-FPM max children | `50` |
| `wordpress.php.pmStartServers` | PHP-FPM start servers | `10` |
| `wordpress.php.pmMinSpareServers` | PHP-FPM min spare | `5` |
| `wordpress.php.pmMaxSpareServers` | PHP-FPM max spare | `20` |

#### Variáveis de Ambiente WordPress

O container WordPress suporta as seguintes variáveis automaticamente configuradas:

| Variável | Descrição | Fonte |
|----------|-----------|-------|
| `WORDPRESS_DB_HOST` | Host do MySQL | Automático (service name) |
| `WORDPRESS_DB_NAME` | Nome do banco | `mysql.auth.database` |
| `WORDPRESS_DB_USER` | Usuário do banco | `mysql.auth.username` |
| `WORDPRESS_DB_PASSWORD` | Senha do banco | Secret MySQL |
| `REDIS_HOST` | Host do Redis | Automático (se habilitado) |
| `REDIS_PORT` | Porta do Redis | `redis.service.port` |
| `REDIS_PASSWORD` | Senha do Redis | Secret Redis (se definido) |

**Nota**: O WordPress será instalado automaticamente na primeira execução se o volume estiver vazio.

#### MySQL/MariaDB

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `mysql.auth.rootPassword` | Senha do root | `fexdelux#11` |
| `mysql.auth.database` | Nome do banco | `wordpress` |
| `mysql.auth.username` | Usuário do banco | `wordpress` |
| `mysql.auth.password` | Senha do usuário | `wordpress123` |

#### Redis

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `redis.auth.password` | Senha do Redis (vazio = sem senha) | `""` |

#### Persistência

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `wordpress.persistence.enabled` | Habilita persistência WordPress | `true` |
| `wordpress.persistence.size` | Tamanho do PVC | `10Gi` |
| `mysql.persistence.enabled` | Habilita persistência MySQL | `true` |
| `mysql.persistence.size` | Tamanho do PVC | `10Gi` |
| `redis.persistence.enabled` | Habilita persistência Redis | `false` |
| `redis.persistence.size` | Tamanho do PVC | `2Gi` |

#### Ingress

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `ingress.enabled` | Habilita Ingress | `false` |
| `ingress.className` | Classe do Ingress | `nginx` |
| `ingress.hosts[0].host` | Hostname | `wordpress.example.com` |

## 📝 Exemplos de Uso

### 1. WordPress com MySQL externo

```yaml
# custom-values.yaml
mysql:
  enabled: false

wordpress:
  enabled: true
  env:
    WORDPRESS_DB_HOST: "mysql.external.com"
    WORDPRESS_DB_NAME: "my_wordpress"
    WORDPRESS_DB_USER: "wp_user"
    WORDPRESS_DB_PASSWORD: "secure_password"
```

```bash
helm install my-wordpress ./biend-wordpress-basic -f custom-values.yaml
```

### 2. WordPress com configurações PHP customizadas

```yaml
# php-custom.yaml
wordpress:
  php:
    uploadMaxFilesize: "128M"
    postMaxSize: "128M"
    maxExecutionTime: "600"
    memoryLimit: "512M"
    pmMaxChildren: "100"
```

```bash
helm install my-wordpress ./biend-wordpress-basic -f php-custom.yaml
```

### 3. WordPress com Ingress e SSL

```yaml
# ingress-ssl.yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/proxy-body-size: "128m"
  hosts:
    - host: myblog.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myblog-tls
      hosts:
        - myblog.com
```

```bash
helm install my-wordpress ./biend-wordpress-basic -f ingress-ssl.yaml
```

**Nota**: Com Ingress + TLS, HTTP/2 é habilitado automaticamente! 🚀

### 3.1. WordPress com Certificado TLS Customizado

```yaml
# custom-certificate.yaml
certificate:
  enabled: true
  commonName: "meuwordpress.interno"
  organization: "Minha Empresa LTDA"
  dnsNames:
    - "meuwordpress.interno"
    - "*.meuwordpress.interno"
    - "wordpress.interno"
```

```bash
helm install my-wordpress ./biend-wordpress-basic -f custom-certificate.yaml
```

**Nota**: O certificado é gerado automaticamente pelo cert-manager e montado no pod. O WordPress responderá em HTTPS com HTTP/2 habilitado! 🔒

### 3.2. WordPress com HTTP/2 e Performance Máxima

```yaml
# production-http2.yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    # Cert-manager
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    
    # HTTP/2 Optimizations (já incluídas por padrão)
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
    nginx.ingress.kubernetes.io/http2-push-preload: "true"
    nginx.ingress.kubernetes.io/enable-gzip: "true"
    
    # HSTS
    nginx.ingress.kubernetes.io/hsts: "true"
    nginx.ingress.kubernetes.io/hsts-max-age: "31536000"
    
  hosts:
    - host: www.seusite.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wordpress-tls
      hosts:
        - www.seusite.com

wordpress:
  replicaCount: 3
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 2Gi

redis:
  enabled: true
```

```bash
helm install wordpress ./biend-wordpress-basic -f production-http2.yaml
```

**Performance esperada**:
- PageSpeed Score: 90-95+
- Load Time: ~1.2s (vs 3.5s sem HTTP/2)
- First Contentful Paint: ~0.6s
- Largest Contentful Paint: ~1.0s

### 4. WordPress com Redis habilitado e senha

```yaml
# redis-enabled.yaml
redis:
  enabled: true
  auth:
    password: "my-secure-redis-password"
  persistence:
    enabled: true
    size: 5Gi
```

```bash
helm install my-wordpress ./biend-wordpress-basic -f redis-enabled.yaml
```

### 5. Instalação minimalista (apenas WordPress, sem persistência)

```bash
helm install my-wordpress ./biend-wordpress-basic \
  --set mysql.enabled=false \
  --set redis.enabled=false \
  --set wordpress.persistence.enabled=false
```

## 🔧 Gerenciamento

### Atualizar instalação

```bash
# Atualizar com novos valores
helm upgrade my-wordpress ./biend-wordpress-basic -f my-values.yaml

# Forçar recriação dos pods
helm upgrade my-wordpress ./biend-wordpress-basic --recreate-pods
```

### Ver status

```bash
# Status da release
helm status my-wordpress

# Ver todos os recursos criados
kubectl get all -l app.kubernetes.io/instance=my-wordpress

# Ver pods
kubectl get pods -l app.kubernetes.io/instance=my-wordpress
```

### Ver valores configurados

```bash
# Ver valores atuais
helm get values my-wordpress

# Ver todos os valores (incluindo padrões)
helm get values my-wordpress --all
```

### Desinstalar

```bash
# Desinstalar (mantém PVCs)
helm uninstall my-wordpress

# Desinstalar e remover PVCs
helm uninstall my-wordpress
kubectl delete pvc -l app.kubernetes.io/instance=my-wordpress
```

## 📊 Monitoramento

### Verificar logs

```bash
# Logs do WordPress
kubectl logs -f deployment/my-wordpress-biend-wordpress-basic-wordpress

# Logs do MySQL
kubectl logs -f deployment/my-wordpress-biend-wordpress-basic-mysql

# Logs do Redis
kubectl logs -f deployment/my-wordpress-biend-wordpress-basic-redis
```

### Acessar shell dos pods

```bash
# WordPress
kubectl exec -it deployment/my-wordpress-biend-wordpress-basic-wordpress -- bash

# MySQL
kubectl exec -it deployment/my-wordpress-biend-wordpress-basic-mysql -- bash

# Redis
kubectl exec -it deployment/my-wordpress-biend-wordpress-basic-redis -- sh
```

### Acessar MySQL CLI

```bash
kubectl exec -it deployment/my-wordpress-biend-wordpress-basic-mysql -- \
  mysql -u root -p'fexdelux#11' wordpress
```

### Verificar HTTP/2

```bash
# Via curl
curl -I --http2 https://www.seusite.com

# Deve retornar:
# HTTP/2 200
# server: nginx

# Via openssl
openssl s_client -connect www.seusite.com:443 -alpn h2 | grep "ALPN protocol"

# Deve retornar:
# ALPN protocol: h2
```

**Browser DevTools**:
1. Abra Chrome DevTools (F12)
2. Aba Network
3. Coluna "Protocol"
4. Deve mostrar "h2" para HTTP/2

## 🔐 Segurança

### Alterar senhas padrão

**IMPORTANTE**: Altere as senhas padrão em produção!

```yaml
mysql:
  auth:
    rootPassword: "sua-senha-root-segura"
    password: "sua-senha-wordpress-segura"

redis:
  auth:
    password: "sua-senha-redis-segura"
```

### Usar Secrets existentes

Você pode criar seus próprios Secrets e referenciá-los:

```bash
# Criar secret do MySQL
kubectl create secret generic my-mysql-secret \
  --from-literal=mysql-root-password=rootpass \
  --from-literal=mysql-password=wppass

# Criar secret do Redis
kubectl create secret generic my-redis-secret \
  --from-literal=redis-password=redispass
```

## 🚀 Build da Imagem Docker

Para usar este chart, você precisa fazer o build da imagem WordPress:

```bash
# Na pasta do Dockerfile
docker build -t your-registry/wordpress-nginx-php8:latest .

# Push para seu registry
docker push your-registry/wordpress-nginx-php8:latest

# Atualizar o values.yaml
wordpress:
  image:
    repository: your-registry/wordpress-nginx-php8
    tag: latest
```

**Nota**: A imagem usa Alpine Linux 3.19 como base, resultando em um tamanho de apenas ~80-120MB (vs 500-600MB com Ubuntu), proporcionando startups mais rápidos e menor uso de recursos.

## 📦 Package do Chart

```bash
# Criar package
helm package ./biend-wordpress-basic

# Verificar chart
helm lint ./biend-wordpress-basic

# Testar instalação (dry-run)
helm install my-wordpress ./biend-wordpress-basic --dry-run --debug
```

## 🐛 Troubleshooting

### Pod não inicia

```bash
# Ver eventos do pod
kubectl describe pod -l app.kubernetes.io/component=wordpress

# Ver logs detalhados
kubectl logs -f deployment/my-wordpress-biend-wordpress-basic-wordpress --previous
```

### Problemas de conectividade

```bash
# Testar conectividade com MySQL
kubectl run -it --rm debug --image=mysql:8 --restart=Never -- \
  mysql -h my-wordpress-biend-wordpress-basic-mysql -u wordpress -pwordpress123

# Testar conectividade com Redis
kubectl run -it --rm debug --image=redis:alpine --restart=Never -- \
  redis-cli -h my-wordpress-biend-wordpress-basic-redis ping
```

### PVC stuck in Pending

```bash
# Ver detalhes do PVC
kubectl describe pvc my-wordpress-biend-wordpress-basic-wordpress-pvc

# Verificar StorageClass disponíveis
kubectl get storageclass

# Definir StorageClass no values.yaml
global:
  storageClass: "your-storage-class"
```

## 📚 Recursos Adicionais

- [WordPress Documentation](https://wordpress.org/support/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

## 📄 Licença

MIT License

## 👥 Maintainers

- TechArch Team
- Email: support@techarch.com

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor, abra uma issue ou pull request.
