#!/bin/bash

set -e

# === CONFIG ===
CA_DIR=certs/ca
COMPONENTS=("kraftcontroller" "kafka" "connect" "schemaregistry" "ksqldb" "controlcenter" "kafkarestproxy")
NAMESPACE=confluent
DAYS_VALID=1000
CLUSTER_DOMAIN="svc.cluster.local"

# === Create CA ===
mkdir -p $CA_DIR
openssl genrsa -out $CA_DIR/ca.key 4096
openssl req -x509 -new -nodes -key $CA_DIR/ca.key -sha256 -days 3650 -out $CA_DIR/ca.pem \
  -subj "/C=IN/ST=KA/L=Bangalore/O=Platformatory/OU=PlatformTeam/CN=platformatory-ca"

# === Generate certs for each component ===
for COMPONENT in "${COMPONENTS[@]}"; do
  echo "Generating certificate for $COMPONENT"
  COMP_DIR=certs/$COMPONENT
  mkdir -p $COMP_DIR

  # Private Key
  openssl genrsa -out $COMP_DIR/${COMPONENT}.key 2048

  # CSR
  openssl req -new -key $COMP_DIR/${COMPONENT}.key -out $COMP_DIR/${COMPONENT}.csr \
    -subj "/C=IN/ST=KA/L=Bangalore/O=Platformatory/OU=Confluent/CN=${COMPONENT}.${NAMESPACE}.${CLUSTER_DOMAIN}"

  # SAN config
  cat > $COMP_DIR/${COMPONENT}.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${COMPONENT}
DNS.2 = ${COMPONENT}.${NAMESPACE}
DNS.3 = ${COMPONENT}.${NAMESPACE}.svc
DNS.4 = ${COMPONENT}.${NAMESPACE}.svc.cluster.local
EOF

  # Add per-pod entries if it's kafka or kraftcontroller
  if [[ "$COMPONENT" == "kafka" || "$COMPONENT" == "kraftcontroller" ]]; then
    for i in 0 1 2; do
      echo "DNS.$((5 + i)) = ${COMPONENT}-${i}.${COMPONENT}.${NAMESPACE}.svc.cluster.local" >> $COMP_DIR/${COMPONENT}.ext
    done
  fi

  # Signed cert
  openssl x509 -req -in $COMP_DIR/${COMPONENT}.csr -CA $CA_DIR/ca.pem -CAkey $CA_DIR/ca.key \
    -CAcreateserial -out $COMP_DIR/${COMPONENT}.crt -days $DAYS_VALID -sha256 \
    -extfile $COMP_DIR/${COMPONENT}.ext

  # Kubernetes secret
  kubectl create secret generic tls-${COMPONENT} \
    --from-file=fullchain.pem=$COMP_DIR/${COMPONENT}.crt \
    --from-file=cacerts.pem=$CA_DIR/ca.pem \
    --from-file=privkey.pem=$COMP_DIR/${COMPONENT}.key \
    --namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

  echo "Secret tls-${COMPONENT} created/updated in namespace $NAMESPACE"
done

echo "✅ All component certificates and Kubernetes secrets created."
#!/bin/bash

set -e

# === CONFIG ===
CA_DIR=certs/ca
COMPONENTS=("kraftcontroller" "kafka" "connect" "schemaregistry" "ksqldb" "controlcenter" "kafkarestproxy")
NAMESPACE=confluent
DAYS_VALID=1000
CLUSTER_DOMAIN="svc.cluster.local"

# === Create CA ===
mkdir -p $CA_DIR
openssl genrsa -out $CA_DIR/ca.key 4096
openssl req -x509 -new -nodes -key $CA_DIR/ca.key -sha256 -days 3650 -out $CA_DIR/ca.pem \
  -subj "/C=IN/ST=KA/L=Bangalore/O=Platformatory/OU=PlatformTeam/CN=platformatory-ca"

# === Generate certs for each component ===
for COMPONENT in "${COMPONENTS[@]}"; do
  echo "Generating certificate for $COMPONENT"
  COMP_DIR=certs/$COMPONENT
  mkdir -p $COMP_DIR

  # Private Key
  openssl genrsa -out $COMP_DIR/${COMPONENT}.key 2048

  # CSR
  openssl req -new -key $COMP_DIR/${COMPONENT}.key -out $COMP_DIR/${COMPONENT}.csr \
    -subj "/C=IN/ST=KA/L=Bangalore/O=Platformatory/OU=Confluent/CN=${COMPONENT}.${NAMESPACE}.${CLUSTER_DOMAIN}"

  # SAN config
  cat > $COMP_DIR/${COMPONENT}.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${COMPONENT}
DNS.2 = ${COMPONENT}.${NAMESPACE}
DNS.3 = ${COMPONENT}.${NAMESPACE}.svc
DNS.4 = ${COMPONENT}.${NAMESPACE}.svc.cluster.local
EOF

  # Add per-pod entries if it's kafka or kraftcontroller
  if [[ "$COMPONENT" == "kafka" || "$COMPONENT" == "kraftcontroller" ]]; then
    for i in 0 1 2; do
      echo "DNS.$((5 + i)) = ${COMPONENT}-${i}.${COMPONENT}.${NAMESPACE}.svc.cluster.local" >> $COMP_DIR/${COMPONENT}.ext
    done
  fi

  # Signed cert
  openssl x509 -req -in $COMP_DIR/${COMPONENT}.csr -CA $CA_DIR/ca.pem -CAkey $CA_DIR/ca.key \
    -CAcreateserial -out $COMP_DIR/${COMPONENT}.crt -days $DAYS_VALID -sha256 \
    -extfile $COMP_DIR/${COMPONENT}.ext

  # Kubernetes secret
  kubectl create secret generic tls-${COMPONENT} \
    --from-file=fullchain.pem=$COMP_DIR/${COMPONENT}.crt \
    --from-file=cacerts.pem=$CA_DIR/ca.pem \
    --from-file=privkey.pem=$COMP_DIR/${COMPONENT}.key \
    --namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

  echo "Secret tls-${COMPONENT} created/updated in namespace $NAMESPACE"
done

echo "✅ All component certificates and Kubernetes secrets created."
