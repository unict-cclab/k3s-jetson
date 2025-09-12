## K3s Jetson

This guide shows the steps required to provision a K3s cluster on NVIDIA Jetson nodes.

### Prerequisites

- ansible

- kubectl

- helm

apk add git
apk add sshpass
ansible-galaxy collection install git+https://github.com/k3s-io/k3s-ansible.git


----------------------------------------------------------------------------------