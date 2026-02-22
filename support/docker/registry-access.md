# Acesso ao Docker Registry

Registry configurado em: `registry.biend.com.br`

## Login no Registry

```bash
docker login registry.biend.com.br
```

## Push de Imagens

### 1. Tag da imagem local
```bash
docker tag sua-imagem:tag registry.biend.com.br/sua-imagem:tag
```

### 2. Push para o registry
```bash
docker push registry.biend.com.br/sua-imagem:tag
```

### Exemplo completo
```bash
# Tag da imagem local
docker tag nginx:latest registry.biend.com.br/nginx:latest

# Push
docker push registry.biend.com.br/nginx:latest
```

## Pull de Imagens

```bash
docker pull registry.biend.com.br/sua-imagem:tag
```

### Exemplo
```bash
docker pull registry.biend.com.br/nginx:latest
```

## Consultas via API

### Listar todas as imagens no registry
```bash
curl https://registry.biend.com.br/v2/_catalog
```

### Listar tags de uma imagem específica
```bash
curl https://registry.biend.com.br/v2/nome-da-imagem/tags/list
```

### Exemplo
```bash
curl https://registry.biend.com.br/v2/nginx/tags/list
```

## Uso com Kubernetes

### Pull de imagem privada em um Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
spec:
  containers:
  - name: app
    image: registry.biend.com.br/my-app:latest
  imagePullSecrets:
  - name: registry-credentials
```

### Criar secret para autenticação (se necessário)
```bash
kubectl create secret docker-registry registry-credentials \
  --docker-server=registry.biend.com.br \
  --docker-username=seu-usuario \
  --docker-password=sua-senha \
  --docker-email=seu-email@example.com \
  --namespace=default
```
