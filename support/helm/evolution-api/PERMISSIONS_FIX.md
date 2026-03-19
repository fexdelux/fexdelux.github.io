# SoluÃ§Ã£o para Problemas de PermissÃ£o no PostgreSQL/Redis

## Problema

Ao instalar o chart Evolution API em ambientes Kubernetes com certos tipos de storage (especialmente **NFS**, **Ceph**, **GlusterFS** ou clusters com **PSP/PSA** estritas), os pods do PostgreSQL e/ou Redis podem falhar com:

```
chown: changing ownership of '/var/lib/postgresql/data/pgdata': Operation not permitted
```

**Status dos Pods:**
```bash
NAME                                                READY   STATUS             RESTARTS
pod/evo-evolution-api-postgresql-777c88985f-xxx     0/1     CrashLoopBackOff   2 (14s ago)
pod/evo-evolution-api-redis-855cf4b4f9-xxx          0/1     CrashLoopBackOff   1 (10s ago)
```

## Causa

1. **Storage com suporte limitado a chown**: Alguns storages (especialmente NFS) nÃ£o permitem que containers alterem ownership de arquivos
2. **UIDs/GIDs incompatÃ­veis**: O volume pode ter sido criado com permissÃµes diferentes do UID/GID esperado pelo container
3. **PolÃ­ticas de seguranÃ§a**: Clusters com PSP/PSA podem restringir operaÃ§Ãµes de mudanÃ§a de ownership

## SoluÃ§Ã£o Implementada âœ…

O chart agora inclui **3 mecanismos** de proteÃ§Ã£o:

### 1. **SecurityContext no Pod** (`fsGroup`)
Define o GID do grupo que terÃ¡ acesso aos volumes:
```yaml
securityContext:
  fsGroup: 999  # PostgreSQL/Redis GID
  fsGroupChangePolicy: "OnRootMismatch"  # SÃ³ muda quando necessÃ¡rio
```

### 2. **InitContainer para Ajustar PermissÃµes**
Container privilegiado que executa antes do principal para corrigir permissÃµes:
```yaml
initContainers:
- name: init-chmod-data
  image: busybox:latest
  command:
  - sh
  - -c
  - |
    chown -R 999:999 /var/lib/postgresql/data || true
    chmod 700 /var/lib/postgresql/data || true
  securityContext:
    runAsUser: 0  # Root
```

### 3. **ContainerSecurityContext**
Garante que o container principal execute com o UID correto:
```yaml
containerSecurityContext:
  runAsUser: 999
  runAsNonRoot: true
  allowPrivilegeEscalation: false
```

## Como Usar

### OpÃ§Ã£o 1: Usar configuraÃ§Ã£o padrÃ£o (Recomendado)

As configuraÃ§Ãµes jÃ¡ estÃ£o **habilitadas por padrÃ£o** no `values.yaml`:

```bash
helm install evolution-api fexdelux/evolution-api
```

### OpÃ§Ã£o 2: Desabilitar em ambientes sem restriÃ§Ãµes

Se seu ambiente **nÃ£o tem problemas de permissÃ£o**, vocÃª pode desabilitar:

```bash
helm install evolution-api fexdelux/evolution-api \
  --set postgresql.securityContext.enabled=false \
  --set postgresql.initContainer.enabled=false \
  --set redis.securityContext.enabled=false \
  --set redis.initContainer.enabled=false
```

### OpÃ§Ã£o 3: Customizar UIDs/GIDs

Para ambientes com UIDs/GIDs especÃ­ficos:

```bash
helm install evolution-api fexdelux/evolution-api \
  --set postgresql.securityContext.fsGroup=1000 \
  --set postgresql.securityContext.runAsUser=1000 \
  --set postgresql.containerSecurityContext.runAsUser=1000
```

## ConfiguraÃ§Ãµes DisponÃ­veis

### PostgreSQL

```yaml
postgresql:
  securityContext:
    enabled: true                          # Ativar/desativar fsGroup
    fsGroup: 999                           # GID do grupo (padrÃ£o: postgres)
    fsGroupChangePolicy: "OnRootMismatch"  # Quando aplicar permissÃµes
    runAsUser: 999                         # UID do usuÃ¡rio
  
  containerSecurityContext:
    enabled: true          # SecurityContext do container
    runAsUser: 999         # UID do processo
    runAsNonRoot: true     # NÃ£o permitir root
  
  initContainer:
    enabled: true              # Ativar initContainer
    image: busybox:latest      # Imagem do initContainer
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

## ValidaÃ§Ã£o

ApÃ³s atualizar o chart:

```bash
# 1. Fazer upgrade
helm upgrade evolution-api fexdelux/evolution-api

# 2. Verificar pods
kubectl get pods -l app.kubernetes.io/instance=evolution-api

# 3. Verificar logs (se ainda houver erro)
kubectl logs <pod-postgresql-name> -c init-chmod-data
kubectl logs <pod-postgresql-name> -c postgresql
```

## Troubleshooting

### InitContainer falha com "Operation not permitted"

**Causa**: O storage nÃ£o permite chown mesmo com root.

**SoluÃ§Ã£o**: Use `storageClass` com suporte a `fsGroup` ou desabilite o initContainer:
```bash
--set postgresql.initContainer.enabled=false
```

### Pod ainda falha apÃ³s aplicar a soluÃ§Ã£o

1. **Verifique o storageClass**:
   ```bash
   kubectl get storageclass -o yaml | grep -A 5 volumeBindingMode
   ```

2. **Verifique as permissÃµes do PV**:
   ```bash
   kubectl get pv
   kubectl describe pv <pv-name>
   ```

3. **Delete e recrie o PVC** (âš ï¸ CUIDADO: isso apaga os dados):
   ```bash
   kubectl delete pvc evolution-api-postgresql
   helm upgrade evolution-api fexdelux/evolution-api
   ```

### NFS especÃ­fico

Para NFS, adicione ao PV/StorageClass:

```yaml
mountOptions:
  - nfsvers=4.1
  - rw
  - sync
  - no_root_squash  # Permite root no NFS
```

## Ambientes Testados

âœ… **GKE** (Google Kubernetes Engine) - funciona com configuraÃ§Ã£o padrÃ£o  
âœ… **EKS** (Amazon EKS) - funciona com configuraÃ§Ã£o padrÃ£o  
âœ… **AKS** (Azure Kubernetes) - funciona com configuraÃ§Ã£o padrÃ£o  
âœ… **NFS** - funciona com `initContainer.enabled=true` + `no_root_squash`  
âœ… **Longhorn** - funciona com configuraÃ§Ã£o padrÃ£o  
âš ï¸ **Ceph RBD** - pode precisar de `fsGroupChangePolicy: "Always"`

## ReferÃªncias

- [Kubernetes Volume Permissions](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [PostgreSQL Container User](https://hub.docker.com/_/postgres)
- [FSGroup Policy](https://kubernetes.io/blog/2020/12/14/kubernetes-release-1.20-fsgroupchangepolicy-fsgrouppolicy/)
