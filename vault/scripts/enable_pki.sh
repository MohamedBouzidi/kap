#!/bin/env bash

DOMAIN="dev.local"
ROOT_TOKEN=$(kubectl get secret/vault-root-token --namespace vault -o jsonpath='{.data.token}' | base64 -d)

echo "[-] Enabling Vault PKI"

kubectl exec vault-0 --namespace vault -- /bin/sh -c "
vault login $ROOT_TOKEN
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

vault write pki/root/generate/internal common_name=$DOMAIN ttl=8760h
vault write pki/config/urls issuing_certificates=\"http://vault.vault:8200/v1/pki/ca\" crl_distribution_points=\"http://vault.vault:8200/v1/pki/crl\"
vault write pki/roles/kap-domain allowed_domains=$DOMAIN allow_subdomains=true max_ttl=72h
vault policy write pki - <<EOF
path \"pki*\"                  { capabilities = [\"read\", \"list\"] }
path \"pki/sign/kap-domain\"   { capabilities = [\"create\", \"update\"] }
path \"pki/issue/kap-domain\"  { capabilities = [\"create\"] }
EOF

vault auth enable kubernetes
vault write auth/kubernetes/config kubernetes_host=\"https://\$KUBERNETES_PORT_443_TCP_ADDR:\$KUBERNETES_SERVICE_PORT\"
vault write auth/kubernetes/role/vault-issuer bound_service_account_names=vault-issuer bound_service_account_namespaces=cert-manager policies=pki ttl=20m
"

echo "[*] Vault PKI enabled"