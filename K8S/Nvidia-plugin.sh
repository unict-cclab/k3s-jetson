#!/bin/bash
# Script per configurare time-slicing multi-nodo con NVIDIA Device Plugin

# Namespace
NAMESPACE="nvidia-device-plugin"


# 1. Aggiungere label ai nodi
#   - jetsonorigin -> orin
#   - nano9*       -> nano

kubectl label node jetsonorigin nvidia.com/device-plugin.config=orin --overwrite
for i in {90..97}; do
  kubectl label node nano$i nvidia.com/device-plugin.config=nano --overwrite
done

# 2. Applica il ConfigMap dal file (presente nella cartella files)
kubectl apply -n $NAMESPACE -f ./files/multi-node-configuration.yaml


# 3. Installazione / upgrade NVIDIA Device Plugin via Helm
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --version=0.17.4 \
  --namespace $NAMESPACE \
  --create-namespace \
  --set config.name=time-slicing-config \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key="node-role.kubernetes.io/master" \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator="DoesNotExist"
