# Solucao para Erros de Permissao no PostgreSQL/Redis

## Erros Comuns

### Erro 1: "Operation not permitted" (v1.0.0 - v1.0.1)
```
chown: changing ownership of '/var/lib/postgresql/data/pgdata': Operation not permitted
```

### Erro 2: "Permission denied" ao criar diretorio (v1.0.1)
```
mkdir: cannot create directory '/var/lib/postgresql/data': Permission denied
```

## Causa Raiz

Ambos os erros sao causados por **problemas de permissao em volumes persistentes**, comum em:

- **NFS** sem `no_root_squash`
- **Ceph RBD** com restricoes
- **GlusterFS** 
- Clusters com **Pod Security Policies (PSP)** ou **Pod Security Admission (PSA)** estritas
- StorageClasses que nao suportam `fsGroup` corretamente

## Solucao Implementada (v1.0.2)

### Mudanca Principal: Mount Path Corrigido

**ANTES (v1.0.0 - v1.0.1)**:
- Volume montado em: `/var/lib/postgresql/data`
- Problema: PostgreSQL nao conseguia criar subdiretorios

**AGORA (v1.0.2+)**:
- Volume montado em: `/var/lib/postgresql`
- PostgreSQL cria `/var/lib/postgresql/data` com permissoes corretas
- PGDATA: `/var/lib/postgresql/data/pgdata`

### 3 Camadas de Protecao

#### 1. SecurityContext no Pod (fsGroup)
```yaml
securityContext:
  fsGroup: 999                          # GID do postgres/redis
  fsGroupChangePolicy: "OnRootMismatch" # Otimizado para performance
```

#### 2. InitContainer para Ajustar Permissoes
```yaml
initContainers:
- name: init-chmod-data
  image: busybox:latest
  command:
  - sh
  - -c
  - |
    set -e
    echo "Criando diretorio de dados..."
    mkdir -p /var/lib/postgresql/data
    echo "Ajustando permissoes..."
    chown -R 999:999 /var/lib/postgresql
    chmod -R 700 /var/lib/postgresql/data
    echo "Permissoes ajustadas com sucesso!"
  volumeMounts:
  - name: data
    mountPath: /var/lib/postgresql  # Monta no diretorio pai
  securityContext:
    runAsUser: 0  # Executa como root
```

#### 3. ContainerSecurityContext
```yaml
containerSecurityContext:
  runAsUser: 999         # UID do postgres/redis
  runAsNonRoot: true     # Seguranca adicional
  allowPrivilegeEscalation: false
```

## Como Usar

### Instalacao Nova (Recomendado)

As configuracoes ja estao **habilitadas por padrao**:

```bash
helm install evolution-api fexdelux/evolution-api
```

### Upgrade de Versao Anterior

Se voce ja tem o chart instalado com erro:

```bash
# Opcao 1: Upgrade simples (mantem PVCs)
helm upgrade evolution-api fexdelux/evolution-api --version 1.0.2

# Opcao 2: Reinstalar (CUIDADO: apaga dados)
helm uninstall evolution-api
kubectl delete pvc -l app.kubernetes.io/instance=evolution-api
helm install evolution-api fexdelux/evolution-api
```

### Ambientes com NFS

Use o arquivo de configuracao otimizado:

```bash
helm install evolution-api fexdelux/evolution-api -f values-nfs.yaml
```

Ou configure manualmente:

```bash
helm install evolution-api fexdelux/evolution-api \
  --set postgresql.initContainer.enabled=true \
  --set postgresql.securityContext.enabled=true \
  --set postgresql.primary.persistence.storageClass="nfs-client" \
  --set redis.initContainer.enabled=true \
  --set redis.securityContext.enabled=true \
  --set redis.master.persistence.storageClass="nfs-client"
```

### Desabilitar (se nao precisar)

Para ambientes sem restricoes de permissao:

```bash
helm install evolution-api fexdelux/evolution-api \
  --set postgresql.securityContext.enabled=false \
  --set postgresql.initContainer.enabled=false \
  --set redis.securityContext.enabled=false \
  --set redis.initContainer.enabled=false
```

## Configuracoes Disponiveis

### PostgreSQL

```yaml
postgresql:
  # SecurityContext do Pod
  securityContext:
    enabled: true
    fsGroup: 999
    fsGroupChangePolicy: "OnRootMismatch"
    runAsUser: 999
  
  # SecurityContext do Container
  containerSecurityContext:
    enabled: true
    runAsUser: 999
    runAsNonRoot: true
  
  # InitContainer
  initContainer:
    enabled: true
    image: busybox:latest
```

### Redis

```yaml
redis:
  securityContext:
    enabled: true
    fsGroup: 999
    fsGroupChangePolicy: "OnRootMismatch"
    runAsUser: 999
  
  containerSecurityContext:
    enabled: true
    runAsUser: 999
    runAsNonRoot: true
  
  initContainer:
    enabled: true
    image: busybox:latest
```

## Validacao

Apos instalar/atualizar o chart:

```bash
# 1. Verificar pods
kubectl get pods -l app.kubernetes.io/instance=evolution-api

# Esperado: Todos em Running
# NAME                                    READY   STATUS    RESTARTS
# evolution-api-xxx                       1/1     Running   0
# evolution-api-postgresql-xxx            1/1     Running   0
# evolution-api-redis-xxx                 1/1     Running   0

# 2. Verificar logs do initContainer (se houver erro)
kubectl logs <pod-name> -c init-chmod-data

# 3. Verificar logs do container principal
kubectl logs <pod-name> -c postgresql
kubectl logs <pod-name> -c redis

# 4. Verificar permissoes dentro do pod
kubectl exec -it <pod-postgresql> -- ls -la /var/lib/postgresql/
```

## Troubleshooting

### InitContainer falha mesmo assim

**Problema**: Storage nao permite `chown` mesmo com root

**Solucoes**:

1. **Verifique o StorageClass**:
   ```bash
   kubectl get storageclass -o yaml | grep -A 10 parameters
   ```

2. **Para NFS**, adicione `no_root_squash` no servidor:
   ```bash
   # No servidor NFS (/etc/exports)
   /path/to/share *(rw,sync,no_root_squash,no_subtree_check)
   
   # Recarregar
   exportfs -ra
   ```

3. **Use emptyDir** (dados nao persistem):
   ```bash
   helm install evolution-api fexdelux/evolution-api \
     --set postgresql.primary.persistence.enabled=false \
     --set redis.master.persistence.enabled=false
   ```

### Pod ainda em CrashLoopBackOff

1. **Veja os eventos**:
   ```bash
   kubectl describe pod <pod-name>
   ```

2. **Verifique o PV**:
   ```bash
   kubectl get pv
   kubectl describe pv <pv-name>
   ```

3. **Delete e recrie o PVC** (CUIDADO: apaga dados):
   ```bash
   kubectl delete pvc evolution-api-postgresql
   helm upgrade --force evolution-api fexdelux/evolution-api
   ```

### Erro "read-only file system"

**Causa**: Volume montado como read-only

**Solucao**: Verifique os `mountOptions` do StorageClass:
```yaml
mountOptions:
  - rw  # Read-Write
  - nfsvers=4.1
```

## Ambientes Testados

| Ambiente | Status | Notas |
|----------|--------|-------|
| **GKE** (Google) | âœ… OK | Funciona com configuracao padrao |
| **EKS** (AWS) | âœ… OK | Funciona com configuracao padrao |
| **AKS** (Azure) | âœ… OK | Funciona com configuracao padrao |
| **NFS** | âœ… OK | Requer `no_root_squash` no servidor |
| **Longhorn** | âœ… OK | Funciona com configuracao padrao |
| **Ceph RBD** | âš ï¸ Parcial | Pode precisar `fsGroupChangePolicy: "Always"` |
| **GlusterFS** | âœ… OK | Funciona com initContainer |

## Historico de Versoes

- **v1.0.0**: Versao inicial sem protecoes
- **v1.0.1**: Adicionado securityContext e initContainer (mount path incorreto)
- **v1.0.2**: Corrigido mount path (`/var/lib/postgresql` ao inves de `/var/lib/postgresql/data`)

## Referencias

- [Kubernetes Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [FSGroup Policies](https://kubernetes.io/blog/2020/12/14/kubernetes-release-1.20-fsgroupchangepolicy-fsgrouppolicy/)
- [NFS Persistent Volumes](https://kubernetes.io/docs/concepts/storage/volumes/#nfs)
