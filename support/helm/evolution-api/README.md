# Evolution API - Helm Chart

Chart Helm para instalação da Evolution API no Kubernetes com suporte para PostgreSQL e Redis opcionais.

## Descrição

Este chart permite instalar a Evolution API (WhatsApp Multi-Device API) no Kubernetes com flexibilidade total para escolher quais componentes utilizar:

- **Evolution API**: Aplicação principal (obrigatória)
- **PostgreSQL**: Banco de dados (opcional - pode usar interno ou externo)
- **Redis**: Cache (opcional - pode usar interno ou externo)

## Pré-requisitos

- Kubernetes 1.19+
- Helm 3.0+
- PersistentVolume suportado (se usar persistência)

## Instalação

### 1. Instalação Completa (PostgreSQL + Redis internos)

Instalação padrão com todos os componentes:

```bash
helm install evolution-api ./evolution-api
```

### 2. Apenas Evolution API (sem PostgreSQL/Redis)

```bash
helm install evolution-api ./evolution-api \
  --set postgresql.enabled=false \
  --set redis.enabled=false
```

### 3. Com PostgreSQL externo

```bash
helm install evolution-api ./evolution-api \
  --set postgresql.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.host=postgres.exemplo.com \
  --set externalDatabase.username=evolution \
  --set externalDatabase.password=senha123 \
  --set externalDatabase.database=evolution
```

### 4. Com Redis externo

```bash
helm install evolution-api ./evolution-api \
  --set redis.enabled=false \
  --set externalRedis.enabled=true \
  --set externalRedis.host=redis.exemplo.com \
  --set externalRedis.port=6379
```

### 5. Com PostgreSQL e Redis externos

```bash
helm install evolution-api ./evolution-api \
  --set postgresql.enabled=false \
  --set redis.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.host=postgres.exemplo.com \
  --set externalDatabase.username=evolution \
  --set externalDatabase.password=senha123 \
  --set externalDatabase.database=evolution \
  --set externalRedis.enabled=true \
  --set externalRedis.host=redis.exemplo.com
```

### 6. Com S3/MinIO para armazenamento de arquivos

```bash
helm install evolution-api ./evolution-api \
  --set s3.enabled=true \
  --set s3.accessKey="YOUR_ACCESS_KEY" \
  --set s3.secretKey="YOUR_SECRET_KEY" \
  --set s3.bucket="evolution" \
  --set s3.endpoint="s3.us-east-1.amazonaws.com" \
  --set s3.region="us-east-1"
```

**Exemplo com MinIO:**

```bash
helm install evolution-api ./evolution-api \
  --set s3.enabled=true \
  --set s3.accessKey="minioadmin" \
  --set s3.secretKey="minioadmin" \
  --set s3.bucket="evolution" \
  --set s3.endpoint="minio.exemplo.com" \
  --set s3.port=9000 \
  --set s3.useSSL=false \
  --set s3.region="us-east-1"
```

## Segurança - API Key

A Evolution API requer uma API key para autenticação. O chart oferece duas opções:

### Auto-geração (Recomendado)

Se você não fornecer uma API key, o chart **gera automaticamente** uma key segura no formato:
- UUID (32 caracteres) + 25 caracteres aleatórios (A-Z, 0-9)
- Exemplo: `357cd6bf-f79d-47b9-b706-c30e6fd06e50-11VXFBOGY8KCG3AJEX3C8LZSW`

Para obter a API key gerada:

```bash
kubectl get secret evolution-api-secret -n <namespace> -o jsonpath="{.data.api-key}" | base64 --decode
```

**Persistência**: A API key gerada é preservada durante upgrades do Helm (usando `lookup` function).

### Key personalizada

Você pode fornecer sua própria API key:

```bash
helm install evolution-api ./evolution-api \
  --set evolution.authenticationApiKey="minha-chave-super-segura-12345"
```

Ou via `values.yaml`:

```yaml
evolution:
  authenticationApiKey: "minha-chave-super-segura-12345"
```

## Configuração via values.yaml

Crie um arquivo `custom-values.yaml`:

```yaml
# Evolution API
evolution:
  serverUrl: "https://evolution.seudominio.com"
  # API key é auto-gerada se não especificada
  # authenticationApiKey: "sua-chave-super-segura"
  
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 1000m
      memory: 1Gi

# PostgreSQL interno habilitado
postgresql:
  enabled: true
  auth:
    password: "senha-postgres-segura"
  primary:
    persistence:
      enabled: true
      size: 20Gi
      storageClass: "fast-ssd"

# Redis interno habilitado
redis:
  enabled: true
  master:
    persistence:
      enabled: true
      size: 10Gi
      storageClass: "fast-ssd"

# S3 para armazenamento de arquivos
s3:
  enabled: true
  accessKey: "YOUR_AWS_ACCESS_KEY"
  secretKey: "YOUR_AWS_SECRET_KEY"
  bucket: "evolution-storage"
  endpoint: "s3.us-east-1.amazonaws.com"
  port: 443
  useSSL: true
  region: "us-east-1"

# Ingress
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: evolution.seudominio.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: evolution-tls
      hosts:
        - evolution.seudominio.com
```

Instale com:

```bash
helm install evolution-api ./evolution-api -f custom-values.yaml
```

## Cenários de Uso

### Cenário 1: Desenvolvimento Local

```yaml
postgresql:
  enabled: true
  primary:
    persistence:
      enabled: false  # Sem persistência

redis:
  enabled: true
  master:
    persistence:
      enabled: false  # Sem persistência
```

### Cenário 2: Produção com Bancos Gerenciados

```yaml
postgresql:
  enabled: false

externalDatabase:
  enabled: true
  host: "postgres-prod.abc123.us-east-1.rds.amazonaws.com"
  username: "evolution"
  password: "senha-super-segura"
  database: "evolution_prod"

redis:
  enabled: false

externalRedis:
  enabled: true
  host: "redis-prod.abc123.cache.amazonaws.com"
  port: 6379
```

### Cenário 3: Alta Disponibilidade

```yaml
replicaCount: 3

evolution:
  resources:
    limits:
      cpu: 2000m
      memory: 2Gi
    requests:
      cpu: 1000m
      memory: 1Gi

postgresql:
  enabled: true
  primary:
    persistence:
      enabled: true
      size: 50Gi
      storageClass: "ssd"
  resources:
    limits:
      cpu: 1000m
      memory: 2Gi

redis:
  enabled: true
  master:
    persistence:
      enabled: true
      size: 20Gi
      storageClass: "ssd"
```

## Parâmetros Principais

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `replicaCount` | Número de réplicas do Evolution API | `1` |
| `image.repository` | Repositório da imagem | `evoapicloud/evolution-api` |
| `image.tag` | Tag da imagem | `latest` |
| `evolution.serverUrl` | URL do servidor | `http://localhost:8081` |
| `evolution.authenticationApiKey` | Chave de autenticação da API (auto-gerada se vazio) | `""` |
| `postgresql.enabled` | Habilitar PostgreSQL interno | `true` |
| `postgresql.auth.password` | Senha do PostgreSQL | `password` |
| `postgresql.primary.persistence.enabled` | Persistência do PostgreSQL | `true` |
| `postgresql.primary.persistence.size` | Tamanho do volume PostgreSQL | `10Gi` |
| `redis.enabled` | Habilitar Redis interno | `true` |
| `redis.master.persistence.enabled` | Persistência do Redis | `true` |
| `redis.master.persistence.size` | Tamanho do volume Redis | `5Gi` |
| `externalDatabase.enabled` | Usar PostgreSQL externo | `false` |
| `externalDatabase.host` | Host do PostgreSQL externo | `""` |
| `externalRedis.enabled` | Usar Redis externo | `false` |
| `externalRedis.host` | Host do Redis externo | `""` |
| `s3.enabled` | Habilitar armazenamento S3/MinIO | `false` |
| `s3.accessKey` | Chave de acesso S3/MinIO | `""` |
| `s3.secretKey` | Chave secreta S3/MinIO | `""` |
| `s3.bucket` | Nome do bucket S3 | `evolution` |
| `s3.endpoint` | Endpoint do S3/MinIO | `""` |
| `s3.port` | Porta do serviço S3/MinIO | `443` |
| `s3.useSSL` | Usar SSL para S3/MinIO | `true` |
| `s3.region` | Região do bucket S3 | `us-east-1` |
| `ingress.enabled` | Habilitar Ingress | `false` |

## Atualizando a Instalação

```bash
helm upgrade evolution-api ./evolution-api -f custom-values.yaml
```

## Troubleshooting

### Erro: "Operation not permitted" no PostgreSQL/Redis

Se você vê este erro nos logs:
```
chown: changing ownership of '/var/lib/postgresql/data/pgdata': Operation not permitted
```

**Causa**: Storage com restrições de permissão (NFS, Ceph, etc.)

**Solução**: O chart já inclui configurações de securityContext por padrão. Se o problema persistir:

1. **Use o arquivo de configuração para NFS**:
   ```bash
   helm install evolution-api ./evolution-api -f values-nfs.yaml
   ```

2. **Ou configure manualmente**:
   ```bash
   helm install evolution-api ./evolution-api \
     --set postgresql.initContainer.enabled=true \
     --set postgresql.securityContext.enabled=true
   ```

**Documentação completa**: Ver [PERMISSIONS_FIX.md](PERMISSIONS_FIX.md)

### Pods em CrashLoopBackOff

1. Verifique os logs:
   ```bash
   kubectl logs <pod-name>
   ```

2. Verifique eventos:
   ```bash
   kubectl describe pod <pod-name>
   ```

3. Problemas comuns:
   - **PostgreSQL**: Permissões de volume (ver acima)
   - **Evolution API**: Aguardando PostgreSQL/Redis (normal no primeiro start)
   - **Redis**: Permissões de volume (ver acima)

### API Key não aparece

Para obter a API key gerada automaticamente:
```bash
kubectl get secret evolution-api-secret -o jsonpath="{.data.api-key}" | base64 --decode
```

## Desinstalação

```bash
helm uninstall evolution-api
```

**ATENÇÃO**: Isso não remove os PVCs. Para removê-los:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=evolution-api
```

## Comandos Úteis

### Ver status dos pods

```bash
kubectl get pods -l app.kubernetes.io/instance=evolution-api
```

### Ver logs do Evolution API

```bash
kubectl logs -l app.kubernetes.io/name=evolution-api -f
```

### Ver logs do PostgreSQL

```bash
kubectl logs -l app.kubernetes.io/component=database -f
```

### Ver logs do Redis

```bash
kubectl logs -l app.kubernetes.io/component=cache -f
```

### Port-forward para acesso local

```bash
kubectl port-forward svc/evolution-api 8080:8080
```

Acesse: http://localhost:8080

## Troubleshooting

### Evolution API não conecta no PostgreSQL

Verifique se o PostgreSQL está rodando:

```bash
kubectl get pods -l app.kubernetes.io/component=database
kubectl logs -l app.kubernetes.io/component=database
```

### Evolution API não conecta no Redis

Verifique se o Redis está rodando:

```bash
kubectl get pods -l app.kubernetes.io/component=cache
kubectl logs -l app.kubernetes.io/component=cache
```

### Verificar variáveis de ambiente

```bash
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[0].env}' | jq
```

### Verificar o Secret

```bash
kubectl get secret evolution-api-secret -o yaml
```

## Licença

Este chart é mantido pela FHSNS.

## Suporte

Para questões e suporte, abra uma issue no repositório.
