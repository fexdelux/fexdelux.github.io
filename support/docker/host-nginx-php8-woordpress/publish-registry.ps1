# Script PowerShell para build e publish no Docker Registry
# Uso: .\publish-registry.ps1 -Version "1.0.0"

param(
    [Parameter(Mandatory=$false)]
    [string]$Version = "1.0.0",
    
    [Parameter(Mandatory=$false)]
    [string]$Registry = "registry.biend.com.br",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageName = "wordpress-nginx-php8",
    
    [switch]$SkipBuild = $false,
    [switch]$SkipTests = $false,
    [switch]$DryRun = $false
)

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
Write-ColorOutput Blue "   Build e Publish - Docker Registry"
Write-ColorOutput Blue "======================================================="
Write-Output ""
Write-ColorOutput Cyan "Registry: $Registry"
Write-ColorOutput Cyan "Image:    $ImageName"
Write-ColorOutput Cyan "Version:  $Version"
if ($DryRun) {
    Write-ColorOutput Yellow "Modo:     DRY RUN (simulacao)"
}
Write-Output ""

# Validar versao semantica
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    Write-ColorOutput Red "Erro: Versao invalida. Use formato semantico: X.Y.Z (ex: 1.0.0)"
    exit 1
}

# Definir tags
$TAG_VERSION = "${Registry}/${ImageName}:${Version}"
$TAG_LATEST = "${Registry}/${ImageName}:latest"
$TAG_ALPINE = "${Registry}/${ImageName}:alpine"

Write-ColorOutput Yellow "Tags que serao criadas:"
Write-Output "  - $TAG_VERSION"
Write-Output "  - $TAG_LATEST"
Write-Output "  - $TAG_ALPINE"
Write-Output ""

# Etapa 1: Verificar certificados SSL
Write-ColorOutput Yellow "Etapa 1: Verificando certificados SSL..."
if (-not (Test-Path "ssl/tls.crt") -or -not (Test-Path "ssl/tls.key")) {
    Write-ColorOutput Yellow "  Certificados SSL nao encontrados. Gerando..."
    if (-not $DryRun) {
        & .\generate-ssl-cert.ps1
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput Red "Erro ao gerar certificados SSL"
            exit 1
        }
    } else {
        Write-ColorOutput Gray "  [DRY RUN] Pulando geracao de certificados"
    }
} else {
    Write-ColorOutput Green "  Certificados SSL encontrados"
}
Write-Output ""

# Etapa 2: Build da imagem
if (-not $SkipBuild) {
    Write-ColorOutput Yellow "Etapa 2: Build da imagem Docker..."
    if (-not $DryRun) {
        docker build -t $TAG_VERSION .
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput Red "Erro no build da imagem"
            exit 1
        }
        Write-ColorOutput Green "  Build concluido com sucesso!"
    } else {
        Write-ColorOutput Gray "  [DRY RUN] docker build -t $TAG_VERSION ."
    }
} else {
    Write-ColorOutput Gray "  Pulando build (--SkipBuild)"
}
Write-Output ""

# Etapa 3: Testes basicos
if (-not $SkipTests) {
    Write-ColorOutput Yellow "Etapa 3: Executando testes basicos..."
    if (-not $DryRun) {
        # Verificar se a imagem existe
        $searchPattern = "${ImageName}:${Version}"
        $imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern $searchPattern
        if (-not $imageExists) {
            Write-ColorOutput Red "Erro: Imagem nao encontrada apos build"
            exit 1
        }
        
        # Teste rapido: iniciar container e verificar se sobe
        Write-ColorOutput Gray "  Testando container..."
        docker run --rm -d --name test-wordpress-build $TAG_VERSION > $null
        Start-Sleep -Seconds 5
        
        $containerRunning = docker ps --filter "name=test-wordpress-build" --format "{{.Names}}"
        if ($containerRunning) {
            Write-ColorOutput Green "  Container iniciou com sucesso"
            docker stop test-wordpress-build > $null
        } else {
            Write-ColorOutput Red "  Erro: Container nao iniciou"
            exit 1
        }
    } else {
        Write-ColorOutput Gray "  [DRY RUN] Pulando testes"
    }
} else {
    Write-ColorOutput Gray "  Pulando testes (--SkipTests)"
}
Write-Output ""

# Etapa 4: Criar tags adicionais
Write-ColorOutput Yellow "Etapa 4: Criando tags adicionais..."
if (-not $DryRun) {
    docker tag $TAG_VERSION $TAG_LATEST
    docker tag $TAG_VERSION $TAG_ALPINE
    Write-ColorOutput Green "  Tags criadas com sucesso"
} else {
    Write-ColorOutput Gray "  [DRY RUN] docker tag $TAG_VERSION $TAG_LATEST"
    Write-ColorOutput Gray "  [DRY RUN] docker tag $TAG_VERSION $TAG_ALPINE"
}
Write-Output ""

# Etapa 5: Login no registry
Write-ColorOutput Yellow "Etapa 5: Login no Docker Registry..."
if (-not $DryRun) {
    Write-Host "Entre com as credenciais do registry $Registry" -ForegroundColor Cyan
    docker login $Registry
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "Erro no login do registry"
        exit 1
    }
    Write-ColorOutput Green "  Login realizado com sucesso"
} else {
    Write-ColorOutput Gray "  [DRY RUN] docker login $Registry"
}
Write-Output ""

# Etapa 6: Push das imagens
Write-ColorOutput Yellow "Etapa 6: Publicando imagens no registry..."
if (-not $DryRun) {
    Write-ColorOutput Cyan "  Enviando $TAG_VERSION..."
    docker push $TAG_VERSION
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "Erro ao publicar versao $Version"
        exit 1
    }
    
    Write-ColorOutput Cyan "  Enviando $TAG_LATEST..."
    docker push $TAG_LATEST
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "Erro ao publicar tag latest"
        exit 1
    }
    
    Write-ColorOutput Cyan "  Enviando $TAG_ALPINE..."
    docker push $TAG_ALPINE
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "Erro ao publicar tag alpine"
        exit 1
    }
    
    Write-ColorOutput Green "  Todas as imagens publicadas com sucesso!"
} else {
    Write-ColorOutput Gray "  [DRY RUN] docker push $TAG_VERSION"
    Write-ColorOutput Gray "  [DRY RUN] docker push $TAG_LATEST"
    Write-ColorOutput Gray "  [DRY RUN] docker push $TAG_ALPINE"
}
Write-Output ""

# Etapa 7: Verificar imagens no registry
Write-ColorOutput Yellow "Etapa 7: Verificando publicacao..."
if (-not $DryRun) {
    Write-ColorOutput Green "  Imagens disponiveis no registry:"
    Write-Output "    - ${Registry}/${ImageName}:${Version}"
    Write-Output "    - ${Registry}/${ImageName}:latest"
    Write-Output "    - ${Registry}/${ImageName}:alpine"
} else {
    Write-ColorOutput Gray "  [DRY RUN] Verificacao de publicacao"
}
Write-Output ""

# Summary
Write-ColorOutput Blue "======================================================="
Write-ColorOutput Green "   Publicacao Concluida com Sucesso!"
Write-ColorOutput Blue "======================================================="
Write-Output ""
Write-ColorOutput Yellow "Para usar a imagem publicada:"
Write-Output ""
Write-ColorOutput Cyan "  # Pull da imagem"
Write-ColorOutput White "  docker pull ${Registry}/${ImageName}:${Version}"
Write-Output ""
Write-ColorOutput Cyan "  # Ou usar a versao latest"
Write-ColorOutput White "  docker pull ${Registry}/${ImageName}:latest"
Write-Output ""
Write-ColorOutput Cyan "  # Executar container"
Write-ColorOutput White "  docker run -d -p 8080:80 -p 8443:443 ${Registry}/${ImageName}:${Version}"
Write-Output ""
Write-ColorOutput Yellow "Proximos passos sugeridos:"
Write-Output "  1. Atualizar docker-compose.yml para usar a imagem do registry"
Write-Output "  2. Atualizar Helm Chart values.yaml com a nova versao"
Write-Output "  3. Fazer deploy no Kubernetes"
Write-Output ""
Write-ColorOutput Blue "======================================================="

# Criar arquivo com informacoes da build
if (-not $DryRun) {
    $buildInfo = @{
        Version = $Version
        Registry = $Registry
        ImageName = $ImageName
        Tags = @($TAG_VERSION, $TAG_LATEST, $TAG_ALPINE)
        BuildDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        GitCommit = (git rev-parse --short HEAD 2>$null)
    }
    
    $buildInfo | ConvertTo-Json | Out-File "build-info.json" -Encoding UTF8
    Write-ColorOutput Gray "Informacoes da build salvas em: build-info.json"
}
