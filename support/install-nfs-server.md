# Instalação do Servidor NFS para o Kubernetes

## Instalação do serviço NFS
instalar o serviço de NFS no servidor principal onde será sentralizados todos disco fisicos.

Crias as pastas de storages onde sera montado os discos:
```bash
mkdir -p /storages/storage01 # indicado para criação no disco principal caso tenha espaço
chown nobody:nogroup /storages/storage01
chmod 777 /storages/storage01
```

Depois de criar as pastas com os storages instale e serviço
```bash
apt update
apt install nfs-kernel-server
```

Edite o arquivo /etc/exports e coloque as pastas dos storages
```txt
/storages/storage01  192.168.1.0/24(rw,sync,no_subtree_check)
/storages/storage02  192.168.1.0/24(rw,sync,no_subtree_check)

```
Aplique as cofigurações do NFS
```bash
exportfs -a
systemctl restart nfs-kernel-server
```

Libere a porta para os outro servidores acessar no firewall
```bash
ufw allow from 192.168.1.0/24 to any port nfs
```

Congiruação do no outros servidores para validar o acesso do NFS:
```bash
sudo apt install nfs-common
sudo mkdir -p /mnt/nfs_clientshare
sudo mount 192.168.1.x:/mnt/nfs_share /mnt/nfs_clientshare
```
## Instalação do NFS no kubernetes

instalação no kubernetes precisa esta apontando para servidor que esta como principal do NFS.

A instalação e configuração é atravez do helm usando o nfs-subdir-external-provisioner:
```bash
helm repo add nfs-subdir https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-storage01 nfs-subdir/nfs-subdir-external-provisioner --namespace nfs-subdir --create-namespace --set nfs.server=187.84.150.162 --set nfs.path=/storages/storage01 --set storageClass.defaultClass=true --set storageClass.name=storage01
 
```

