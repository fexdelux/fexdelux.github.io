#!/bin/bash
export EMAIL_ADDRESS=$1
export INGRESS_CLASS_NAME=$2
export SERVER_LETSENCRYPT="https://acme-v02.api.letsencrypt.org/directory"

curl -s https://url/seu-arquivo.yaml | envsubst | kubectl apply -f -