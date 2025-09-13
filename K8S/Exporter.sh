#!/bin/bash
# Script to install Prometheus + Grafana + Jetson Exporter

# Namespace where Prometheus and Grafana will be installed
NAMESPACE="prometheus"

# 1. Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. Install kube-prometheus-stack using values.yaml in the files directory
helm install prometheus-community/kube-prometheus-stack \
  --namespace $NAMESPACE \
  --create-namespace \
  --generate-name \
  --values ./files/values.yaml

# 3. Patch Grafana Service (grafana-patch.yaml in the files directory)
#    Dynamically get the Grafana service name created by Helm
GRAFANA_SVC=$(kubectl get svc -n $NAMESPACE -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}')

kubectl patch svc $GRAFANA_SVC -n $NAMESPACE --patch "$(cat ./files/grafana-patch.yaml)"

echo "Grafana credentials default: user=admin password=prom-operator"

# 5. Apply exporter (exporter.yaml in the files directory)
kubectl apply -n $NAMESPACE -f ./files/exporter.yaml


echo "Prometheus + Grafana + Jetson Exporter installation complete!"
