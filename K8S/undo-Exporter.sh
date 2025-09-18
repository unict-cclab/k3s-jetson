#!/bin/bash
# Rimuove Prometheus + Grafana + Jetson Exporter

NAMESPACE="monitoring"

echo ">>> Rimozione Jetson Exporter..."
kubectl delete -f ./files/exporter.yaml --ignore-not-found

echo ">>> Disinstallazione kube-prometheus-stack..."
# find the Helm release
RELEASE=$(helm list -n $NAMESPACE -q | grep kube-prometheus-stack)
if [ -n "$RELEASE" ]; then
  helm uninstall "$RELEASE" -n $NAMESPACE
else
  echo "Nessuna release kube-prometheus-stack trovata in $NAMESPACE"
fi

echo ">>> Eliminazione namespace"
kubectl delete namespace $NAMESPACE --ignore-not-found

echo ">>> Undo completato!"
