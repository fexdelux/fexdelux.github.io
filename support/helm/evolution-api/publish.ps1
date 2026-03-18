# Script PowerShell para publicar o Helm Chart Evolution API
# Uso: .\publish.ps1

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

$CHART_DIR = "."
$CHART_NAME = "evolution-api"
$CHARTS_OUTPUT = "../../../charts"
$REPO_URL = "https://fexdelux.github.io/charts"

# Funcao para output colorido
function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ForegroundColor,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Message
    )
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($Message) {
        Write-Output ($Message -join ' ')
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Blue "======================================================="
Write-ColorOutput Blue "   Publicacao do Helm Chart: $CHART_NAME"
Write-ColorOutput Blue "======================================================="
Write-Output ""

# Verificar se o chart existe
if (-not (Test-Path "Chart.yaml")) {
    Write-ColorOutput Red "Erro: Chart.yaml nao encontrado no diretorio atual"
    Write-ColorOutput Yellow "Execute este script do diretorio: support/helm/evolution-api"
    exit 1
}

# Verificar se helm esta instalado
try {
    $helmVersion = helm version --short 2>$null
    Write-ColorOutput Green "Helm encontrado: $helmVersion"
} catch {
    Write-ColorOutput Red "Erro: Helm nao esta instalado"
    Write-Output "Instale o Helm: https://helm.sh/docs/intro/install/"
    exit 1
}
Write-Output ""

Write-ColorOutput Yellow "Etapa 1: Corrigindo line endings (CRLF -> LF)..."
try {
    # Converter arquivos de CRLF para LF (compatibilidade Linux/Kubernetes)
    $files = Get-ChildItem -Recurse -Include *.yaml,*.yml,*.tpl,*.txt,*.md
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match "`r`n") {
            $content = $content -replace "`r`n", "`n"
            [System.IO.File]::WriteAllText($file.FullName, $content)
        }
    }
    Write-ColorOutput Green "Line endings corrigidos (Unix LF)!"
} catch {
    Write-ColorOutput Yellow "Aviso: Nao foi possivel corrigir line endings automaticamente."
}
Write-Output ""

Write-ColorOutput Yellow "Etapa 2: Validando o chart..."
try {
    helm lint $CHART_DIR
    Write-ColorOutput Green "Chart validado com sucesso!"
} catch {
    Write-ColorOutput Red "Erro no lint do chart. Corrija os erros antes de publicar."
    exit 1
}
Write-Output ""

# Obter versao do chart
$chartYaml = Get-Content "Chart.yaml" -Raw
if ($chartYaml -match '(?m)^version:\s*(.+)$') {
    $CHART_VERSION = $matches[1].Trim()
} else {
    Write-ColorOutput Red "Erro: Nao foi possivel encontrar a versao no Chart.yaml"
    exit 1
}
Write-ColorOutput Blue "Versao do chart: $CHART_VERSION"
Write-Output ""

# Verificar se o diretorio de output existe
if (-not (Test-Path $CHARTS_OUTPUT)) {
    Write-ColorOutput Yellow "Criando diretorio de charts: $CHARTS_OUTPUT"
    New-Item -ItemType Directory -Force -Path $CHARTS_OUTPUT | Out-Null
}

# Verificar se a versao ja existe
$packagePath = Join-Path $CHARTS_OUTPUT "$CHART_NAME-$CHART_VERSION.tgz"
if (Test-Path $packagePath) {
    Write-ColorOutput Yellow "Versao $CHART_VERSION ja existe!"
    if (-not $Force) {
        $response = Read-Host "Deseja sobrescrever? (s/N)"
        if ($response -ne 's' -and $response -ne 'S') {
            Write-ColorOutput Red "Publicacao cancelada."
            Write-ColorOutput Yellow "Dica: Atualize a versao em Chart.yaml ou use -Force para sobrescrever."
            exit 1
        }
    }
    Remove-Item $packagePath -Force
}

Write-ColorOutput Yellow "Etapa 3: Empacotando o chart..."
try {
    helm package $CHART_DIR -d $CHARTS_OUTPUT
    Write-ColorOutput Green "Chart empacotado: $CHART_NAME-$CHART_VERSION.tgz"
} catch {
    Write-ColorOutput Red "Erro ao empacotar o chart."
    exit 1
}
Write-Output ""

Write-ColorOutput Yellow "Etapa 4: Atualizando indice do repositorio..."
$originalLocation = Get-Location
Set-Location ../../..
try {
    if (Test-Path "charts\index.yaml") {
        helm repo index charts\ --url $REPO_URL --merge charts\index.yaml
    } else {
        helm repo index charts\ --url $REPO_URL
    }
    Write-ColorOutput Green "Indice atualizado: charts\index.yaml"
} catch {
    Write-ColorOutput Red "Erro ao atualizar o indice."
    Set-Location $originalLocation
    exit 1
}
Set-Location $originalLocation
Write-Output ""

Write-ColorOutput Blue "======================================================="
Write-ColorOutput Green "Chart publicado com sucesso!"
Write-ColorOutput Blue "======================================================="
Write-Output ""
Write-ColorOutput Yellow "Proximos passos:"
Write-Output ""
Write-Output "  1. Fazer commit das mudancas:"
Write-ColorOutput Green "     git add charts/"
Write-ColorOutput Green "     git commit -m `"chore: publish evolution-api helm chart v$CHART_VERSION`""
Write-Output ""
Write-Output "  2. Criar tag da versao:"
Write-ColorOutput Green "     git tag evolution-api-v$CHART_VERSION"
Write-Output ""
Write-Output "  3. Fazer push para o repositorio:"
Write-ColorOutput Green "     git push origin main"
Write-ColorOutput Green "     git push --tags"
Write-Output ""
Write-ColorOutput Yellow "Apos o push, o chart estara disponivel em:"
Write-Output ""
Write-Output "  # Adicionar o repositorio"
Write-ColorOutput Green "  helm repo add fexdelux $REPO_URL"
Write-Output ""
Write-Output "  # Atualizar a lista de charts"
Write-ColorOutput Green "  helm repo update"
Write-Output ""
Write-Output "  # Buscar o chart"
Write-ColorOutput Green "  helm search repo fexdelux/$CHART_NAME"
Write-Output ""
Write-Output "  # Instalar o chart"
Write-ColorOutput Green "  helm install evolution-api fexdelux/$CHART_NAME"
Write-Output ""
Write-ColorOutput Cyan "Instalacao com configuracoes customizadas:"
Write-Output ""
Write-ColorOutput Green "  # Apenas Evolution API (sem PostgreSQL/Redis)"
Write-Output "  helm install evolution-api fexdelux/$CHART_NAME \"
Write-Output "    --set postgresql.enabled=false \"
Write-Output "    --set redis.enabled=false"
Write-Output ""
Write-ColorOutput Green "  # Com S3/MinIO"
Write-Output "  helm install evolution-api fexdelux/$CHART_NAME \"
Write-Output "    --set s3.enabled=true \"
Write-Output "    --set s3.bucket=evolution \"
Write-Output "    --set s3.accessKey=YOUR_KEY \"
Write-Output "    --set s3.secretKey=YOUR_SECRET"
Write-Output ""
Write-ColorOutput Green "  # Com Ingress"
Write-Output "  helm install evolution-api fexdelux/$CHART_NAME \"
Write-Output "    --set ingress.enabled=true \"
Write-Output "    --set ingress.hosts[0].host=evolution.example.com"
Write-Output ""
Write-ColorOutput Blue "======================================================="
