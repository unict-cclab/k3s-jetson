# k3s-jetson

Script per installare **k3s** su nodi **NVIDIA Jetson** e configurare **monitoring + NVIDIA Device Plugin**.

---

## 📁 Script principali

| Script / Playbook                                     | Descrizione                                                                 |
| ----------------------------------------------------- | --------------------------------------------------------------------------- |
| `ansible-playbook -i inventory.yml setup-cluster.yml` | Installa k3s sui nodi Jetson ( Ansible )                                    |
| `ansible-playbook -i inventory.yml undo-cluster.yml`  | Disinstalla / rollback del cluster k3s                                      |
| `./Monitoring.sh`                                     | Installa Prometheus, Grafana, Istio, Jetson Exporter e NVIDIA Device Plugin |
| `./undo-Monitoring.sh`                                | Disinstalla la configurazione di monitoring e NVIDIA Device Plugin          |

---

## 🚀 Installazione cluster k3s con Ansible

Esegui il playbook per installare k3s sui Jetson:

```bash
ansible-playbook -i inventory.yml setup-cluster.yml
```

Per disinstallare/rollback:

```bash
ansible-playbook -i inventory.yml undo-cluster.yml
```

---

## 📊 Monitoring + NVIDIA Device Plugin

Per installare la suite di monitoring e il device plugin:

```bash
./Monitoring.sh
```

Per rimuovere tutto:

```bash
./undo-Monitoring.sh
```

---

## ⚙️ Dettagli installazione – Monitoring

> Valorizzare le variabili `NAMESPACE` e i file in `./files/` prima di eseguire gli script, se necessario.

### 1. Installazione kube-prometheus-stack

```bash
helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
  --version 75.8.1 -f ./files/prometheus-values.yml \
  -n observability \
  --create-namespace
```

### 2. Installazione Istio

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

helm install istio-base istio/base --version 1.26.2 \
  --set defaultRevision=default \
  -n istio-system --create-namespace

helm install istiod istio/istiod --version 1.26.2 \
  -f ./files/values.yml \
  -n istio-system --create-namespace --wait
```

### 3. Abilitare l’injection automatica dei sidecar Envoy

```bash
kubectl label namespace default istio-injection=enabled
```

> Nota: applica la label solo se vuoi l'injection automatica per TUTTI i pod nel namespace `default`. In alternativa crea un namespace dedicato per le tue app e applica la label lì.

### 4. Monitor Istio

```bash
kubectl apply -f ./files/istio-monitor.yml
```

### 5. Jetson Exporter (metriche da jtop)

```bash
kubectl apply -n observability -f ./files/exporter.yaml
```

---

## ⚙️ Dettagli installazione – NVIDIA Device Plugin

### 1. Label dei nodi per configurazioni time-slice diverse

```bash
kubectl label node jetsonorigin nvidia.com/device-plugin.config=orin --overwrite

for i in {90..97}; do
  kubectl label node nano$i nvidia.com/device-plugin.config=nano --overwrite
done
```

### 2. ConfigMap multi-configurazione time-slice

```bash
kubectl apply -n nvidia-device-plugin -f ./files/multi-node-configuration.yaml
```

### 3. Installazione NVIDIA Device Plugin (escludendo master node)

```bash
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo update

helm upgrade -i nvdp nvdp/nvidia-device-plugin \
  --version=0.17.4 \
  --namespace nvidia-device-plugin \
  --create-namespace \
  --set config.name=time-slicing-config \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].key="node-role.kubernetes.io/master" \
  --set affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[0].operator="DoesNotExist"
```

---

## 🧾 Script di rollback

* `undo-Monitoring.sh` — script per rimuovere Prometheus, Grafana, Istio e Jetson Exporter (se presente).
* `undo-cluster.yml` — Ansible playbook per rimuovere k3s (se presente).
