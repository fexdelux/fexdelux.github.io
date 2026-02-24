# Script para gerar certificado SSL autoassinado
# Uso: .\generate-ssl-cert.ps1

$ErrorActionPreference = "Stop"

$SSL_DIR = "ssl"
$CERT_FILE = "$SSL_DIR\tls.crt"
$KEY_FILE = "$SSL_DIR\tls.key"

Write-Host "=======================================================" -ForegroundColor Blue
Write-Host "   Geracao de Certificado SSL Autoassinado" -ForegroundColor Blue
Write-Host "=======================================================" -ForegroundColor Blue
Write-Output ""

# Criar diretorio SSL se nao existir
if (-not (Test-Path $SSL_DIR)) {
    Write-Host "Criando diretorio SSL..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force -Path $SSL_DIR | Out-Null
}

# Verificar se certificado ja existe
if ((Test-Path $CERT_FILE) -and (Test-Path $KEY_FILE)) {
    Write-Host "Certificados ja existem!" -ForegroundColor Yellow
    $response = Read-Host "Deseja gerar novos certificados? (s/N)"
    if ($response -ne 's' -and $response -ne 'S') {
        Write-Host "Operacao cancelada." -ForegroundColor Red
        exit 0
    }
    Write-Host "Removendo certificados antigos..." -ForegroundColor Yellow
    Remove-Item $CERT_FILE -Force
    Remove-Item $KEY_FILE -Force
}

Write-Host "Gerando certificado SSL autoassinado..." -ForegroundColor Green

# Configuracao do certificado
$config = @"
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C = BR
ST = SaoPaulo
L = SaoPaulo
O = Development
OU = WordPress
CN = localhost

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
DNS.3 = wordpress.local
DNS.4 = *.wordpress.local
IP.1 = 127.0.0.1
"@

# Salvar configuracao temporaria
$configFile = "$SSL_DIR\openssl.cnf"
$config | Out-File -FilePath $configFile -Encoding ASCII

# Gerar certificado usando OpenSSL
try {
    $opensslPath = (Get-Command openssl -ErrorAction Stop).Source
    Write-Host "Usando OpenSSL: $opensslPath" -ForegroundColor Gray
    
    & openssl req -x509 -nodes -days 365 -newkey rsa:2048 `
        -keyout $KEY_FILE `
        -out $CERT_FILE `
        -config $configFile
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Certificado SSL gerado com sucesso!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Arquivos gerados:" -ForegroundColor Yellow
        Write-Host "  - Certificado: $CERT_FILE" -ForegroundColor White
        Write-Host "  - Chave privada: $KEY_FILE" -ForegroundColor White
        Write-Host ""
        
        # Mostrar informacoes do certificado
        Write-Host "Informacoes do certificado:" -ForegroundColor Yellow
        & openssl x509 -in $CERT_FILE -noout -subject -issuer -dates
        Write-Host ""
        
        # Remover arquivo de configuracao temporario
        Remove-Item $configFile -Force
        
        Write-Host "=======================================================" -ForegroundColor Blue
        Write-Host "Proximos passos:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1. Os certificados estao em: $SSL_DIR\" -ForegroundColor White
        Write-Host "2. Execute: docker compose up -d --build" -ForegroundColor Green
        Write-Host "3. Acesse: https://localhost:8080" -ForegroundColor Green
        Write-Host ""
        Write-Host "Nota: Seu navegador mostrara um aviso de seguranca" -ForegroundColor Gray
        Write-Host "      (normal para certificados autoassinados)" -ForegroundColor Gray
        Write-Host "=======================================================" -ForegroundColor Blue
    } else {
        throw "Erro ao gerar certificado"
    }
} catch {
    Write-Host "Erro ao gerar certificado SSL!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    if (Test-Path $configFile) {
        Remove-Item $configFile -Force
    }
    exit 1
}
