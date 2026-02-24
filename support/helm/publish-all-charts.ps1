# Script PowerShell para publicar todos os Helm Charts
# Uso: .\publish-all-charts.ps1

param(
    [switch]$Force = $false,
    [string]$ChartFilter = "*",
    [switch]$SkipLint = $false
)

$ErrorActionPreference = "Stop"

$CHARTS_OUTPUT = "../../charts"
$REPO_URL = "https://fexdelux.github.io/charts"
$publishedCharts = @()
$failedCharts = @()

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
Write-ColorOutput Blue "   Publicacao de Helm Charts - Batch"
Write-ColorOutput Blue "======================================================="
Write-Output ""

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

# Buscar todos os charts na pasta atual
Write-ColorOutput Yellow "Buscando Helm Charts..."
$chartDirs = Get-ChildItem -Directory | Where-Object {
    Test-Path (Join-Path $_.FullName "Chart.yaml")
}

if ($ChartFilter -ne "*") {
    $chartDirs = $chartDirs | Where-Object { $_.Name -like $ChartFilter }
}

if ($chartDirs.Count -eq 0) {
    Write-ColorOutput Red "Nenhum Helm Chart encontrado na pasta atual"
    exit 1
}

Write-ColorOutput Green "Encontrados $($chartDirs.Count) chart(s):"
foreach ($dir in $chartDirs) {
    Write-Output "  - $($dir.Name)"
}
Write-Output ""

# Verificar se o diretorio de output existe
if (-not (Test-Path $CHARTS_OUTPUT)) {
    Write-ColorOutput Yellow "Criando diretorio de charts: $CHARTS_OUTPUT"
    New-Item -ItemType Directory -Force -Path $CHARTS_OUTPUT | Out-Null
}

# Processar cada chart
$chartNumber = 1
foreach ($chartDir in $chartDirs) {
    $CHART_DIR = $chartDir.Name
    
    Write-ColorOutput Blue "======================================================="
    Write-ColorOutput Blue "   Chart $chartNumber/$($chartDirs.Count): $CHART_DIR"
    Write-ColorOutput Blue "======================================================="
    Write-Output ""
    
    try {
        # Lint do chart
        if (-not $SkipLint) {
            Write-ColorOutput Yellow "Validando chart..."
            $lintOutput = helm lint $CHART_DIR 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-ColorOutput Red "Aviso: Lint do chart falhou"
                Write-ColorOutput Yellow "Continuando mesmo com erros de lint..."
            } else {
                Write-ColorOutput Green "Chart validado com sucesso!"
            }
        } else {
            Write-ColorOutput Gray "Pulando validacao (--SkipLint)"
        }
        Write-Output ""
        
        # Obter versao do chart
        $chartYaml = Get-Content "$CHART_DIR\Chart.yaml" -Raw
        if ($chartYaml -match '\nversion:\s*(.+)') {
            $CHART_VERSION = $matches[1].Trim()
        } else {
            throw "Nao foi possivel encontrar a versao no Chart.yaml"
        }
        
        if ($chartYaml -match '\nname:\s*(.+)') {
            $CHART_NAME = $matches[1].Trim()
        } else {
            $CHART_NAME = $CHART_DIR
        }
        
        Write-ColorOutput Cyan "Nome: $CHART_NAME"
        Write-ColorOutput Cyan "Versao: $CHART_VERSION"
        Write-Output ""
        
        # Verificar se a versao ja existe
        $packagePath = Join-Path $CHARTS_OUTPUT "$CHART_NAME-$CHART_VERSION.tgz"
        if (Test-Path $packagePath) {
            if (-not $Force) {
                Write-ColorOutput Yellow "Versao $CHART_VERSION ja existe. Pulando..."
                Write-Output ""
                $chartNumber++
                continue
            } else {
                Write-ColorOutput Yellow "Versao $CHART_VERSION ja existe. Sobrescrevendo..."
                Remove-Item $packagePath -Force
            }
        }
        
        # Empacotar o chart
        Write-ColorOutput Yellow "Empacotando chart..."
        $packageOutput = helm package $CHART_DIR -d $CHARTS_OUTPUT 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Erro ao empacotar o chart"
        }
        Write-ColorOutput Green "Chart empacotado: $CHART_NAME-$CHART_VERSION.tgz"
        Write-Output ""
        
        # Adicionar aos charts publicados
        $publishedCharts += @{
            Name = $CHART_NAME
            Version = $CHART_VERSION
            Directory = $CHART_DIR
        }
        
    } catch {
        Write-ColorOutput Red "Erro ao processar chart $CHART_DIR : $($_.Exception.Message)"
        Write-Output ""
        
        $failedCharts += @{
            Name = $CHART_DIR
            Error = $_.Exception.Message
        }
    }
    
    $chartNumber++
}

# Atualizar indice do repositorio se houver charts publicados
if ($publishedCharts.Count -gt 0) {
    Write-ColorOutput Blue "======================================================="
    Write-ColorOutput Yellow "Atualizando indice do repositorio..."
    Write-ColorOutput Blue "======================================================="
    Write-Output ""
    
    $originalLocation = Get-Location
    Set-Location ../..
    
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
}

# Relatorio final
Write-ColorOutput Blue "======================================================="
Write-ColorOutput Blue "   Relatorio de Publicacao"
Write-ColorOutput Blue "======================================================="
Write-Output ""

if ($publishedCharts.Count -gt 0) {
    Write-ColorOutput Green "Charts publicados com sucesso ($($publishedCharts.Count)):"
    foreach ($chart in $publishedCharts) {
        Write-Output "  - $($chart.Name) v$($chart.Version) ($($chart.Directory))"
    }
    Write-Output ""
}

if ($failedCharts.Count -gt 0) {
    Write-ColorOutput Red "Charts com erro ($($failedCharts.Count)):"
    foreach ($chart in $failedCharts) {
        Write-Output "  - $($chart.Name): $($chart.Error)"
    }
    Write-Output ""
}

if ($publishedCharts.Count -eq 0) {
    Write-ColorOutput Yellow "Nenhum chart foi publicado."
    Write-Output ""
    exit 0
}

# Proximos passos
Write-ColorOutput Yellow "Proximos passos:"
Write-Output ""
Write-Output "  1. Fazer commit das mudancas:"
Write-ColorOutput Green "     git add charts/"
if ($publishedCharts.Count -eq 1) {
    $chart = $publishedCharts[0]
    Write-ColorOutput Green "     git commit -m `"chore: publish helm chart $($chart.Name) v$($chart.Version)`""
} else {
    Write-ColorOutput Green "     git commit -m `"chore: publish $($publishedCharts.Count) helm charts`""
}
Write-Output ""
Write-Output "  2. Fazer push para o repositorio:"
Write-ColorOutput Green "     git push origin main"
Write-Output ""
Write-ColorOutput Yellow "Apos o push, os charts estarao disponiveis em:"
Write-Output ""
Write-Output "  # Adicionar o repositorio"
Write-ColorOutput Green "  helm repo add fexdelux $REPO_URL"
Write-Output ""
Write-Output "  # Atualizar indices"
Write-ColorOutput Green "  helm repo update"
Write-Output ""
Write-Output "  # Listar charts disponiveis"
Write-ColorOutput Green "  helm search repo fexdelux"
Write-Output ""
Write-Output "  # Instalar um chart"
foreach ($chart in $publishedCharts) {
    Write-ColorOutput Green "  helm install my-$($chart.Name) fexdelux/$($chart.Name) --version $($chart.Version)"
}
Write-Output ""
Write-ColorOutput Blue "======================================================="

# Salvar relatorio em JSON
$report = @{
    Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    PublishedCount = $publishedCharts.Count
    FailedCount = $failedCharts.Count
    Published = $publishedCharts
    Failed = $failedCharts
}

$reportPath = "publish-report.json"
$report | ConvertTo-Json -Depth 10 | Out-File $reportPath -Encoding UTF8
Write-ColorOutput Gray "Relatorio salvo em: $reportPath"
