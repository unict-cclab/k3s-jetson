#!/bin/bash
# Script to install Prometheus + Grafana + Jetson Exporter

# Namespace where Prometheus and Grafana will be installed
NAMESPACE="observability"

# 1. Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. Install kube-prometheus-stack using values.yaml in the files directory
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
    --version 75.8.1 -f ./files/prometheus-values.yml \
    -n $NAMESPACE \
    --create-namespace
#3. Install Istio 
#helm repo add istio https://istio-release.storage.googleapis.com/charts
#helm repo update
#helm install istio-base istio/base --version 1.26.2 --set defaultRevision=default -n istio-system --create-namespace
#helm install istiod istio/istiod --version 1.26.2 -f ./files/values.yml -n istio-system --create-namespace --wait
#kubectl label namespace default istio-injection=enabled
#install monitor Istio
#kubectl apply -f ./files/istio-monitor.yml
# 4. Apply exporter (exporter.yaml in the files directory)
kubectl apply -n $NAMESPACE -f ./files/exporter.yaml


echo "Prometheus + Grafana + Istio + Jetson Exporter installation complete!"


# Namespace Plugin
NAMESPACE_NVIDIA="nvidia-device-plugin"
kubectl create namespace $NAMESPACE_NVIDIA

#4. Add label to the nodes
#   - jetsonorigin -> orin
#   - nano9*       -> nano

kubectl label node jetsonorigin nvidia.com/device-plugin.config=orin --overwrite
for i in {90..97}; do
  kubectl label node nano$i nvidia.com/device-plugin.config=nano --overwrite
done

#5. Apply ConfigMap from the file (in the directory files)
kubectl apply -n $NAMESPACE_NVIDIA -f ./files/multi-node-configuration.yaml


#6. Installation / upgrade NVIDIA Device Plugin via Helm
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --version=0.17.4 \
  --namespace $NAMESPACE_NVIDIA \
  --create-namespace \
  --set config.name=time-slicing-config \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key="node-role.kubernetes.io/master" \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator="DoesNotExist"
