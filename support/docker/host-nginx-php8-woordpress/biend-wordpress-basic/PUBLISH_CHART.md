# Como Publicar o Helm Chart

Este guia explica como empacotar e publicar o Helm Chart `biend-wordpress-basic` para distribuição.

## 📦 Processo de Publicação

### 1. Estrutura de Diretórios

```
fexdelux.github.io/
├── charts/                          # Repositório de charts (gerado)
│   ├── index.yaml                   # Índice do repositório
│   └── biend-wordpress-basic-1.0.0.tgz  # Chart empacotado
└── support/
    └── docker/
        └── host-nginx-php8-woordpress/
            └── biend-wordpress-basic/   # Código fonte do chart
                ├── Chart.yaml
                ├── values.yaml
                └── templates/
```

### 2. Empacotar o Chart

#### Passo 1: Ir para o diretório do projeto

```bash
cd d:/workspaces/fhsns/fexdelux.github.io/support/docker/host-nginx-php8-woordpress
```

#### Passo 2: Empacotar o chart

```bash
helm package biend-wordpress-basic -d ../../../charts/
```

**Resultado:**
```
Successfully packaged chart and saved it to: ../../../charts/biend-wordpress-basic-1.0.0.tgz
```

Este comando cria um arquivo `.tgz` com todo o conteúdo do chart.

#### Opcional: Assinar o Chart (Segurança)

```bash
# Gerar chave GPG (se não tiver)
gpg --gen-key

# Empacotar e assinar
helm package biend-wordpress-basic \
  --sign \
  --key 'seu-email@exemplo.com' \
  --keyring ~/.gnupg/secring.gpg \
  -d ../../../charts/
```

### 3. Gerar o Índice do Repositório

O arquivo `index.yaml` é essencial para que o Helm encontre os charts disponíveis.

#### Passo 1: Ir para a pasta raiz

```bash
cd d:/workspaces/fhsns/fexdelux.github.io
```

#### Passo 2: Gerar o index.yaml

```bash
helm repo index charts/ --url https://fexdelux.github.io/charts
```

**Nota:** Substitua a URL pela URL real onde o repositório será hospedado.

#### Exemplo de index.yaml gerado:

```yaml
apiVersion: v1
entries:
  biend-wordpress-basic:
  - apiVersion: v2
    appVersion: 1.0.0
    created: "2026-02-24T10:30:00.000000000Z"
    description: Helm Chart para WordPress com Nginx + PHP 8.3 + MySQL + Redis
    digest: 5f7a8c9d2e1b3f4a6c8e0d2b4f6a8c0e2d4b6f8a0c2e4d6b8a0c2e4d6b8a0c2
    name: biend-wordpress-basic
    type: application
    urls:
    - https://fexdelux.github.io/charts/biend-wordpress-basic-1.0.0.tgz
    version: 1.0.0
generated: "2026-02-24T10:30:00.000000000Z"
```

### 4. Atualizar o Índice (Quando Adicionar Nova Versão)

Quando você publicar uma nova versão do chart:

```bash
# 1. Atualizar Chart.yaml com nova versão
# version: 1.1.0

# 2. Empacotar nova versão
cd d:/workspaces/fhsns/fexdelux.github.io/support/docker/host-nginx-php8-woordpress
helm package biend-wordpress-basic -d ../../../charts/

# 3. Atualizar o índice (mantém versões anteriores)
cd d:/workspaces/fhsns/fexdelux.github.io
helm repo index charts/ --url https://fexdelux.github.io/charts --merge charts/index.yaml
```

O parâmetro `--merge` preserva as versões anteriores do chart no índice.

## 🌐 Publicar no GitHub Pages

### Opção 1: GitHub Pages Automático

#### 1. Fazer commit e push

```bash
cd d:/workspaces/fhsns/fexdelux.github.io

git add charts/
git commit -m "chore: publish helm chart biend-wordpress-basic v1.0.0"
git push origin main
```

#### 2. Habilitar GitHub Pages

1. Acesse o repositório no GitHub
2. Vá em **Settings** → **Pages**
3. Em **Source**, selecione `main` branch
4. Pasta: `/` (root)
5. Salve

#### 3. Aguardar deploy

O GitHub Pages estará disponível em:
```
https://fexdelux.github.io/
```

### Opção 2: GitHub Actions (Automático)

Crie `.github/workflows/publish-helm-chart.yml`:

```yaml
name: Publish Helm Chart

on:
  push:
    branches:
      - main
    paths:
      - 'support/docker/host-nginx-php8-woordpress/biend-wordpress-basic/**'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Install Helm
        uses: azure/setup-helm@v3
        with:
          version: 'v3.13.0'
      
      - name: Package Helm Chart
        run: |
          cd support/docker/host-nginx-php8-woordpress
          helm package biend-wordpress-basic -d ../../../charts/
      
      - name: Generate Helm Index
        run: |
          helm repo index charts/ --url https://fexdelux.github.io/charts --merge charts/index.yaml
      
      - name: Commit and Push
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add charts/
          git commit -m "chore: update helm chart" || echo "No changes to commit"
          git push
```

## 📥 Usar o Chart Publicado

### 1. Adicionar o repositório

```bash
helm repo add fexdelux https://fexdelux.github.io/charts
helm repo update
```

### 2. Pesquisar charts disponíveis

```bash
helm search repo fexdelux
```

**Saída:**
```
NAME                            CHART VERSION   APP VERSION   DESCRIPTION
fexdelux/biend-wordpress-basic  1.0.0          1.0.0         Helm Chart para WordPress com Nginx + PHP 8.3...
```

### 3. Instalar o chart

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
# Informações do chart
helm show chart fexdelux/biend-wordpress-basic

# Ver todos os valores padrão
helm show values fexdelux/biend-wordpress-basic

# Ver README
helm show readme fexdelux/biend-wordpress-basic

# Ver tudo
helm show all fexdelux/biend-wordpress-basic
```

## 🔄 Versionamento Semântico

Siga o padrão [SemVer](https://semver.org/) no `Chart.yaml`:

```yaml
version: MAJOR.MINOR.PATCH
```

- **MAJOR** (1.x.x): Mudanças incompatíveis (breaking changes)
- **MINOR** (x.1.x): Novas funcionalidades compatíveis
- **PATCH** (x.x.1): Correções de bugs compatíveis

### Exemplos

```yaml
# Versão inicial
version: 1.0.0

# Correção de bug no template
version: 1.0.1

# Nova funcionalidade: adicionar suporte a autoscaling
version: 1.1.0

# Breaking change: mudar estrutura do values.yaml
version: 2.0.0
```

## 📋 Checklist de Publicação

Antes de publicar uma nova versão:

- [ ] Atualizar `Chart.yaml` com nova versão
- [ ] Atualizar `Chart.yaml` com nova `appVersion` (se aplicável)
- [ ] Atualizar `README.md` com novas funcionalidades
- [ ] Atualizar `CHANGELOG.md` (se existir)
- [ ] Testar o chart localmente
  ```bash
  helm install test ./biend-wordpress-basic --dry-run --debug
  ```
- [ ] Fazer lint do chart
  ```bash
  helm lint biend-wordpress-basic
  ```
- [ ] Empacotar o chart
- [ ] Atualizar o index.yaml
- [ ] Fazer commit e push
- [ ] Criar tag no Git
  ```bash
  git tag v1.0.0
  git push --tags
  ```

## 🛠️ Comandos Úteis

### Verificar Chart Empacotado

```bash
# Listar conteúdo do .tgz
tar -tzf charts/biend-wordpress-basic-1.0.0.tgz

# Extrair para inspeção
tar -xzf charts/biend-wordpress-basic-1.0.0.tgz -C /tmp
```

### Testar Chart Localmente

```bash
# Dry-run (não instala)
helm install wordpress ./biend-wordpress-basic --dry-run --debug

# Lint (validação)
helm lint biend-wordpress-basic

# Template (ver manifests gerados)
helm template wordpress ./biend-wordpress-basic
```

### Verificar Índice

```bash
# Ver índice local
cat charts/index.yaml

# Verificar se está acessível online
curl https://fexdelux.github.io/charts/index.yaml

# Baixar e testar chart
helm pull fexdelux/biend-wordpress-basic --version 1.0.0
```

## 🚀 Publicação em Outros Registries

### ChartMuseum

```bash
# Subir chart para ChartMuseum
curl --data-binary "@charts/biend-wordpress-basic-1.0.0.tgz" \
  http://chartmuseum.example.com/api/charts
```

### Harbor

```bash
# Login
helm registry login harbor.example.com

# Push
helm push charts/biend-wordpress-basic-1.0.0.tgz oci://harbor.example.com/library
```

### Artifactory

```bash
# Configurar repo
helm repo add artifactory https://artifactory.example.com/artifactory/helm-local \
  --username user --password pass

# Push via curl
curl -u user:pass \
  -T charts/biend-wordpress-basic-1.0.0.tgz \
  "https://artifactory.example.com/artifactory/helm-local/biend-wordpress-basic-1.0.0.tgz"
```

## 📄 Script de Automação

Crie `publish.sh` para automatizar o processo:

```bash
#!/bin/bash

set -e

CHART_DIR="support/docker/host-nginx-php8-woordpress/biend-wordpress-basic"
CHARTS_OUTPUT="../../../charts"
REPO_URL="https://fexdelux.github.io/charts"

echo "📦 Empacotando Helm Chart..."
cd "$CHART_DIR"
helm lint .
helm package . -d "$CHARTS_OUTPUT"

echo "📋 Atualizando índice do repositório..."
cd -
helm repo index charts/ --url "$REPO_URL" --merge charts/index.yaml

echo "✅ Chart publicado com sucesso!"
echo ""
echo "Próximos passos:"
echo "  1. git add charts/"
echo "  2. git commit -m 'chore: publish helm chart'"
echo "  3. git push origin main"
echo ""
echo "Após o push, o chart estará disponível em:"
echo "  helm repo add fexdelux $REPO_URL"
echo "  helm install wordpress fexdelux/biend-wordpress-basic"
```

Tornar executável:
```bash
chmod +x publish.sh
```

Executar:
```bash
./publish.sh
```

## 🔍 Troubleshooting

### Erro: "chart not found"

```bash
# Atualizar repositórios locais
helm repo update

# Verificar se o repo existe
helm repo list

# Remover e adicionar novamente
helm repo remove fexdelux
helm repo add fexdelux https://fexdelux.github.io/charts
```

### Erro: "index.yaml not found"

Verifique se o GitHub Pages está configurado corretamente:
```bash
curl -I https://fexdelux.github.io/charts/index.yaml
# Deve retornar HTTP 200 OK
```

### Erro ao empacotar

```bash
# Verificar Chart.yaml
cat biend-wordpress-basic/Chart.yaml

# Lint para identificar problemas
helm lint biend-wordpress-basic
```

## 📚 Referências

- [Helm Documentation](https://helm.sh/docs/)
- [Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Helm Repository Guide](https://helm.sh/docs/topics/chart_repository/)
- [GitHub Pages](https://pages.github.com/)
- [Semantic Versioning](https://semver.org/)
