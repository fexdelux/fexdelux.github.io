#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Uso: $0 <email> <ingress-class>"
  exit 1
fi

export EMAIL_ADDRESS=$1
export INGRESS_CLASS_NAME=$2
export SERVER_LETSENCRYPT="https://acme-v02.api.letsencrypt.org/directory"

curl -s https://fexdelux.github.io/support/kubernetes/configs/ingress/cert-manager-letsencrypt.yaml | envsubst | kubectl apply -f -