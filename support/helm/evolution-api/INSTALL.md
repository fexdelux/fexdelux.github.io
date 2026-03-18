# Instalação Rápida - Evolution API Helm Chart

## API Key (Importante)

O chart **auto-gera** uma API key segura se você não especificar uma. Para obter a key gerada:

```bash
kubectl get secret evolution-api-secret -o jsonpath="{.data.api-key}" | base64 --decode
```

**Formato da key gerada**: `UUID-25caracteres` (exemplo: `357cd6bf-f79d-47b9-b706-c30e6fd06e50-11VXFBOGY8KCG3AJEX3C8LZSW`)

Se preferir usar sua própria key, adicione `--set evolution.authenticationApiKey="sua-key"`.

## Exemplos de Instalação

### 1. Instalação Padrão (Completa)
```bash
helm install evolution-api ./evolution-api
```

### 2. Instalação Apenas Evolution API (sem PostgreSQL/Redis)
```bash
helm install evolution-api ./evolution-api \
  --set postgresql.enabled=false \
  --set redis.enabled=false
```

### 3. Com Ingress e Let's Encrypt
```bash
helm install evolution-api ./evolution-api \
  --set evolution.serverUrl="https://evolution.exemplo.com" \
  --set ingress.enabled=true \
  --set ingress.className="nginx" \
  --set ingress.hosts[0].host="evolution.exemplo.com" \
  --set ingress.hosts[0].paths[0].path="/" \
  --set ingress.hosts[0].paths[0].pathType="Prefix" \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"="letsencrypt-prod" \
  --set ingress.tls[0].secretName="evolution-tls" \
  --set ingress.tls[0].hosts[0]="evolution.exemplo.com"
```

### 4. Produção com Bancos Externos
```bash
helm install evolution-api ./evolution-api \
  --set postgresql.enabled=false \
  --set redis.enabled=false \
  --set externalDatabase.enabled=true \
  --set externalDatabase.host="postgres.prod.com" \
  --set externalDatabase.username="evolution" \
  --set externalDatabase.password="senha123" \
  --set externalDatabase.database="evolution" \
  --set externalRedis.enabled=true \
  --set externalRedis.host="redis.prod.com" \
  --set externalRedis.port=6379
```

### 5. Desenvolvimento (sem persistência)
```bash
helm install evolution-api ./evolution-api \
  --set postgresql.primary.persistence.enabled=false \
  --set redis.master.persistence.enabled=false
```

### 6. Com S3/MinIO para armazenamento
```bash
# AWS S3
helm install evolution-api ./evolution-api \
  --set s3.enabled=true \
  --set s3.accessKey="AKIAIOSFODNN7EXAMPLE" \
  --set s3.secretKey="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" \
  --set s3.bucket="evolution-storage" \
  --set s3.endpoint="s3.us-east-1.amazonaws.com" \
  --set s3.region="us-east-1"

# MinIO
helm install evolution-api ./evolution-api \
  --set s3.enabled=true \
  --set s3.accessKey="minioadmin" \
  --set s3.secretKey="minioadmin" \
  --set s3.bucket="evolution" \
  --set s3.endpoint="minio.local" \
  --set s3.port=9000 \
  --set s3.useSSL=false
```

## Atualização
```bash
helm upgrade evolution-api ./evolution-api -f custom-values.yaml
```

## Desinstalação
```bash
helm uninstall evolution-api
```

## Verificação
```bash
# Ver status
kubectl get pods -l app.kubernetes.io/instance=evolution-api

# Ver logs
kubectl logs -l app.kubernetes.io/name=evolution-api -f

# Port-forward para teste local
kubectl port-forward svc/evolution-api 8080:8080
```
