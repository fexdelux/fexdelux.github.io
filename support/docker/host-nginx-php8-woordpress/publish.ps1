# Script PowerShell para publicar o Helm Chart
# Uso: .\publish.ps1

param(
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"

$CHART_DIR = "biend-wordpress-basic"
$CHART_NAME = "biend-wordpress-basic"
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
if (-not (Test-Path $CHART_DIR)) {
    Write-ColorOutput Red "Erro: Diretorio do chart nao encontrado: $CHART_DIR"
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

Write-ColorOutput Yellow "Etapa 1: Validando o chart..."
try {
    helm lint $CHART_DIR
    Write-ColorOutput Green "Chart validado com sucesso!"
} catch {
    Write-ColorOutput Red "Erro no lint do chart. Corrija os erros antes de publicar."
    exit 1
}
Write-Output ""

# Obter versao do chart
$chartYaml = Get-Content "$CHART_DIR\Chart.yaml" -Raw
if ($chartYaml -match 'version:\s*(.+)') {
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

Write-ColorOutput Yellow "Etapa 2: Empacotando o chart..."
try {
    helm package $CHART_DIR -d $CHARTS_OUTPUT
    Write-ColorOutput Green "Chart empacotado: $CHART_NAME-$CHART_VERSION.tgz"
} catch {
    Write-ColorOutput Red "Erro ao empacotar o chart."
    exit 1
}
Write-Output ""

Write-ColorOutput Yellow "Etapa 3: Atualizando indice do repositorio..."
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
    exit 1
}
Write-Output ""

Write-ColorOutput Blue "======================================================="
Write-ColorOutput Green "Chart publicado com sucesso!"
Write-ColorOutput Blue "======================================================="
Write-Output ""
Write-ColorOutput Yellow "Proximos passos:"
Write-Output ""
Write-Output "  1. Fazer commit das mudancas:"
Write-ColorOutput Green "     git add charts/"
Write-ColorOutput Green "     git commit -m `"chore: publish helm chart v$CHART_VERSION`""
Write-Output ""
Write-Output "  2. Criar tag da versao:"
Write-ColorOutput Green "     git tag v$CHART_VERSION"
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
Write-Output "  # Instalar o chart"
Write-ColorOutput Green "  helm install wordpress fexdelux/$CHART_NAME"
Write-Output ""
Write-ColorOutput Blue "======================================================="
