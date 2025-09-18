#!/bin/bash
# Script to delete Nvidia Device Plugin configuration and multi-node time-slicing

# Namespace 
NAMESPACE="nvidia-device-plugin"

echo "Rimuovo label dai nodi…"

# 1. Remove labels from the nodes
kubectl label node jetsonorigin nvidia.com/device-plugin.config- 2>/dev/null
for i in {90..97}; do
  kubectl label node nano$i nvidia.com/device-plugin.config- 2>/dev/null
done

# 2. Delete ConfigMap deployed
echo "Rimuovo ConfigMap multi-node-configuration…"
kubectl delete -n $NAMESPACE -f ./files/multi-node-configuration.yaml 2>/dev/null

# 3. Uninstall NVIDIA Device Plugin via Helm
echo "Disinstallo chart Helm nvdp…"
helm uninstall nvdp -n $NAMESPACE 2>/dev/null

echo "Operazioni completate."
