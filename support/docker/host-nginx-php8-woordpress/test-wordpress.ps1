# Script de teste para validar setup WordPress com HTTP/2 e SSL
# Uso: .\test-wordpress.ps1

Write-Host "=======================================================" -ForegroundColor Blue
Write-Host "   Teste do WordPress com SSL e HTTP/2" -ForegroundColor Blue
Write-Host "=======================================================" -ForegroundColor Blue
Write-Output ""

# Teste 1: Container rodando
Write-Host "Teste 1: Verificando containers..." -ForegroundColor Yellow
$containers = docker compose ps --format json | ConvertFrom-Json
$wpContainer = $containers | Where-Object { $_.Service -eq "wordpress" }

if ($wpContainer.State -eq "running") {
    Write-Host "  WordPress container: RODANDO" -ForegroundColor Green
} else {
    Write-Host "  WordPress container: PARADO" -ForegroundColor Red
    exit 1
}

# Teste 2: Certificado SSL montado
Write-Host "`nTeste 2: Verificando certificados SSL..." -ForegroundColor Yellow
try {
    $certCheck = docker exec wordpress-app sh -c "test -f /etc/nginx/ssl/tls.crt && test -f /etc/nginx/ssl/tls.key && echo OK"
    if ($certCheck -match "OK") {
        Write-Host "  Certificados SSL: OK" -ForegroundColor Green
    } else {
        Write-Host "  Certificados SSL: NAO ENCONTRADOS" -ForegroundColor Red
    }
} catch {
    Write-Host "  Certificados SSL: ERRO" -ForegroundColor Red
}

# Teste 3: Nginx HTTP/2 support
Write-Host "`nTeste 3: Verificando suporte HTTP/2 no Nginx..." -ForegroundColor Yellow
$ErrorActionPreference = "Continue"
$http2Check = docker exec wordpress-app nginx -V  2>&1 | Out-String
$ErrorActionPreference = "Stop"
if ($http2Check -match "http_v2_module") {
    Write-Host "  HTTP/2 module: HABILITADO" -ForegroundColor Green
} else {
    Write-Host "  HTTP/2 module: NAO ENCONTRADO" -ForegroundColor Red
}

# Teste 4: Porta HTTP (80 -> redireciona para HTTPS)
Write-Host "`nTeste 4: Testando redirecionamento HTTP -> HTTPS..." -ForegroundColor Yellow
try {
    $httpResponse = curl -sI http://localhost:8080 2>&1
    $redirect = $httpResponse | Select-String "Location: https://"
    if ($redirect) {
        Write-Host "  Redirecionamento HTTP->HTTPS: OK" -ForegroundColor Green
    } else {
        Write-Host "  Redirecionamento HTTP->HTTPS: FALHOU" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Redirecionamento HTTP->HTTPS: ERRO" -ForegroundColor Red
}

# Teste 5: Porta HTTPS (443)
Write-Host "`nTeste 5: Testando conexao HTTPS..." -ForegroundColor Yellow
try {
    $httpsResponse = curl -Isk https://localhost:8443 2>&1
    $httpStatus = $httpsResponse | Select-String "^HTTP"
    if ($httpStatus) {
        Write-Host "  HTTPS: $($httpStatus)" -ForegroundColor Green
        
        # Verificar headers de seguranca
        $headers = @{
            "X-Frame-Options" = "SAMEORIGIN"
            "X-Content-Type-Options" = "nosniff"
            "X-XSS-Protection" = "1"
        }
        
        Write-Host "`n  Headers de seguranca:" -ForegroundColor Gray
        foreach ($header in $headers.Keys) {
            $found = $httpsResponse | Select-String $header
            if ($found) {
                Write-Host "    $header : OK" -ForegroundColor Green
            } else {
                Write-Host "    $header : Ausente" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  HTTPS: FALHOU" -ForegroundColor Red
    }
} catch {
    Write-Host "  HTTPS: ERRO - $($_.Exception.Message)" -ForegroundColor Red
}

# Teste 6: PHP funcionando
Write-Host "`nTeste 6: Verificando PHP..." -ForegroundColor Yellow
$phpVersion = docker exec wordpress-app php -v 2>&1 | Select-String "^PHP"
if ($phpVersion) {
    Write-Host "  $phpVersion" -ForegroundColor Green
} else {
    Write-Host "  PHP: NAO ENCONTRADO" -ForegroundColor Red
}

# Teste 7: MySQL conectividade
Write-Host "`nTeste 7: Verificando MySQL..." -ForegroundColor Yellow
$mysqlCheck = docker exec wordpress-mysql mysqladmin ping -h localhost -u root -prootpass123 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  MySQL: Respondendo" -ForegroundColor Green
} else {
    Write-Host "  MySQL: Nao responde" -ForegroundColor Red
}

# Teste 8: Redis conectividade
Write-Host "`nTeste 8: Verificando Redis..." -ForegroundColor Yellow
$redisCheck = docker exec wordpress-redis redis-cli -a redispass123 --no-auth-warning ping 2>&1
if ($redisCheck -match "PONG") {
    Write-Host "  Redis: Respondendo (PONG)" -ForegroundColor Green
} else {
    Write-Host "  Redis: Nao responde" -ForegroundColor Red
}

Write-Output ""
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host "   Resumo" -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Blue
Write-Host ""
Write-Host "Acesse o WordPress em:" -ForegroundColor White
Write-Host "  HTTP:  http://localhost:8080 (redireciona para HTTPS)" -ForegroundColor Cyan
Write-Host "  HTTPS: https://localhost:8443" -ForegroundColor Green
Write-Host ""
Write-Host "Nota: Aceite o aviso de certificado autoassinado no navegador" -ForegroundColor Gray
Write-Host "=======================================================" -ForegroundColor Blue
