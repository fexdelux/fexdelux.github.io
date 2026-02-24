# Configuração de Certificado TLS no Pod WordPress

## Visão Geral

Este Helm Chart configura automaticamente um certificado TLS **autoassinado** para o pod do WordPress usando o **cert-manager**. O certificado é usado pelo Nginx dentro do container para servir o WordPress via HTTPS com HTTP/2.

## Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    Kubernetes Namespace                  │
│                                                          │
│  ┌──────────────┐      ┌─────────────────┐             │
│  │   Issuer     │─────>│  Certificate    │             │
│  │ (selfsigned) │      │  (wordpress-tls)│             │
│  └──────────────┘      └────────┬────────┘             │
│                                  │                       │
│                                  v                       │
│                        ┌─────────────────┐              │
│                        │  Secret (TLS)   │              │
│                        │  - tls.crt      │              │
│                        │  - tls.key      │              │
│                        └────────┬────────┘              │
│                                 │                        │
│                                 v (mounted)              │
│                        ┌─────────────────┐              │
│                        │  WordPress Pod  │              │
│                        │                 │              │
│                        │  Nginx + PHP    │              │
│                        │  Listen: 443    │              │
│                        │  HTTP/2 Enabled │              │
│                        └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

## Componentes Criados

### 1. Issuer (Self-Signed)

**Arquivo:** `templates/issuer.yaml`

```yaml
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: {{ releaseName }}-selfsigned
spec:
  selfSigned: {}
```

O Issuer é responsável por gerar certificados autoassinados no namespace.

### 2. Certificate

**Arquivo:** `templates/certificate.yaml`

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: {{ releaseName }}-tls
spec:
  secretName: {{ releaseName }}-tls-secret
  duration: 8760h  # 1 ano
  renewBefore: 720h  # Renovar 30 dias antes
  commonName: wordpress.local
  dnsNames:
    - wordpress.local
    - *.wordpress.local
    - localhost
  issuerRef:
    name: {{ releaseName }}-selfsigned
    kind: Issuer
```

O Certificate solicita ao Issuer a geração de um certificado TLS que será armazenado em um Secret.

### 3. Secret TLS

Criado automaticamente pelo cert-manager contendo:
- `tls.crt` - Certificado público
- `tls.key` - Chave privada

### 4. Montagem no Pod

**Arquivo:** `templates/deployment-wordpress.yaml`

O Secret é montado no pod em `/etc/nginx/ssl/`:

```yaml
volumeMounts:
  - name: tls-cert
    mountPath: /etc/nginx/ssl
    readOnly: true

volumes:
  - name: tls-cert
    secret:
      secretName: {{ releaseName }}-tls-secret
      defaultMode: 0400
```

### 5. Configuração do Nginx

**Arquivo:** `nginx-wordpress.conf`

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2 default_server;
    
    ssl_certificate /etc/nginx/ssl/tls.crt;
    ssl_certificate_key /etc/nginx/ssl/tls.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:...;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # ... resto da configuração
}
```

## Configuração via values.yaml

```yaml
certificate:
  enabled: true
  commonName: "wordpress.local"
  organization: "BiendIT"
  dnsNames:
    - "*.wordpress.local"
    - "localhost"

wordpress:
  service:
    type: ClusterIP
    port: 80
    httpsPort: 443
```

### Parâmetros Disponíveis

| Parâmetro | Descrição | Padrão |
|-----------|-----------|--------|
| `certificate.enabled` | Habilita criação do certificado | `true` |
| `certificate.commonName` | Nome comum (CN) do certificado | `wordpress.local` |
| `certificate.organization` | Organização (O) do certificado | `BiendIT` |
| `certificate.dnsNames` | SANs (Subject Alternative Names) | `["*.wordpress.local", "localhost"]` |
| `wordpress.service.httpsPort` | Porta HTTPS do Service | `443` |

## Instalação

### Pré-requisitos

1. **Cert-manager instalado no cluster:**

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

2. **Verificar cert-manager está rodando:**

```bash
kubectl get pods -n cert-manager
```

### Deploy do Helm Chart

```bash
# Atualizar dependências
helm dependency update

# Instalar
helm install wordpress ./biend-wordpress-basic \
  --set certificate.commonName="meuwordpress.local" \
  --set certificate.dnsNames[0]="meuwordpress.local" \
  --set certificate.dnsNames[1]="*.meuwordpress.local"
```

### Verificar Certificado Criado

```bash
# Ver o Certificate
kubectl get certificate

# Ver o Secret gerado
kubectl get secret wordpress-tls-secret

# Verificar detalhes do certificado
kubectl describe certificate wordpress-tls

# Ver o conteúdo do certificado
kubectl get secret wordpress-tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout
```

## Como Funciona

1. **Helm instala os recursos:**
   - Issuer (self-signed)
   - Certificate

2. **Cert-manager detecta o Certificate:**
   - Solicita ao Issuer a geração do certificado
   - Cria um Secret com `tls.crt` e `tls.key`

3. **Pod do WordPress inicia:**
   - Monta o Secret em `/etc/nginx/ssl/`
   - Nginx lê o certificado e chave privada
   - Nginx escuta na porta 443 com SSL/TLS

4. **Service expõe as portas:**
   - Porta 80 (HTTP) → Redireciona para HTTPS
   - Porta 443 (HTTPS) → Tráfego criptografado

## Renovação Automática

O cert-manager renova automaticamente o certificado **30 dias antes** da expiração:

- **Duração:** 1 ano (8760 horas)
- **Renovação:** 30 dias antes (720 horas)

Para forçar renovação manual:

```bash
kubectl delete secret wordpress-tls-secret
# O cert-manager recria automaticamente
```

## Testes

### 1. Verificar HTTPS no Pod

```bash
# Port-forward para o pod
kubectl port-forward svc/wordpress-wordpress 8443:443

# Testar HTTPS (certificado autoassinado)
curl -k https://localhost:8443/

# Verificar HTTP/2
curl -k -I --http2 https://localhost:8443/
```

### 2. Verificar Redirect HTTP → HTTPS

```bash
kubectl port-forward svc/wordpress-wordpress 8080:80

curl -I http://localhost:8080/
# Deve retornar: HTTP/1.1 301 Moved Permanently
# Location: https://localhost/
```

### 3. Inspecionar Certificado

```bash
# Extrair certificado do Secret
kubectl get secret wordpress-tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d > cert.pem

# Ver informações do certificado
openssl x509 -in cert.pem -text -noout

# Verificar validade
openssl x509 -in cert.pem -noout -dates
```

## Considerações de Segurança

### ⚠️ Certificado Autoassinado

- **Uso recomendado:** Desenvolvimento, testes, ambientes internos
- **NÃO recomendado:** Produção com acesso público
- **Navegadores:** Mostrarão aviso de certificado não confiável

### Para Produção

Para ambientes de produção com domínio público, recomenda-se:

1. **Usar Let's Encrypt no Ingress:**
   ```yaml
   ingress:
     enabled: true
     annotations:
       cert-manager.io/cluster-issuer: "letsencrypt-prod"
   ```

2. **Manter o pod com certificado autoassinado:**
   - Ingress Controller termina TLS (Let's Encrypt)
   - Comunicação Ingress → Pod usa TLS autoassinado (seguro dentro do cluster)

3. **Arquitetura recomendada:**
   ```
   Internet → HTTPS (Let's Encrypt) → Ingress Controller 
           → HTTPS (Self-Signed) → Pod WordPress
   ```

## Troubleshooting

### Certificado não é criado

```bash
# Verificar eventos do Certificate
kubectl describe certificate wordpress-tls

# Verificar logs do cert-manager
kubectl logs -n cert-manager deploy/cert-manager

# Verificar CertificateRequest
kubectl get certificaterequest
kubectl describe certificaterequest <name>
```

### Nginx não inicia com erro SSL

```bash
# Verificar se Secret foi criado
kubectl get secret wordpress-tls-secret

# Verificar se Secret tem os dados corretos
kubectl get secret wordpress-tls-secret -o yaml

# Verificar logs do pod
kubectl logs wordpress-wordpress-xxxxx

# Verificar montagem do volume
kubectl describe pod wordpress-wordpress-xxxxx
```

### HTTP/2 não funciona

```bash
# Verificar se TLS está configurado (HTTP/2 requer TLS)
curl -k -I --http2 https://localhost:443/

# Deve retornar: HTTP/2 200
```

### Certificado expirado

```bash
# Forçar renovação
kubectl delete secret wordpress-tls-secret

# Aguardar cert-manager recriar (alguns segundos)
kubectl get secret wordpress-tls-secret

# Reiniciar pod para recarregar certificado
kubectl rollout restart deployment wordpress-wordpress
```

## Referências

- [Cert-manager Documentation](https://cert-manager.io/docs/)
- [Nginx SSL/TLS Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [HTTP/2 in Nginx](https://nginx.org/en/docs/http/ngx_http_v2_module.html)
