# Build e Deploy da Imagem WordPress

Guia rápido para criar e publicar a imagem Docker WordPress com Nginx + PHP 8.3.

## 📦 Build da Imagem

### 1. Build local

```bash
cd support/docker/host-nginx-php8-woordpress

# Build com tag latest
docker build -t biend/wordpress-nginx-php8:latest .

# Build com tag específica
docker build -t biend/wordpress-nginx-php8:1.0.0 .

# Build multi-tag
docker build \
  -t biend/wordpress-nginx-php8:latest \
  -t biend/wordpress-nginx-php8:1.0.0 \
  .
```

### 2. Verificar imagem criada

```bash
# Listar imagens
docker images | grep wordpress-nginx-php8

# Ver detalhes
docker inspect biend/wordpress-nginx-php8:latest

# Ver histórico de layers
docker history biend/wordpress-nginx-php8:latest
```

### 3. Testar localmente

```bash
# Rodar container teste
docker run -d \
  --name wordpress-test \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=mysql:3306 \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=wordpress123 \
  biend/wordpress-nginx-php8:latest

# Ver logs
docker logs -f wordpress-test

# Testar acesso
curl http://localhost:8080

# Parar e remover
docker stop wordpress-test
docker rm wordpress-test
```

## 🚀 Push para Registry

### Docker Hub

```bash
# Login
docker login

# Tag
docker tag biend/wordpress-nginx-php8:latest your-dockerhub-user/wordpress-nginx-php8:latest

# Push
docker push your-dockerhub-user/wordpress-nginx-php8:latest
docker push your-dockerhub-user/wordpress-nginx-php8:1.0.0
```

### Registry Privado

```bash
# Login no registry privado
docker login registry.example.com

# Tag com URL do registry
docker tag biend/wordpress-nginx-php8:latest registry.example.com/biend/wordpress-nginx-php8:latest

# Push
docker push registry.example.com/biend/wordpress-nginx-php8:latest
```

### Harbor / Registry Local

```bash
# Login
docker login harbor.local.com

# Tag
docker tag biend/wordpress-nginx-php8:latest harbor.local.com/library/wordpress-nginx-php8:latest

# Push
docker push harbor.local.com/library/wordpress-nginx-php8:latest
```

## 🔧 Build Avançado

### Multi-stage Build (otimização futura)

Para reduzir ainda mais o tamanho da imagem, considere usar multi-stage build:

```dockerfile
# Stage 1: Build dependencies
FROM ubuntu:22.04 as builder
# ... install build tools ...

# Stage 2: Runtime
FROM ubuntu:22.04
COPY --from=builder /usr/bin/specific-tools /usr/bin/
# ... resto da configuração ...
```

### Build com BuildKit

```bash
# Habilitar BuildKit para builds mais rápidos
export DOCKER_BUILDKIT=1

# Build com cache
docker build --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t biend/wordpress-nginx-php8:latest .

# Build sem cache
docker build --no-cache -t biend/wordpress-nginx-php8:latest .
```

### Build para múltiplas arquiteturas

```bash
# Criar builder multi-arch
docker buildx create --name multiarch --use

# Build para AMD64 e ARM64
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t biend/wordpress-nginx-php8:latest \
  --push \
  .
```

## 📊 Informações da Imagem

### Componentes instalados

- **Base**: Alpine Linux 3.19 (minimal)
- **Nginx**: Alpine stable version
- **PHP**: 8.3 FPM
- **Extensões PHP**:
  - php83-cli
  - php83-fpm
  - php83-curl
  - php83-gd
  - php83-igbinary
  - php83-mbstring
  - php83-mysqli / php83-mysqlnd
  - php83-opcache
  - php83-pecl-redis
  - php83-soap
  - php83-xml / php83-xsl
  - php83-zip
  - php83-intl
  - php83-bcmath
  - php83-dom / php83-simplexml
  - php83-session / php83-tokenizer
  - php83-ctype / php83-fileinfo

### Tamanho estimado

- **Tamanho aproximado**: ~80-120MB (vs 500-600MB Ubuntu)
- **Redução**: ~80-85% menor que a versão Ubuntu
- **Layers**: 4-5 layers principais
- **Base Alpine**: ~5MB vs Ubuntu ~77MB

### Portas expostas

- **80**: HTTP (Nginx)

### Volumes recomendados

- `/var/www/html`: Arquivos do WordPress
- `/etc/php-config`: ConfigMap com php.ini customizado (opcional)

## 🔄 Atualizar Helm Chart

Após fazer o build e push, atualize o `values.yaml`:

```yaml
# biend-wordpress-basic/values.yaml
wordpress:
  image:
    repository: "your-registry/biend/wordpress-nginx-php8"
    tag: "1.0.0"
    pullPolicy: IfNotPresent
```

E faça upgrade do chart:

```bash
helm upgrade my-wordpress ./biend-wordpress-basic \
  --set wordpress.image.tag=1.0.0
```

## 🐛 Troubleshooting

### Erro de permissão no build

```bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### Build muito lento

```bash
# Limpar cache do Docker
docker builder prune

# Usar BuildKit
export DOCKER_BUILDKIT=1
```

### Imagem muito grande

```bash
# Ver o que está ocupando espaço
docker history biend/wordpress-nginx-php8:latest --human --format "table {{.Size}}\t{{.CreatedBy}}"

# Squash layers (experimental)
docker build --squash -t biend/wordpress-nginx-php8:latest .
```

## 📝 CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/docker-build.yml
name: Build Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: ./support/docker/host-nginx-php8-woordpress
          push: true
          tags: |
            biend/wordpress-nginx-php8:latest
            biend/wordpress-nginx-php8:${{ github.ref_name }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
docker-build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_TAG
  only:
    - tags
```

## 🔐 Segurança

### Scan de vulnerabilidades

```bash
# Trivy scan
trivy image biend/wordpress-nginx-php8:latest

# Docker scan
docker scan biend/wordpress-nginx-php8:latest
```

### Assinar imagem

```bash
# Docker Content Trust
export DOCKER_CONTENT_TRUST=1
docker push biend/wordpress-nginx-php8:latest
```
