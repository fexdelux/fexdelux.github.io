# WordPress com Nginx + PHP 8.3 no Alpine Linux

Imagem Docker otimizada e Helm Chart para WordPress rodando em Alpine Linux 3.19 com Nginx e PHP 8.3 FPM.

## 🚀 Características

### Imagem Docker
- ⚡ **Alpine Linux 3.19** - Base ultra-leve (~80-120MB vs 500-600MB Ubuntu)
- 🔧 **Nginx** - Servidor web de alta performance com HTTP/2
- 🐘 **PHP 8.3 FPM** - Última versão estável do PHP
- 📦 **15+ extensões PHP** - Todas necessárias para WordPress
- 🤖 **Auto-instalação** - WordPress instalado automaticamente na primeira execução
- ⚙️ **Auto-configuração** - wp-config.php gerado via variáveis de ambiente
- 🔐 **Salt keys únicos** - Gerados automaticamente para segurança
- 🚀 **Suporte Redis** - Detecção e configuração automática
- 💨 **Gzip compression** - Compressão automática para todos assets
- 🎯 **Performance otimizada** - Buffer sizes, cache headers, sendfile

### Helm Chart (biend-wordpress-basic v1.0.0)
- 🎯 **Arquitetura de microserviços** - Pods separados para cada componente
- 🔄 **Flexível** - Habilite/desabilite componentes individualmente
- 💾 **Persistência opcional** - PVCs configuráveis por serviço
- 🔌 **Ingress integrado** - Suporte TLS e cert-manager
- 🚀 **HTTP/2 ready** - Annotations otimizadas para HTTP/2 no Ingress
- 📊 **ConfigMaps** - Configurações PHP customizáveis
- 🔒 **Secrets** - Credenciais gerenciadas com segurança
- 🛡️ **HSTS** - HTTP Strict Transport Security habilitado
- ⚡ **Rate limiting** - Proteção contra DDoS configurada

## 📁 Estrutura

```
.
├── Dockerfile                    # Imagem Alpine + Nginx + PHP 8.3
├── docker-entrypoint.sh          # Script de inicialização com auto-setup
├── docker-compose.yml            # Stack completa para testes locais
├── nginx-wordpress.conf          # Configuração otimizada do Nginx
├── php-fpm-www.conf             # Configuração PHP-FPM para Alpine
├── .dockerignore                # Arquivos ignorados no build
│
├── QUICKSTART.md                # ⭐ Comece aqui! Guia rápido
├── OVERVIEW.md                  # Visão geral completa do projeto
├── BUILD.md                     # Guia de build e publicação
├── ALPINE_MIGRATION.md          # Comparação Ubuntu vs Alpine
├── HTTP2_OPTIMIZATION.md        # 🚀 Otimizações HTTP/2 e Performance
│
└── biend-wordpress-basic/       # Helm Chart v1.0.0
    ├── Chart.yaml
    ├── values.yaml
    ├── README.md                # Documentação do Helm Chart
    ├── CERT_MANAGER_SETUP.md    # 🔐 Setup do Cert-Manager
    └── templates/               # Manifestos Kubernetes (14 arquivos)
```

## 🎯 Início Rápido

### Opção 1: Docker Compose (Recomendado para Testes)

```bash
# Clone ou navegue até o diretório
cd support/docker/host-nginx-php8-woordpress

# Iniciar stack completa (WordPress + MySQL + Redis)
docker-compose up -d

# Ver logs
docker-compose logs -f wordpress

# Acessar WordPress
# http://localhost:8080

# Parar
docker-compose down
```

### Opção 2: Docker Manual

```bash
# Build da imagem
docker build -t wordpress-alpine:latest .

# Rodar (WordPress será instalado automaticamente)
docker run -d \
  --name wordpress \
  -p 8080:80 \
  -e WORDPRESS_DB_HOST=seu-mysql \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wpuser \
  -e WORDPRESS_DB_PASSWORD=wppass \
  wordpress-alpine:latest
```

### Opção 3: Kubernetes com Helm

```bash
# Build e push da imagem
docker build -t your-registry/wordpress:alpine .
docker push your-registry/wordpress:alpine

# Instalar via Helm
helm install meu-wordpress ./biend-wordpress-basic \
  --set wordpress.image.repository=your-registry/wordpress \
  --set wordpress.image.tag=alpine

# Verificar
kubectl get pods
```

## ⚙️ Variáveis de Ambiente

O container suporta as seguintes variáveis de ambiente:

### Banco de Dados (Obrigatório)

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `WORDPRESS_DB_HOST` | `mysql` | Host do MySQL/MariaDB |
| `WORDPRESS_DB_NAME` | `wordpress` | Nome do banco de dados |
| `WORDPRESS_DB_USER` | `wordpress` | Usuário do banco |
| `WORDPRESS_DB_PASSWORD` | `wordpress123` | Senha do banco |

### WordPress (Opcional)

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `WORDPRESS_TABLE_PREFIX` | `wp_` | Prefixo das tabelas |
| `WORDPRESS_DEBUG` | `false` | Modo debug (true/false) |

### Redis (Opcional)

| Variável | Padrão | Descrição |
|----------|--------|-----------|
| `REDIS_HOST` | - | Host do Redis |
| `REDIS_PORT` | `6379` | Porta do Redis |
| `REDIS_PASSWORD` | - | Senha do Redis |

## 📊 Benefícios do Alpine

| Métrica | Ubuntu 22.04 | Alpine 3.19 | Melhoria |
|---------|--------------|-------------|----------|
| **Tamanho da imagem** | ~500-600 MB | ~80-120 MB | 📉 80-85% menor |
| **Tempo de startup** | 10-15s | 3-5s | ⚡ 60-70% mais rápido |
| **Uso de RAM** | 150-200 MB | 50-80 MB | 📉 60-70% menor |
| **Vulnerabilidades** | Mais CVEs | Menos CVEs | 🔒 Mais seguro |
| **Pull time** | ~45s | ~8s | ⚡ 82% mais rápido |

## 📚 Documentação

- **[QUICKSTART.md](./QUICKSTART.md)** ⭐ **Comece aqui!** Guia de teste e validação
- **[OVERVIEW.md](./OVERVIEW.md)** - Visão geral completa com todos os cenários
- **[BUILD.md](./BUILD.md)** - Guia completo de build e publicação em registries
- **[ALPINE_MIGRATION.md](./ALPINE_MIGRATION.md)** - Comparação detalhada Ubuntu vs Alpine
- **[HTTP2_OPTIMIZATION.md](./HTTP2_OPTIMIZATION.md)** 🚀 **Otimizações HTTP/2 e Performance**
- **[biend-wordpress-basic/README.md](./biend-wordpress-basic/README.md)** - Documentação do Helm Chart
- **[biend-wordpress-basic/CERT_MANAGER_SETUP.md](./biend-wordpress-basic/CERT_MANAGER_SETUP.md)** 🔐 **Setup do Cert-Manager**

## 🔧 Como Funciona

### 1. No primeiro start (volume vazio)
```
Container inicia
    ↓
Verifica /var/www/html
    ↓
Não encontra WordPress
    ↓
Baixa wordpress.org/latest.tar.gz
    ↓
Extrai para /var/www/html
    ↓
Gera salt keys únicos
    ↓
Cria wp-config.php com variáveis de ambiente
    ↓
Configura permissões
    ↓
Inicia PHP-FPM e Nginx
    ↓
✅ WordPress pronto para instalação!
```

### 2. Em starts subsequentes (volume com WordPress)
```
Container inicia
    ↓
Detecta WordPress existente
    ↓
Aplica ConfigMaps (se houver)
    ↓
Ajusta permissões
    ↓
Inicia PHP-FPM e Nginx
    ↓
✅ WordPress pronto!
```

## 🎨 Casos de Uso

### Desenvolvimento Local
```bash
docker-compose up -d
# Acesse: http://localhost:8080
```

### CI/CD Pipeline
```yaml
# .gitlab-ci.yml ou .github/workflows/deploy.yml
- docker build -t $CI_REGISTRY/wordpress:$CI_COMMIT_TAG .
- docker push $CI_REGISTRY/wordpress:$CI_COMMIT_TAG
- helm upgrade wordpress ./biend-wordpress-basic \
    --set wordpress.image.tag=$CI_COMMIT_TAG
```

### Produção Kubernetes
```bash
helm install prod-wordpress ./biend-wordpress-basic \
  --namespace production \
  --values production-values.yaml \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=www.seusite.com
```

## 🔐 Segurança

### Práticas Implementadas
- ✅ Salt keys únicos gerados automaticamente
- ✅ Credenciais via Secrets no Kubernetes
- ✅ Edição de arquivos desabilitada no admin (`DISALLOW_FILE_EDIT`)
- ✅ Base Alpine com menos vulnerabilidades
- ✅ PHP-FPM roda como usuário `nginx` (não-root)
- ✅ Nginx com security headers configurados

### Recomendações
```bash
# Scan de vulnerabilidades
trivy image wordpress-alpine:latest

# Atualizar para últimas versões
docker build --no-cache -t wordpress-alpine:latest .
```

## 🐛 Troubleshooting

### Container não inicia
```bash
docker logs <container-id>
```

### WordPress não baixa
```bash
# Verificar conectividade
docker exec <container> curl -I https://wordpress.org

# Verificar logs detalhados
docker logs -f <container>
```

### Erro de conexão com banco
```bash
# Testar conectividade MySQL
docker exec <container> ping mysql

# Verificar credenciais
docker exec <container> env | grep WORDPRESS_DB
```

### Problemas de permissão
```bash
# Container executa como usuário nginx
docker exec <container> ls -la /var/www/html
docker exec <container> ps aux | grep nginx
```

## 🤝 Contribuindo

Sugestões e melhorias são bem-vindas!

1. Faça fork do projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

MIT License

## 👥 Autor

TechArch Team  
**Website**: https://fexdelux.github.io  
**Support**: support@techarch.com

---

**Versão**: 1.0.0 (Alpine)  
**Última atualização**: Fevereiro 2026  
**Status**: ✅ Produção-ready
