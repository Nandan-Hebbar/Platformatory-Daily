# Zookeeper
apiVersion: platform.confluent.io/v1beta1
kind: Zookeeper
metadata:
  name: zookeeper
  namespace: sasl-1
spec:
  replicas: 3
  image:
    application: confluentinc/cp-zookeeper:7.5.0
    init: confluentinc/confluent-init-container:2.7.0
  dataVolumeCapacity: 10Gi
  logVolumeCapacity: 10Gi
  podTemplate:
    resources:
      requests:
        cpu: 100m
        memory: 256Mi
    podSecurityContext:
      fsGroup: 1000
      runAsUser: 1000
      runAsNonRoot: true
---
# Kafka
apiVersion: platform.confluent.io/v1beta1
kind: Kafka
metadata:
  name: kafka
  namespace: sasl-1
spec:
  replicas: 3
  image:
    application: confluentinc/cp-server:7.5.0
    init: confluentinc/confluent-init-container:2.7.0
  dataVolumeCapacity: 10Gi
  listeners:
    internal:
      authentication:
        type: plain
        jaasConfig:
          secretRef: sasl-secrets-s1
    external:
      authentication:
        type: plain
        jaasConfig:
          secretRef: sasl-secrets-s1
  dependencies:
    zookeeper:
      endpoint: zookeeper.sasl-1.svc.cluster.local:2181
  podTemplate:
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
    podSecurityContext:
      fsGroup: 1000
      runAsUser: 1000
      runAsNonRoot: true
---
# Connect
apiVersion: platform.confluent.io/v1beta1
kind: Connect
metadata:
  name: connect
  namespace: sasl-1
spec:
  replicas: 1
  image:
    application: confluentinc/cp-server-connect:7.9.0
    init: confluentinc/confluent-init-container:2.11.0
  dependencies:
    kafka:
      bootstrapEndpoint: kafka.sasl-1.svc.cluster.local:9092
      authentication:
        type: plain
        jaasConfig:
          secretRef: sasl-secrets-c1
---
# Schema Registry
apiVersion: platform.confluent.io/v1beta1
kind: SchemaRegistry
metadata:
  name: schemaregistry
  namespace: sasl-1
spec:
  replicas: 1
  image:
    application: confluentinc/cp-schema-registry:7.9.0
    init: confluentinc/confluent-init-container:2.11.0
  dependencies:
    kafka:
      bootstrapEndpoint: kafka.sasl-1.svc.cluster.local:9092
      authentication:
        type: plain
        jaasConfig:
          secretRef: sasl-secrets-c1
---
# KsqlDB
apiVersion: platform.confluent.io/v1beta1
kind: KsqlDB
metadata:
  name: ksqldb
  namespace: sasl-1
spec:
  replicas: 1
  image:
    application: confluentinc/cp-ksqldb-server:7.9.0
    init: confluentinc/confluent-init-container:2.11.0
  dataVolumeCapacity: 10Gi
  dependencies:
    kafka:
      bootstrapEndpoint: kafka.sasl-1.svc.cluster.local:9092
      authentication:
        type: plain
        jaasConfig:
          secretRef: sasl-secrets-c1
---
# Kafka REST Proxy
apiVersion: platform.confluent.io/v1beta1
kind: KafkaRestProxy
metadata:
  name: kafkarestproxy
  namespace: sasl-1
spec:
  replicas: 1
  image:
    application: confluentinc/cp-kafka-rest:7.9.0
    init: confluentinc/confluent-init-container:2.11.0
  dependencies:
    kafka:
      bootstrapEndpoint: kafka.sasl-1.svc.cluster.local:9092
      authentication:
        type: plain
        jaasConfig:
          secretRef: sasl-secrets-c1
---
#ControlCenter
apiVersion: platform.confluent.io/v1beta1
kind: ControlCenter
metadata:
  name: controlcenter
  namespace: sasl-1
spec:
  replicas: 1
  image:
    application: confluentinc/cp-enterprise-control-center:7.9.0
    init: confluentinc/confluent-init-container:2.11.0
  dataVolumeCapacity: 10Gi
  dependencies:
    kafka:
      bootstrapEndpoint: kafka.sasl-1.svc.cluster.local:9092
      authentication:
        type: plain
        jaasConfig:
          secretRef: sasl-secrets-c1
    connect:
      - name: connect
        url: http://connect.sasl-1.svc.cluster.local:8083
    ksqldb:
      - name: ksqldb
        url: http://ksqldb.sasl-1.svc.cluster.local:8088
    schemaRegistry:
      url: http://schemaregistry.sasl-1.svc.cluster.local:8081


1. Create 2 files with the following name and extension

a. server-secrets.json


{
"platformatory": "729999"
}


b. client-secrets.txt


username=platformatory
password=729999






2. Create secrets for both client and server side:

kubectl create secret generic sasl-secrets-s1 --from-file=plain-users.json=$X/server-secrets.json   --namespace sasl-1

kubectl create secret generic sasl-secrets-c1 --from-file=plain.txt=$Y/client-secrets.txt   --namespace sasl-1







3. Run the following cmds


kubectl apply -f confluent-platform.yaml

kubectl exec -it kafka-1 -n sasl-1 -- bash

cat <<EOF > client-jaas.conf
sasl.mechanism=PLAIN
security.protocol=SASL_PLAINTEXT
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
  username="platformatory" \
  password="729999";
EOF

kafka-topics --bootstrap-server localhost:9092 --command-config client-jaas.conf --create --topic test-topic

kafka-topics --bootstrap-server localhost:9092 --command-config client-jaas.conf --list



