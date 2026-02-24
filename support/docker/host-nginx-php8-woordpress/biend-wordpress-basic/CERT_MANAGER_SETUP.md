# Cert-Manager ClusterIssuer Examples

Exemplos de configuração do cert-manager para obter certificados SSL/TLS automaticamente.

## 📋 Pré-requisitos

### Instalar Cert-Manager

```bash
# Adicionar repositório
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Instalar cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.0

# Verificar instalação
kubectl get pods -n cert-manager
```

## 🔐 ClusterIssuer Configurations

### 1. Let's Encrypt Production (Recomendado)

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Servidor Let's Encrypt de produção
    server: https://acme-v02.api.letsencrypt.org/directory
    
    # Email para notificações de expiração
    email: seu-email@example.com
    
    # Secret para armazenar a chave privada da conta ACME
    privateKeySecretRef:
      name: letsencrypt-prod
    
    # Solvers para validação HTTP-01
    solvers:
    - http01:
        ingress:
          class: nginx
```

Aplicar:
```bash
kubectl apply -f letsencrypt-prod-clusterissuer.yaml

# Verificar
kubectl get clusterissuer letsencrypt-prod
```

### 2. Let's Encrypt Staging (Para Testes)

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    # Servidor Let's Encrypt de staging (rate limits maiores)
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    
    email: seu-email@example.com
    
    privateKeySecretRef:
      name: letsencrypt-staging
    
    solvers:
    - http01:
        ingress:
          class: nginx
```

**Importante**: Use staging para testes! Production tem rate limits de 5 certificados/semana por domínio.

### 3. DNS-01 Challenge (Para Wildcard)

#### AWS Route53
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: seu-email@example.com
    privateKeySecretRef:
      name: letsencrypt-dns-prod
    solvers:
    - dns01:
        route53:
          region: us-east-1
          accessKeyID: YOUR_ACCESS_KEY_ID
          secretAccessKeySecretRef:
            name: route53-credentials-secret
            key: secret-access-key
```

#### Cloudflare
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-cloudflare
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: seu-email@example.com
    privateKeySecretRef:
      name: letsencrypt-cloudflare
    solvers:
    - dns01:
        cloudflare:
          email: seu-email@cloudflare.com
          apiTokenSecretRef:
            name: cloudflare-api-token-secret
            key: api-token
```

Criar secret:
```bash
kubectl create secret generic cloudflare-api-token-secret \
  --from-literal=api-token=YOUR_CLOUDFLARE_API_TOKEN \
  -n cert-manager
```

### 4. Self-Signed (Desenvolvimento Local)

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
```

## 🚀 Uso com Helm Chart

### Configuração Básica

```yaml
# production-values.yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: www.seusite.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wordpress-tls
      hosts:
        - www.seusite.com
```

Deploy:
```bash
helm install wordpress ./biend-wordpress-basic \
  -f production-values.yaml \
  --namespace production \
  --create-namespace
```

### Múltiplos Domínios

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: www.seusite.com
      paths:
        - path: /
          pathType: Prefix
    - host: blog.seusite.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wordpress-tls
      hosts:
        - www.seusite.com
        - blog.seusite.com
```

### Wildcard Certificate (Requer DNS-01)

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-cloudflare"
  hosts:
    - host: "*.seusite.com"
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: wildcard-tls
      hosts:
        - "*.seusite.com"
```

## 🔍 Troubleshooting

### Verificar ClusterIssuer
```bash
kubectl get clusterissuer
kubectl describe clusterissuer letsencrypt-prod
```

### Verificar Certificate
```bash
# Listar certificados
kubectl get certificate -n production

# Detalhes do certificado
kubectl describe certificate wordpress-tls -n production

# Deve mostrar:
# Status: True
# Type: Ready
```

### Verificar CertificateRequest
```bash
kubectl get certificaterequest -n production
kubectl describe certificaterequest -n production
```

### Verificar Challenges
```bash
# Durante a emissão, você verá challenges
kubectl get challenges -n production

# Logs do cert-manager
kubectl logs -n cert-manager deployment/cert-manager -f
```

### Logs Detalhados
```bash
# Cert-manager controller
kubectl logs -n cert-manager deployment/cert-manager -f

# Cert-manager webhook
kubectl logs -n cert-manager deployment/cert-manager-webhook -f

# Cert-manager cainjector
kubectl logs -n cert-manager deployment/cert-manager-cainjector -f
```

### Forçar Renovação
```bash
# Deletar o secret (cert-manager irá recriar)
kubectl delete secret wordpress-tls -n production

# Ou anotar o certificado
kubectl annotate certificate wordpress-tls \
  force-issue="$(date +%s)" \
  -n production
```

## 📅 Renovação Automática

Cert-manager renova certificados automaticamente:
- **Let's Encrypt**: Certificados válidos por 90 dias
- **Renovação**: Automática quando faltam 30 dias
- **Tentativas**: 5 tentativas de renovação antes de falhar

### Verificar Quando Expira
```bash
kubectl get certificate wordpress-tls -n production -o yaml | grep -A 5 status
```

### Notification de Expiração
Configure alertas no Prometheus/Grafana:
```yaml
# Alert quando faltarem 7 dias
- alert: CertificateExpiringSoon
  expr: certmanager_certificate_expiration_timestamp_seconds - time() < 7 * 24 * 60 * 60
  labels:
    severity: warning
```

## 🔐 Rate Limits do Let's Encrypt

| Limite | Valor |
|--------|-------|
| Certificados por domínio registrado | 50/semana |
| Duplicate certificates | 5/semana |
| Falhas de validação | 5/hora |
| Accounts per IP | 10/3 horas |
| Pending authorizations | 300 por conta |

**Dica**: Use staging para desenvolvimento!

## 📚 Recursos

- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [ACME DNS-01 Providers](https://cert-manager.io/docs/configuration/acme/dns01/)

## ✅ Checklist

- [ ] Cert-manager instalado (`kubectl get pods -n cert-manager`)
- [ ] ClusterIssuer criado (`kubectl get clusterissuer`)
- [ ] Ingress com annotation cert-manager.io/cluster-issuer
- [ ] TLS configurado no ingress
- [ ] Certificate criado automaticamente
- [ ] Certificate status: Ready
- [ ] Secret TLS criado
- [ ] Site acessível via HTTPS
- [ ] HTTP/2 funcionando (`curl -I --http2`)

---

**Atualizado**: Fevereiro 2026  
**Cert-Manager Version**: v1.13.0  
**Let's Encrypt**: Production ready
