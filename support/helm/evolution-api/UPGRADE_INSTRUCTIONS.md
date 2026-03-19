# Comandos para Atualizar no Servidor (v1.0.2)

## Problema Corrigido

**Erro**: `mkdir: cannot create directory '/var/lib/postgresql/data': Permission denied`

**Causa**: Mount path incorreto do volume (v1.0.1 montava em `/var/lib/postgresql/data`)

**Solucao**: Mount path corrigido para `/var/lib/postgresql` (v1.0.2)

## Opcao 1: Upgrade com Chart Local

Se voce tem o repositorio clonado localmente:

```bash
# 1. Atualizar o chart no servidor
cd /caminho/do/repo/support/helm

# 2. Fazer upgrade (MANTEM os dados/PVCs)
helm upgrade evo ./evolution-api --namespace evo

# 3. Verificar pods
kubectl get pods -n evo

# 4. Ver logs do initContainer (deve mostrar "Permissoes ajustadas com sucesso!")
kubectl logs -n evo <pod-postgresql-name> -c init-chmod-data

# 5. Ver logs do PostgreSQL
kubectl logs -n evo <pod-postgresql-name> -c postgresql
```

## Opcao 2: Reinstalar (SE O UPGRADE NAO FUNCIONAR)

**ATENCAO**: Esta opcao APAGA todos os dados!

```bash
# 1. Desinstalar
helm uninstall evo -n evo

# 2. Deletar PVCs (APAGA DADOS!)
kubectl delete pvc -n evo -l app.kubernetes.io/instance=evo

# 3. Reinstalar
helm install evo ./evolution-api --namespace evo

# 4. Verificar
kubectl get pods -n evo
```

## Opcao 3: Manter Dados e Recriar Apenas PostgreSQL

Se quiser resetar apenas o PostgreSQL mas manter os dados da Evolution API:

```bash
# 1. Escalar PostgreSQL para 0
kubectl scale deployment evo-evolution-api-postgresql -n evo --replicas=0

# 2. Deletar PVC do PostgreSQL (APAGA DADOS DO POSTGRES!)
kubectl delete pvc evo-evolution-api-postgresql -n evo

# 3. Fazer upgrade
helm upgrade evo ./evolution-api --namespace evo

# 4. Verificar
kubectl get pods -n evo
```

## Validacao Pos-Upgrade

```bash
# 1. Todos os pods devem estar Running
kubectl get pods -n evo

# Esperado:
# NAME                                    READY   STATUS    RESTARTS
# evo-evolution-api-xxx                   1/1     Running   0
# evo-evolution-api-postgresql-xxx        1/1     Running   0
# evo-evolution-api-redis-xxx             1/1     Running   0

# 2. Verificar logs do initContainer (deve ter sucesso)
kubectl logs -n evo $(kubectl get pod -n evo -l app.kubernetes.io/component=postgresql -o name | head -1) -c init-chmod-data

# Esperado:
# Criando diretorio de dados...
# Ajustando permissoes...
# Permissoes ajustadas com sucesso!
# total 0
# drwxr-xr-x    2 999      999             40 Mar 18 23:00 data

# 3. Verificar se PostgreSQL iniciou corretamente
kubectl logs -n evo $(kubectl get pod -n evo -l app.kubernetes.io/component=postgresql -o name | head -1) -c postgresql | tail -20

# Esperado (deve conter):
# database system is ready to accept connections

# 4. Testar conexao com a Evolution API
kubectl get svc -n evo

# Se tiver Ingress configurado:
curl https://seu-dominio.com

# Ou port-forward:
kubectl port-forward -n evo svc/evo-evolution-api 8080:8080
curl http://localhost:8080
```

## Se Ainda Houver Erro

### Verificar Permissoes no Volume

```bash
# Entrar no pod do PostgreSQL
kubectl exec -it -n evo $(kubectl get pod -n evo -l app.kubernetes.io/component=postgresql -o name | head -1 | cut -d/ -f2) -- sh

# Dentro do pod, verificar:
ls -la /var/lib/postgresql/
ls -la /var/lib/postgresql/data/ 2>/dev/null || echo "Diretorio nao existe ainda"

# Deve mostrar algo como:
# drwxr-xr-x    3 postgres postgres      4096 Mar 18 23:00 .
# drwxr-xr-x    1 postgres postgres      4096 Mar 18 23:00 ..
# drwx------    2 postgres postgres      4096 Mar 18 23:00 data
```

### Verificar StorageClass (se for NFS)

```bash
# Ver informacoes do PV
kubectl get pv

# Descrever o PV do PostgreSQL
kubectl describe pv $(kubectl get pvc -n evo evo-evolution-api-postgresql -o jsonpath='{.spec.volumeName}')

# Se for NFS, verificar no servidor NFS se tem 'no_root_squash':
# No servidor NFS:
cat /etc/exports
# Deve conter algo como:
# /path/to/nfs *(rw,sync,no_root_squash,no_subtree_check)
```

### Forcar Recriacao Completa (ULTIMO RECURSO)

```bash
# 1. Backup de configuracoes importantes (API keys, etc)
kubectl get secret evo-evolution-api-secret -n evo -o yaml > backup-secret.yaml

# 2. Desinstalar tudo
helm uninstall evo -n evo

# 3. Deletar TODOS os recursos
kubectl delete all -n evo -l app.kubernetes.io/instance=evo
kubectl delete pvc -n evo -l app.kubernetes.io/instance=evo
kubectl delete secret -n evo -l app.kubernetes.io/instance=evo

# 4. Reinstalar do zero
helm install evo ./evolution-api --namespace evo

# 5. Restaurar secret (se necessario)
kubectl apply -f backup-secret.yaml
```

## Suporte

Se o problema persistir:

1. Colete os logs:
   ```bash
   kubectl logs -n evo <pod-postgresql> -c init-chmod-data > init-logs.txt
   kubectl logs -n evo <pod-postgresql> -c postgresql > postgres-logs.txt
   kubectl describe pod -n evo <pod-postgresql> > pod-describe.txt
   ```

2. Consulte a documentacao completa:
   - [PERMISSIONS_TROUBLESHOOTING.md](PERMISSIONS_TROUBLESHOOTING.md)

3. Informacoes do ambiente:
   ```bash
   kubectl version
   kubectl get storageclass
   kubectl get pv
   ```
