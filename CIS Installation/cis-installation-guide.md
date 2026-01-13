# **UNDER CONSTRUCTION !!!**

References: https://clouddocs.f5.com/containers/latest/userguide/kubernetes/#installing-cis-manually

# F5 Container Ingress Service (CIS) Installation

## Pre-requisites Before Installation
1. Under Construction!!!
2.

## Step-by-step of F5 CIS Installation
1. Create RBAC file
```
kubectl create -f k8s_rbac.yaml
```
2. Install CRD
3. Create secret bigip credential 
```
kubectl create secret generic bigip-login -n kube-system --from-literal=username=admin --from-literal=password=<password>
```
4. Install CIS
```
kubectl create -f cis-installation.yaml
```
