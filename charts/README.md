# Helm Charts Repository

Repositório de Helm Charts para deployments no Kubernetes.

## 📦 Charts Disponíveis

### biend-wordpress-basic

Helm Chart completo para WordPress com Nginx, PHP 8.3, MySQL e Redis.

**Funcionalidades:**
- ✨ WordPress auto-instalável e auto-configurável
- 🔒 Certificado TLS autoassinado gerado automaticamente
- 🚀 HTTP/2 habilitado para máxima performance
- 💨 Gzip compression (40-70% de redução)
- 🎯 Cache otimizado para assets estáticos
- 📦 MySQL/MariaDB 10.11 integrado
- ⚡ Redis para cache de objetos
- 🎛️ PHP 8.3 FPM com 15+ extensões

**Versão:** 1.0.0  
**App Version:** 1.0.0

## 🚀 Como Usar

### 1. Adicionar o repositório

```bash
helm repo add fexdelux https://fexdelux.github.io/charts
helm repo update
```

### 2. Listar charts disponíveis

```bash
helm search repo fexdelux
```

### 3. Instalar um chart

```bash
# Instalação padrão
helm install wordpress fexdelux/biend-wordpress-basic

# Com valores customizados
helm install wordpress fexdelux/biend-wordpress-basic \
  --set certificate.commonName="meusite.local" \
  --set wordpress.replicaCount=3

# Com arquivo de valores
helm install wordpress fexdelux/biend-wordpress-basic -f my-values.yaml
```

### 4. Ver informações do chart

```bash
# Ver valores padrão
helm show values fexdelux/biend-wordpress-basic

# Ver README completo
helm show readme fexdelux/biend-wordpress-basic

# Ver todas as informações
helm show all fexdelux/biend-wordpress-basic
```

## 📚 Documentação

Cada chart possui documentação detalhada no seu repositório:

- [biend-wordpress-basic](../support/docker/host-nginx-php8-woordpress/biend-wordpress-basic/README.md)

## 🔧 Para Desenvolvedores

### Estrutura do Repositório

```
charts/
├── index.yaml                            # Índice do repositório (gerado)
├── biend-wordpress-basic-1.0.0.tgz      # Chart empacotado (gerado)
└── README.md                             # Este arquivo
```

### Publicar Nova Versão

```bash
# Opção 1: Usar script de automação (PowerShell)
cd support/docker/host-nginx-php8-woordpress
.\publish.ps1

# Opção 2: Usar script de automação (Bash)
cd support/docker/host-nginx-php8-woordpress
./publish.sh

# Opção 3: Manual
cd support/docker/host-nginx-php8-woordpress
helm package biend-wordpress-basic -d ../../../charts/
cd ../../..
helm repo index charts/ --url https://fexdelux.github.io/charts --merge charts/index.yaml
```

### Checklist de Publicação

1. Atualizar versão em `Chart.yaml`
2. Executar `helm lint` para validar
3. Empacotar o chart
4. Atualizar o `index.yaml`
5. Commit e push para o repositório
6. Criar tag Git com a versão

📖 **Ver guia completo:** [PUBLISH_CHART.md](../support/docker/host-nginx-php8-woordpress/biend-wordpress-basic/PUBLISH_CHART.md)

## 🔍 Troubleshooting

### Chart não encontrado após atualizar repo

```bash
# Atualizar cache do Helm
helm repo update

# Verificar repositórios
helm repo list

# Remover e adicionar novamente
helm repo remove fexdelux
helm repo add fexdelux https://fexdelux.github.io/charts
```

### Erro ao acessar o repositório

```bash
# Verificar se o index.yaml está acessível
curl -I https://fexdelux.github.io/charts/index.yaml

# Deve retornar HTTP 200 OK
```

## 📄 Licença

Os charts neste repositório são distribuídos sob a licença especificada em cada chart individual.

## 🤝 Contribuindo

Para contribuir com novos charts ou melhorias:

1. Fork o repositório
2. Crie uma branch com sua feature (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'feat: adicionar nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📞 Suporte

Para questões ou suporte:
- Abra uma issue no repositório
- Consulte a documentação individual de cada chart
- Entre em contato com a equipe BiendIT
