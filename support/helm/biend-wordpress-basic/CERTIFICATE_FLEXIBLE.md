# Certificado Autoassinado Flexível

## Propósito

O certificado autoassinado é usado **exclusivamente para HTTP/2 na comunicação interna** do pod WordPress. Ele é **separado** do certificado Let's Encrypt que é gerenciado pelo Ingress.

## Configuração para Aceitar Qualquer IP/Domínio

### 1. Wildcards DNS (values.yaml)

```yaml
certificate:
  enabled: true
  commonName: "*.local"
  organization: "BiendIT"
  dnsNames:
    - "*.local"              # Aceita qualquer *.local
    - "*.svc"                # Serviços Kubernetes
    - "*.svc.cluster.local"  # FQDN interno do cluster
    - "localhost"            # Acesso local
    # Adicione seus domínios específicos
    - "*.seudominio.com.br"
    - "www.seudominio.com.br"
```

### 2. Endereços IP (opcional)

Para aceitar acesso direto por IP, adicione-os em `ipAddresses`:

```yaml
certificate:
  ipAddresses:
    - "127.0.0.1"      # Localhost IPv4
    - "::1"            # Localhost IPv6
    - "10.42.0.100"    # IP específico do pod (exemplo)
    - "192.168.1.50"   # IP externo (se aplicável)
```

## Descobrir o IP do Pod

Para adicionar o IP do pod ao certificado:

```bash
# Descobrir IP do pod
kubectl get pod -n <namespace> -o wide

# Adicionar ao values.yaml
certificate:
  ipAddresses:
    - "127.0.0.1"
    - "::1"
    - "10.42.x.x"  # IP do pod descoberto
```

## Limitações

⚠️ **Importante:** Certificados SSL/TLS sempre precisam de nomes/IPs específicos por design de segurança. Não existe "certificado para qualquer endereço".

A solução com wildcards (`*.local`, `*.svc`) cobre a maioria dos casos de uso interno, mas você sempre pode adicionar:
- Domínios específicos em `dnsNames`
- IPs específicos em `ipAddresses`

## Fluxo de SSL

```
Cliente Externo
    │
    └─→ Ingress (HTTPS - Let's Encrypt)
            │
            └─→ Service (HTTP/HTTPS interno)
                    │
                    └─→ Pod WordPress (HTTPS - Certificado Autoassinado)
                            └─→ HTTP/2 habilitado
```

## Atualizar Chart

Após modificar o certificado no values:

```bash
helm upgrade <release> ./biend-wordpress-basic \
  -f values-custom.yml \
  -n <namespace>
```

O cert-manager regenerará o certificado automaticamente com as novas configurações.
