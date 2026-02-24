# Guia Rapido de Publicacao no Registry

## Uso Basico

### 1. Publicar versao especifica
```powershell
.\publish-registry.ps1 -Version "1.0.0"
```

### 2. Publicar com outra versao
```powershell
.\publish-registry.ps1 -Version "1.2.5"
```

### 3. Usar registry customizado
```powershell
.\publish-registry.ps1 -Version "1.0.0" -Registry "myregistry.com"
```

### 4. Simular publicacao (Dry Run)
```powershell
.\publish-registry.ps1 -Version "1.0.0" -DryRun
```

## Opcoes Avancadas

### Pular build (usar imagem ja existente)
```powershell
.\publish-registry.ps1 -Version "1.0.0" -SkipBuild
```

### Pular testes
```powershell
.\publish-registry.ps1 -Version "1.0.0" -SkipTests
```

### Todas as opcoes combinadas
```powershell
.\publish-registry.ps1 `
    -Version "2.0.0" `
    -Registry "registry.biend.com.br" `
    -ImageName "wordpress-nginx-php8" `
    -SkipTests
```

## Parametros

- **Version**: Versao da imagem (formato semantico X.Y.Z)
- **Registry**: URL do registry (padrao: registry.biend.com.br)
- **ImageName**: Nome da imagem (padrao: wordpress-nginx-php8)
- **SkipBuild**: Pula etapa de build
- **SkipTests**: Pula testes basicos
- **DryRun**: Simula execucao sem fazer alteracoes

## Fluxo de Publicacao

O script executa as seguintes etapas:

1. **Verificacao de certificados SSL** - Gera se nao existir
2. **Build da imagem** - Compila a imagem Docker
3. **Testes basicos** - Valida se o container inicia
4. **Criacao de tags** - Cria tags: version, latest, alpine
5. **Login no registry** - Autentica no registry
6. **Push das imagens** - Envia todas as tags
7. **Verificacao** - Confirma publicacao

## Tags Criadas

Para versao 1.0.0, sao criadas:
- `registry.biend.com.br/wordpress-nginx-php8:1.0.0`
- `registry.biend.com.br/wordpress-nginx-php8:latest`
- `registry.biend.com.br/wordpress-nginx-php8:alpine`

## Usando Imagem Publicada

### No Docker Compose
```yaml
services:
  wordpress:
    image: registry.biend.com.br/wordpress-nginx-php8:1.0.0
    # ... resto da configuracao
```

### No Kubernetes/Helm
```yaml
image:
  repository: registry.biend.com.br/wordpress-nginx-php8
  tag: "1.0.0"
  pullPolicy: IfNotPresent
```

### Pull Manual
```bash
docker pull registry.biend.com.br/wordpress-nginx-php8:1.0.0
```

## Troubleshooting

### Erro de autenticacao no registry
```powershell
# Fazer login manualmente primeiro
docker login registry.biend.com.br
```

### Versao ja existe no registry
Use uma versao nova seguindo versionamento semantico:
- Patch: 1.0.0 -> 1.0.1 (bugfixes)
- Minor: 1.0.0 -> 1.1.0 (novas features)
- Major: 1.0.0 -> 2.0.0 (breaking changes)

### Build info gerado
Apos publicacao bem-sucedida, o arquivo `build-info.json` contem:
- Versao publicada
- Registry utilizado
- Tags criadas
- Data do build
- Git commit hash
