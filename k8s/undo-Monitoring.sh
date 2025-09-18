#!/bin/bash
# Rimuove Prometheus + Grafana + Jetson Exporter

NAMESPACE="observability"

echo ">>> Rimozione Jetson Exporter..."
kubectl delete -f ./files/exporter.yaml --ignore-not-found
# Remove Istio monitoring config
echo "Removing Istio monitoring config..."
kubectl delete -f ./files/istio-monitor.yml --ignore-not-found

#  Remove Istio (istiod and istio-base)
echo "Uninstalling Istio..."
helm uninstall istiod -n istio-system || true
helm uninstall istio-base -n istio-system || true

# Remove Istio namespace (if empty)
kubectl delete namespace istio-system --ignore-not-found

# Remove istio-injection label from default namespace
kubectl label namespace default istio-injection- || true


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

# Namespace plugin 
NAMESPACE_NVIDIA="nvidia-device-plugin"

echo "Rimuovo label dai nodi…"

#  Remove labels from the nodes
kubectl label node jetsonorigin nvidia.com/device-plugin.config- 2>/dev/null
for i in {90..97}; do
  kubectl label node nano$i nvidia.com/device-plugin.config- 2>/dev/null
done

#  Delete ConfigMap deployed
echo "Rimuovo ConfigMap multi-node-configuration…"
kubectl delete -n $NAMESPACE_NVIDIA -f ./files/multi-node-configuration.yaml 2>/dev/null

#  Uninstall NVIDIA Device Plugin via Helm
echo "Disinstallo chart Helm nvdp…"
helm uninstall nvdp -n $NAMESPACE_NVIDIA 2>/dev/null

echo ">>> Undo completato!"
