# Cert-Manager com Let's Encrypt - Script de Instalação

Script para configurar automaticamente o ClusterIssuer do Cert-Manager com Let's Encrypt.

## Pré-requisitos

- Cluster Kubernetes configurado
- `kubectl` instalado e configurado
- Cert-Manager já instalado no cluster
- Ingress Controller instalado (nginx, traefik, etc)

## Parâmetros

O script aceita 2 parâmetros obrigatórios:

1. **EMAIL**: Email para notificações do Let's Encrypt
2. **INGRESS_CLASS**: Nome da IngressClass do seu cluster (ex: `nginx`, `public`, `traefik`)

## Uso

### Executar diretamente da internet

```bash
curl -s https://fexdelux.github.io/support/scripts/cert-manager-letsencrypt.sh | bash -s -- seu@email.com public
```

Ou usando process substitution:

```bash
bash <(curl -s https://fexdelux.github.io/support/scripts/cert-manager-letsencrypt.sh) seu@email.com public
```

### Executar localmente

```bash
# 1. Baixar o script
curl -O https://fexdelux.github.io/support/scripts/cert-manager-letsencrypt.sh

# 2. Dar permissão de execução
chmod +x cert-manager-letsencrypt.sh

# 3. Executar
./cert-manager-letsencrypt.sh seu@email.com public
```

## Exemplos

### Com IngressClass "nginx"
```bash
curl -s https://fexdelux.github.io/support/scripts/cert-manager-letsencrypt.sh | bash -s -- admin@biend.com.br nginx
```

### Com IngressClass "public"
```bash
curl -s https://fexdelux.github.io/support/scripts/cert-manager-letsencrypt.sh | bash -s -- admin@biend.com.br public
```

### Execução local
```bash
./cert-manager-letsencrypt.sh admin@biend.com.br public
```

## Verificação

Após executar o script, verifique se o ClusterIssuer foi criado:

```bash
kubectl get clusterissuer
```

Saída esperada:
```
NAME          READY   AGE
letsencrypt   True    10s
```

Verificar detalhes:
```bash
kubectl describe clusterissuer letsencrypt
```

## Uso em Ingress

Após configurar o ClusterIssuer, use-o em seus Ingress:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: meu-app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
spec:
  ingressClassName: public
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: meu-service
            port:
              number: 80
  tls:
  - hosts:
    - app.example.com
    secretName: app-tls-secret
```

O Cert-Manager automaticamente criará e renovará o certificado SSL.

## Troubleshooting

### Verificar status do certificado
```bash
kubectl get certificate
kubectl describe certificate nome-do-certificado
```

### Verificar challenge do Let's Encrypt
```bash
kubectl get challenges
kubectl describe challenge nome-do-challenge
```

### Logs do Cert-Manager
```bash
kubectl logs -n cert-manager deployment/cert-manager
```

### Erros comuns

**"ClusterIssuer not ready"**
- Verifique se o Cert-Manager está rodando: `kubectl get pods -n cert-manager`
- Verifique os logs do Cert-Manager

**"Challenge failed"**
- Verifique se o Ingress Controller está funcionando
- Verifique se a porta 80 está acessível externamente
- Verifique se o DNS está apontando para o IP correto

**"Too many certificates"**
- Let's Encrypt tem rate limits
- Use o servidor de staging para testes: `https://acme-staging-v02.api.letsencrypt.org/directory`

## Configuração Avançada

### Usar servidor de staging (para testes)

Edite o script e altere:
```bash
export SERVER_LETSENCRYPT="https://acme-staging-v02.api.letsencrypt.org/directory"
```

### Adicionar múltiplos solvers

O YAML gerado pode ser customizado para incluir DNS-01 challenge ou outros solvers.
