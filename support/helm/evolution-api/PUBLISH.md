# Publicação do Chart Evolution API

Script PowerShell para publicar o Helm Chart do Evolution API no repositório GitHub Pages.

## Pré-requisitos

- Helm 3.0+ instalado
- PowerShell
- Acesso de escrita ao repositório

## Uso

### Publicar nova versão

1. **Atualize a versão** no `Chart.yaml`:
   ```yaml
   version: 1.1.0  # Incremente a versão
   ```

2. **Execute o script** do diretório `support/helm/evolution-api`:
   ```powershell
   .\publish.ps1
   ```

3. **Sobrescrever versão existente** (use com cuidado):
   ```powershell
   .\publish.ps1 -Force
   ```

## O que o script faz

1. 🔧 **Corrige line endings** (CRLF → LF) para compatibilidade Linux
2. ✅ Valida o chart com `helm lint`
3. 📦 Empacota o chart (.tgz)
4. 📝 Atualiza o `charts/index.yaml`
5. 📋 Exibe instruções para commit e push

### Importante: Line Endings

O script **automaticamente converte** todos os arquivos de CRLF (Windows) para LF (Unix/Linux) antes de empacotar. Isso previne o erro de caracteres `^M` ao instalar o chart em servidores Linux/Kubernetes.

**Proteção adicional**: O arquivo `.gitattributes` garante que os commits sempre usem LF para arquivos YAML/YML/TPL.

## Após a publicação

O script exibe os próximos passos:

```bash
# 1. Commit
git add charts/
git commit -m "chore: publish evolution-api helm chart v1.0.0"

# 2. Tag
git tag evolution-api-v1.0.0

# 3. Push
git push origin main
git push --tags
```

## Instalação do chart publicado

Após o push, o chart estará disponível em:

```bash
# Adicionar repositório
helm repo add fexdelux https://fexdelux.github.io/charts

# Atualizar
helm repo update

# Buscar chart
helm search repo fexdelux/evolution-api

# Instalar
helm install evolution-api fexdelux/evolution-api
```

## Exemplos de instalação

### Instalação básica
```bash
helm install evolution-api fexdelux/evolution-api
```

### Sem PostgreSQL/Redis
```bash
helm install evolution-api fexdelux/evolution-api \
  --set postgresql.enabled=false \
  --set redis.enabled=false
```

### Com S3/MinIO
```bash
helm install evolution-api fexdelux/evolution-api \
  --set s3.enabled=true \
  --set s3.bucket=evolution \
  --set s3.accessKey=YOUR_KEY \
  --set s3.secretKey=YOUR_SECRET
```

### Com Ingress
```bash
helm install evolution-api fexdelux/evolution-api \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=evolution.example.com
```

## Versionamento

Siga o [Semantic Versioning](https://semver.org/):

- **MAJOR** (x.0.0): Mudanças incompatíveis
- **MINOR** (1.x.0): Novas funcionalidades compatíveis
- **PATCH** (1.0.x): Correções de bugs

## Troubleshooting

### Erro: "Versão já existe"
- Incremente a versão no `Chart.yaml`, ou
- Use `-Force` para sobrescrever (não recomendado em produção)

### Erro: "Chart.yaml não encontrado"
- Certifique-se de estar no diretório `support/helm/evolution-api`

### Erro: "Helm não instalado"
- Instale o Helm: https://helm.sh/docs/intro/install/

### Erro: Caracteres `^M` ou problemas de parse no Kubernetes
Este erro geralmente aparece como:
```
error: error parsing deployment-evolution.yaml: error converting YAML to JSON
```

**Causa**: Arquivos com line endings CRLF (Windows) ao invés de LF (Unix/Linux)

**Solução**: O script de publicação **automaticamente corrige** isso. Se o problema persistir:

```bash
# Converter manualmente todos os arquivos
cd support/helm/evolution-api
find . -name "*.yaml" -o -name "*.yml" -o -name "*.tpl" | xargs sed -i 's/\r$//'

# Verificar conversão
file values.yaml  # Deve mostrar "ASCII text" ou "UTF-8 text" (sem CRLF)
```

**Prevenção**: O arquivo `.gitattributes` força LF nos commits futuros.
