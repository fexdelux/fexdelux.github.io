# Permissões com NFS Storage

## Problema Comum

Ao usar NFS (nfs-subdir-external-provisioner) no Kubernetes, operações de `chown` geralmente falham devido ao `root_squash` do NFS, causando problemas de permissão nos arquivos do WordPress.

## Solução Implementada

Este chart usa uma abordagem **NFS-friendly** para gerenciar permissões:

### 1. fsGroup no Kubernetes
```yaml
securityContext:
  fsGroup: 82  # nginx user no Alpine Linux
  fsGroupChangePolicy: "OnRootMismatch"
```

O Kubernetes gerencia automaticamente o **ownership** dos arquivos através do `fsGroup`, mapeando todos os arquivos para o GID 82 (nginx).

### 2. InitContainer
O initContainer **não tenta fazer chown**, apenas ajusta **permissões** (chmod):
- Diretórios: `775` (rwxrwxr-x)
- Arquivos: `664` (rw-rw-r--)

Isso permite que o grupo (nginx) tenha permissão de leitura e escrita.

### 3. Entrypoint do Container
O entrypoint também foi ajustado para trabalhar com NFS:
- Remove `SKIP_CHOWN=true` do deployment
- Usa apenas `chmod`, não `chown`
- Permissões 775/664 para compatibilidade com grupo

## Configuração do NFS Server

Para melhor compatibilidade, configure o export NFS com:

```bash
# /etc/exports
/storages/storage01  192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
```

**Nota:** `no_root_squash` permite que o root do container mantenha privilégios, mas não é obrigatório com nossa configuração.

## Permissões Recomendadas

### Para Storage NFS:
```bash
# No servidor NFS
chown -R 82:82 /storages/storage01
chmod -R 775 /storages/storage01
```

### UID/GID Mapping:
- **Alpine nginx**: UID=82, GID=82
- **Debian www-data**: UID=33, GID=33 (não usado)

## Troubleshooting

### WordPress não consegue escrever arquivos:
```bash
# Verificar permissões dentro do pod
kubectl exec -it <pod-name> -n <namespace> -- ls -la /var/www/html

# Verificar fsGroup aplicado
kubectl get pod <pod-name> -n <namespace> -o jsonpath='{.spec.securityContext}'

# Forçar reajuste de permissões
kubectl delete pod -l app.kubernetes.io/component=wordpress -n <namespace>
```

### Erro "Permission denied" no NFS:
```bash
# No servidor NFS, verificar export
showmount -e localhost

# Verificar logs do NFS
journalctl -u nfs-server -f

# Testar montagem manual
mount -t nfs <nfs-server>:/storages/storage01 /mnt/test
```

### Verificar UID/GID no container:
```bash
kubectl exec -it <pod-name> -n <namespace> -- sh
id nginx
# Deve mostrar: uid=82(nginx) gid=82(nginx)

ls -ln /var/www/html
# Deve mostrar: 82 82 (ownership via fsGroup)
```

## Alternativas ao NFS

Se problemas de permissão persistirem, considere:

1. **Longhorn** - Block storage nativo para Kubernetes
2. **Rook/Ceph** - Distributed storage
3. **Local Path Provisioner** - Para desenvolvimento/single-node
4. **Cloud Provider Storage** - EBS, Azure Disk, etc.

## Backup de Dados

Com NFS, backup é simples:

```bash
# No servidor NFS
tar -czf wordpress-backup-$(date +%F).tar.gz /storages/storage01/<namespace>-<pvc-name>
```

## Referências

- [Kubernetes Security Context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- [NFS Best Practices](https://kubernetes.io/docs/concepts/storage/volumes/#nfs)
- [Alpine Linux nginx user](https://wiki.alpinelinux.org/wiki/Nginx)
