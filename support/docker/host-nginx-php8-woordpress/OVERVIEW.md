# WordPress com Kubernetes - Documentação Completa

## 📁 Estrutura do Projeto

```
support/docker/host-nginx-php8-woordpress/
├── Dockerfile                    # Imagem WordPress + Nginx + PHP 8.3
├── docker-entrypoint.sh          # Script de inicialização do container
├── nginx-wordpress.conf          # Configuração do Nginx para WordPress
├── BUILD.md                      # Guia de build e publicação da imagem
└── biend-wordpress-basic/        # Helm Chart v1.0.0
    ├── Chart.yaml                # Metadados do chart
    ├── values.yaml               # Configurações do usuário
    ├── README.md                 # Documentação completa do Helm Chart
    ├── .helmignore               # Arquivos ignorados no package
    └── templates/                # Manifestos Kubernetes
        ├── _helpers.tpl          # Funções auxiliares
        ├── configmap-php.yaml    # Configurações PHP.ini e PHP-FPM
        ├── deployment-wordpress.yaml  # Pod WordPress
        ├── deployment-mysql.yaml      # Pod MySQL/MariaDB
        ├── deployment-redis.yaml      # Pod Redis
        ├── service-wordpress.yaml     # Serviço WordPress
        ├── service-mysql.yaml         # Serviço MySQL
        ├── service-redis.yaml         # Serviço Redis
        ├── pvc-wordpress.yaml         # Volume WordPress
        ├── pvc-mysql.yaml             # Volume MySQL
        ├── pvc-redis.yaml             # Volume Redis
        ├── secret-mysql.yaml          # Credenciais MySQL
        ├── secret-redis.yaml          # Credenciais Redis
        └── ingress.yaml               # Ingress Controller
```

## 🚀 Guia Rápido de Deploy

### Passo 1: Build da Imagem Docker

```bash
cd support/docker/host-nginx-php8-woordpress

# Build
docker build -t your-registry/wordpress-nginx-php8:latest .

# Push para registry
docker push your-registry/wordpress-nginx-php8:latest
```

**Nota**: O WordPress será instalado automaticamente na primeira execução se não existir em `/var/www/html`.

📖 **Mais detalhes**: Ver [BUILD.md](BUILD.md)

### Passo 2: Configurar Variáveis de Ambiente

O container suporta as seguintes variáveis de ambiente:

```bash
# Banco de dados (obrigatório)
WORDPRESS_DB_HOST=mysql          # Host do MySQL
WORDPRESS_DB_NAME=wordpress      # Nome do banco
WORDPRESS_DB_USER=wordpress      # Usuário
WORDPRESS_DB_PASSWORD=senha123   # Senha

# Opcionais
WORDPRESS_TABLE_PREFIX=wp_       # Prefixo das tabelas
WORDPRESS_DEBUG=false            # Modo debug

# Redis (opcional)
REDIS_HOST=redis                 # Host do Redis
REDIS_PORT=6379                  # Porta do Redis
REDIS_PASSWORD=redispass         # Senha do Redis
```

### Passo 2: Configurar o Helm Chart

Edite `biend-wordpress-basic/values.yaml`:

```yaml
wordpress:
  image:
    repository: "your-registry/wordpress-nginx-php8"
    tag: "latest"
```

### Passo 3: Instalar no Kubernetes

```bash
# Instalar
helm install meu-wordpress ./biend-wordpress-basic

# Ou com valores customizados
helm install meu-wordpress ./biend-wordpress-basic -f custom-values.yaml

# Verificar status
kubectl get pods
```

📖 **Mais detalhes**: Ver [biend-wordpress-basic/README.md](biend-wordpress-basic/README.md)

## 🎯 Componentes da Solução

### 1. Imagem Docker (Dockerfile)

**Componentes instalados:**
- Alpine Linux 3.19 (base minimal)
- Nginx (servidor web)
- PHP 8.3 FPM
- 15+ extensões PHP essenciais para WordPress

**Funcionalidades:**
- ✅ Auto-instalação do WordPress (última versão)
- ✅ Auto-configuração via variáveis de ambiente
- ✅ Geração automática de salt keys
- ✅ Suporte a Redis (detecção automática)
- ✅ wp-config.php criado automaticamente

**Otimizações:**
- ✅ Base Alpine (80-85% menor que Ubuntu)
- ✅ Layers reduzidas (4-5 layers)
- ✅ Cache limpo automaticamente
- ✅ Sem pacotes desnecessários
- ✅ Tamanho: ~80-120MB (vs 500-600MB Ubuntu)
- ✅ Startup mais rápido
- ✅ Menor superfície de ataque

### 2. Helm Chart (biend-wordpress-basic)

**Arquitetura:**
- **3 Pods separados**: WordPress, MySQL, Redis
- **1 ConfigMap**: Configurações PHP customizáveis
- **2 Secrets**: Credenciais MySQL e Redis
- **3 PVCs**: Persistência opcional por componente
- **3 Services**: Comunicação ClusterIP
- **1 Ingress**: Acesso externo com TLS

**Flexibilidade:**
- ✅ Habilitar/desabilitar cada componente
- ✅ Usar banco de dados externo
- ✅ Configurar PHP via values.yaml
- ✅ Escalar réplicas independentemente
- ✅ Opções de persistência por serviço

## ⚙️ Configuração Rápida

### Cenário 1: Instalação Completa (recomendado)

```bash
helm install wordpress ./biend-wordpress-basic
```

Instala: WordPress + MySQL + Redis com persistência

### Cenário 2: WordPress com MySQL externo

```yaml
# values.yaml
mysql:
  enabled: false

wordpress:
  env:
    WORDPRESS_DB_HOST: "mysql.external.com"
```

```bash
helm install wordpress ./biend-wordpress-basic -f values.yaml
```

### Cenário 3: WordPress sem cache (mínimo)

```bash
helm install wordpress ./biend-wordpress-basic \
  --set redis.enabled=false
```

### Cenário 4: Produção com Ingress e SSL

```yaml
# production.yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: www.mysite.com
  tls:
    - secretName: mysite-tls
      hosts:
        - www.mysite.com

wordpress:
  replicaCount: 3
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 2Gi
  
  php:
    uploadMaxFilesize: "128M"
    memoryLimit: "512M"
    pmMaxChildren: 100

mysql:
  persistence:
    size: 50Gi
  resources:
    requests:
      memory: 1Gi
```

```bash
helm install wordpress ./biend-wordpress-basic -f production.yaml
```

## 🔧 Configurações PHP Disponíveis

Todas configuráveis via `values.yaml`:

```yaml
wordpress:
  php:
    uploadMaxFilesize: "64M"      # Tamanho máximo de upload
    postMaxSize: "64M"             # Tamanho máximo de POST
    maxExecutionTime: "300"        # Tempo máximo de execução
    memoryLimit: "256M"            # Limite de memória PHP
    maxInputVars: "3000"           # Máximo de variáveis de input
    pmMaxChildren: 50              # PHP-FPM: máximo de workers
    pmStartServers: 10             # PHP-FPM: workers iniciais
    pmMinSpareServers: 5           # PHP-FPM: mínimo de workers inativos
    pmMaxSpareServers: 20          # PHP-FPM: máximo de workers inativos
```

## 📊 Gerenciamento

### Ver recursos criados

```bash
# Todos os recursos
kubectl get all -l app.kubernetes.io/instance=meu-wordpress

# Apenas pods
kubectl get pods -l app.kubernetes.io/instance=meu-wordpress

# Volumes
kubectl get pvc -l app.kubernetes.io/instance=meu-wordpress

# Secrets
kubectl get secrets -l app.kubernetes.io/instance=meu-wordpress
```

### Verificar logs

```bash
# WordPress
kubectl logs -f deployment/meu-wordpress-biend-wordpress-basic-wordpress

# MySQL
kubectl logs -f deployment/meu-wordpress-biend-wordpress-basic-mysql

# Redis
kubectl logs -f deployment/meu-wordpress-biend-wordpress-basic-redis
```

### Atualizar instalação

```bash
# Atualizar com novos valores
helm upgrade meu-wordpress ./biend-wordpress-basic -f new-values.yaml

# Ver histórico
helm history meu-wordpress

# Rollback
helm rollback meu-wordpress 1
```

### Desinstalar

```bash
# Desinstalar (mantém PVCs)
helm uninstall meu-wordpress

# Remover PVCs também
kubectl delete pvc -l app.kubernetes.io/instance=meu-wordpress
```

## 🐛 Troubleshooting Rápido

### Pod não inicia

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Teste de conectividade

```bash
# MySQL
kubectl run -it --rm debug --image=mysql:8 --restart=Never -- \
  mysql -h meu-wordpress-biend-wordpress-basic-mysql -u wordpress -p

# Redis
kubectl run -it --rm debug --image=redis:alpine --restart=Never -- \
  redis-cli -h meu-wordpress-biend-wordpress-basic-redis ping
```

### PVC em Pending

```bash
# Ver detalhes
kubectl describe pvc <pvc-name>

# Verificar StorageClass
kubectl get storageclass

# Definir StorageClass específica
# Em values.yaml:
global:
  storageClass: "your-storage-class"
```

## 🔐 Segurança

### ⚠️ IMPORTANTE: Alterar senhas padrão!

```yaml
# values.yaml
mysql:
  auth:
    rootPassword: "senha-root-forte-aqui"
    password: "senha-wordpress-forte-aqui"

redis:
  auth:
    password: "senha-redis-forte-aqui"
```

### Scan de vulnerabilidades da imagem

```bash
trivy image your-registry/wordpress-nginx-php8:latest
```

## 📚 Documentação Completa

- **[BUILD.md](BUILD.md)** - Guia completo de build da imagem Docker
- **[biend-wordpress-basic/README.md](biend-wordpress-basic/README.md)** - Documentação completa do Helm Chart
- **[values.yaml](biend-wordpress-basic/values.yaml)** - Todas as configurações disponíveis

## 🎓 Exemplos Práticos

### Exemplo 1: Desenvolvimento local

```bash
helm install dev-wp ./biend-wordpress-basic \
  --set wordpress.replicaCount=1 \
  --set wordpress.persistence.enabled=false \
  --set mysql.persistence.enabled=false \
  --set redis.enabled=false
```

### Exemplo 2: Staging com recursos limitados

```yaml
# staging.yaml
wordpress:
  replicaCount: 2
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi
  persistence:
    size: 5Gi

mysql:
  resources:
    requests:
      memory: 512Mi
  persistence:
    size: 10Gi

redis:
  enabled: true
  persistence:
    enabled: false
```

```bash
helm install staging-wp ./biend-wordpress-basic -f staging.yaml
```

### Exemplo 3: Múltiplas instalações no mesmo cluster

```bash
# Instância 1: Blog
helm install blog-wp ./biend-wordpress-basic \
  --namespace blog \
  --create-namespace \
  --set ingress.hosts[0].host=blog.example.com

# Instância 2: Site corporativo
helm install corp-wp ./biend-wordpress-basic \
  --namespace corporate \
  --create-namespace \
  --set ingress.hosts[0].host=www.example.com

# Instância 3: E-commerce
helm install shop-wp ./biend-wordpress-basic \
  --namespace shop \
  --create-namespace \
  --set ingress.hosts[0].host=shop.example.com \
  --set redis.enabled=true
```

## 📈 Próximos Passos

1. ✅ Build da imagem Docker
2. ✅ Push para registry
3. ✅ Configurar values.yaml
4. ✅ Deploy no Kubernetes
5. ⏳ Configurar backup automático
6. ⏳ Implementar monitoramento (Prometheus/Grafana)
7. ⏳ Configurar auto-scaling (HPA)

## 🤝 Suporte

Para dúvidas ou problemas:
1. Verifique os logs dos pods
2. Consulte os README.md específicos
3. Revise os exemplos de configuração

---

**Versão**: 1.0.0  
**Última atualização**: 2024  
**Maintainer**: TechArch Team
