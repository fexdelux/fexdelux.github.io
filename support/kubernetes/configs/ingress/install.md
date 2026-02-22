# Instalação do Ingress NGINX

## Via Helm

´´´bash
helm install <my-release> oci://ghcr.io/nginx/charts/nginx-ingress --version 2.4.3

´´´
ou

versão 1.14

´´´bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress --create-namespace --set controller.ingressClassResource.default=true --set controller.ingressClassResource.name=public 
´´´
