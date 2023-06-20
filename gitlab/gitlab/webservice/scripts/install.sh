#!/bin/env bash

SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )


KAP_REALM_DESCRIPTOR=$(curl -sLk https://keycloak.dev.local/realms/kap/protocol/saml/descriptor)
REALM_CERTIFICATE=$(echo $KAP_REALM_DESCRIPTOR | sed -nE 's/.*<ds:X509Certificate>(.*)<\/ds:X509Certificate>.*/\1/p' | tr -d '\n')
REALM_FINGERPRINT=$(echo $REALM_CERTIFICATE | openssl x509 -noout -fingerprint -sha1 -in <(echo -e "-----BEGIN CERTIFICATE-----\n$REALM_CERTIFICATE\n-----END CERTIFICATE-----") | sed -e 's/.*Fingerprint=//')
SAML_PROVIDER_FILE=$(mktemp)

cat <<EOF > $SAML_PROVIDER_FILE
name: 'saml'
label: 'Keycloak'
args:
    assertion_consumer_service_url: 'https://gitlab.dev.local/users/auth/saml/callback'
    idp_cert_fingerprint: '$REALM_FINGERPRINT'
    idp_sso_target_url: 'https://keycloak.dev.local/realms/kap/protocol/saml/clients/gitlab'
    issuer: 'gitlab'
    name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
EOF

kubectl delete secret/gitlab-saml-provider --namespace gitlab
kubectl create secret generic gitlab-saml-provider --type=Opaque --namespace gitlab --from-file=keycloak-saml=$SAML_PROVIDER_FILE

rm $SAML_PROVIDER_FILE

kubectl create -k $SCRIPT_DIR/..
kubectl wait -n gitlab --for=condition=complete job/gitlab-migrations-1 --timeout=300s
kubectl wait -n gitlab --for=condition=complete job/gitlab-create-admin-user --timeout=300s