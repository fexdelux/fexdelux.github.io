# Guia Rápido de Publicação do Helm Chart

## ⚡ Publicação Rápida

### Windows (PowerShell)

```powershell
# Executar script de publicação
cd support\docker\host-nginx-php8-woordpress
.\publish.ps1

# Ou com força (sobrescrever versão existente)
.\publish.ps1 -Force
```

### Linux/Mac (Bash)

```bash
# Executar script de publicação
cd support/docker/host-nginx-php8-woordpress
chmod +x publish.sh
./publish.sh
```

## 📦 Comandos Helm Essenciais

### 1. Empacotar Chart

```bash
# Em: support/docker/host-nginx-php8-woordpress/
helm package biend-wordpress-basic -d ../../../charts/
```

**Resultado:** `charts/biend-wordpress-basic-1.0.0.tgz`

### 2. Gerar/Atualizar Índice

```bash
# Na raiz do projeto
helm repo index charts/ --url https://fexdelux.github.io/charts

# OU atualizar mantendo versões anteriores
helm repo index charts/ --url https://fexdelux.github.io/charts --merge charts/index.yaml
```

### 3. Validar Chart

```bash
# Lint (validação)
helm lint biend-wordpress-basic

# Dry-run (testar sem instalar)
helm install test ./biend-wordpress-basic --dry-run --debug

# Ver templates gerados
helm template test ./biend-wordpress-basic
```

## 🔄 Workflow Completo

```bash
# 1. Atualizar versão (Chart.yaml)
version: 1.0.1

# 2. Validar
helm lint biend-wordpress-basic

# 3. Empacotar
helm package biend-wordpress-basic -d ../../../charts/

# 4. Atualizar índice
cd ../../..
helm repo index charts/ --url https://fexdelux.github.io/charts --merge charts/index.yaml

# 5. Commit
git add charts/
git commit -m "chore: publish helm chart v1.0.1"
git tag v1.0.1

# 6. Push
git push origin main
git push --tags
```

## 🌐 Usar Chart Publicado

```bash
# Adicionar repositório
helm repo add fexdelux https://fexdelux.github.io/charts
helm repo update

# Pesquisar
helm search repo fexdelux

# Instalar
helm install wordpress fexdelux/biend-wordpress-basic

# Ver valores padrão
helm show values fexdelux/biend-wordpress-basic
```

## 🎯 Estrutura Criada

```
fexdelux.github.io/
├── charts/                                      # ← Pasta para charts publicados
│   ├── README.md                               # Documentação do repositório
│   ├── index.yaml                              # Índice (gerado pelo Helm)
│   └── biend-wordpress-basic-1.0.0.tgz         # Chart empacotado
└── support/
    └── docker/
        └── host-nginx-php8-woordpress/
            ├── publish.sh                       # Script Bash
            ├── publish.ps1                      # Script PowerShell
            └── biend-wordpress-basic/           # Código fonte do chart
                ├── Chart.yaml                  # Metadados e versão
                ├── values.yaml                 # Valores padrão
                ├── README.md                   # Documentação
                ├── PUBLISH_CHART.md            # Guia de publicação completo
                └── templates/                  # Templates do Kubernetes
```

## 🔍 Verificações

### Verificar Chart Local

```bash
# Conteúdo do .tgz
tar -tzf charts/biend-wordpress-basic-1.0.0.tgz

# Extrair para inspeção
tar -xzf charts/biend-wordpress-basic-1.0.0.tgz -C /tmp
```

### Verificar Repositório Online

```bash
# Testar acesso ao índice
curl https://fexdelux.github.io/charts/index.yaml

# Testar download do chart
curl -O https://fexdelux.github.io/charts/biend-wordpress-basic-1.0.0.tgz
```

## ⚙️ Parâmetros do Script publish.ps1

```powershell
# PowerShell com força (sobrescrever sem perguntar)
.\publish.ps1 -Force
```

## 📝 Versionamento

Seguir **Semantic Versioning** no `Chart.yaml`:

```yaml
version: MAJOR.MINOR.PATCH
```

- **MAJOR** (1.x.x): Breaking changes
- **MINOR** (x.1.x): Novas funcionalidades
- **PATCH** (x.x.1): Correções de bugs

### Exemplos

```yaml
# Bug fix na configuração do Nginx
version: 1.0.1

# Nova funcionalidade: suporte a autoscaling
version: 1.1.0

# Breaking change: mudança na estrutura do values.yaml
version: 2.0.0
```

## 🚀 GitHub Pages

Após fazer push, habilitar GitHub Pages:

1. Acesse o repositório no GitHub
2. **Settings** → **Pages**
3. Source: `main` branch, pasta `/ (root)`
4. Save

O repositório estará em: `https://fexdelux.github.io/charts`

## 📚 Documentação Completa

Ver [PUBLISH_CHART.md](biend-wordpress-basic/PUBLISH_CHART.md) para guia detalhado com:
- GitHub Actions para automação
- Publicação em outros registries (Harbor, Artifactory)
- Troubleshooting completo
- Best practices
