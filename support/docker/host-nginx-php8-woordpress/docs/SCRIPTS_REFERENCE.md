# Quick Reference - Scripts Disponiveis

## Scripts PowerShell

### 1. generate-ssl-cert.ps1
Gera certificados SSL autoassinados para desenvolvimento local.

```powershell
.\generate-ssl-cert.ps1
```

**Quando usar:** Primeira vez que for rodar o projeto localmente ou quando os certificados expirarem.

---

### 2. test-wordpress.ps1
Executa suite de testes para validar o ambiente WordPress.

```powershell
.\test-wordpress.ps1
```

**Testa:**
- Containers rodando
- Certificados SSL
- HTTP/2 suportado
- PHP funcionando
- MySQL conectividade
- Redis conectividade

---

### 3. publish-registry.ps1
Faz build e publica a imagem no Docker Registry privado.

```powershell
# Publicacao padrao
.\publish-registry.ps1 -Version "1.0.0"

# Simular sem executar
.\publish-registry.ps1 -Version "1.0.0" -DryRun

# Pular testes
.\publish-registry.ps1 -Version "1.0.0" -SkipTests

# Registry customizado
.\publish-registry.ps1 -Version "1.0.0" -Registry "myregistry.com"
```

**Quando usar:** Para publicar nova versao da imagem no registry privado.

---

### 4. publish.ps1 (Helm Chart)
Publica o Helm Chart no repositorio GitHub Pages.

```powershell
cd biend-wordpress-basic
..\publish.ps1

# Forcar sobrescrever
..\publish.ps1 -Force
```

**Quando usar:** Apos atualizar o Helm Chart e querer publicar no repositorio.

---

## Fluxo de Trabalho Completo

### Desenvolvimento Local
```powershell
# 1. Gerar certificados SSL
.\generate-ssl-cert.ps1

# 2. Subir ambiente
docker compose up -d

# 3. Testar
.\test-wordpress.ps1

# 4. Desenvolver...

# 5. Parar ambiente
docker compose down
```

### Publicar Nova Versao
```powershell
# 1. Testar localmente primeiro
docker compose up -d
.\test-wordpress.ps1

# 2. Simular publicacao
.\publish-registry.ps1 -Version "1.0.0" -DryRun

# 3. Publicar imagem
.\publish-registry.ps1 -Version "1.0.0"

# 4. Atualizar Helm Chart (se necessario)
# Editar biend-wordpress-basic/values.yaml
# Editar biend-wordpress-basic/Chart.yaml (version)

# 5. Publicar Helm Chart
cd biend-wordpress-basic
..\publish.ps1
```

---

## Arquivos Importantes

- **docker-compose.yml** - Configuracao para desenvolvimento local
- **Dockerfile** - Build da imagem
- **nginx-wordpress.conf** - Configuracao Nginx com HTTP/2
- **php-fpm-www.conf** - Configuracao PHP-FPM
- **docker-entrypoint.sh** - Script de inicializacao do container
- **build-info.json** - Info da ultima build (gerado automaticamente)

---

## URLs de Acesso Local

- **HTTP:** http://localhost:8080 (redireciona para HTTPS)
- **HTTPS:** https://localhost:8443
- **WordPress Admin:** https://localhost:8443/wp-admin

---

## Troubleshooting

### Certificados SSL invalidos
```powershell
Remove-Item ssl/* -Force
.\generate-ssl-cert.ps1
docker compose restart
```

### Containers nao sobem
```powershell
docker compose down
docker compose up -d
docker compose logs -f
```

### Erro de permissao no registry
```powershell
docker login registry.biend.com.br
```

### Resetar ambiente completo
```powershell
docker compose down -v
Remove-Item ssl/* -Force
.\generate-ssl-cert.ps1
docker compose up -d --build
```
