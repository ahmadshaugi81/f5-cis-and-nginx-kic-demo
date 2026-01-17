# **UNDER CONSTRUCTION !!!**

References: https://clouddocs.f5.com/containers/latest/userguide/kubernetes/#installing-cis-manually

# F5 Container Ingress Service (CIS) Installation

## Pre-requisites Before Installation
1. Under Construction!!!
2.

## Step-by-step of F5 CIS Installation
1. Download the CA/BIG IP certificate and use it with CIS controller.
```
echo | openssl s_client -showcerts -servername <server-hostname>  -connect <server-ip-address>:<server-port> 2>/dev/null | openssl x509 -outform PEM > server_cert.pem
```
    Create configmap
```
kubectl create configmap trusted-certs --from-file=./server_cert.pem  -n kube-system
```
Alternatively, for non-prod environment you can use --insecure=true parameter.

2. Create RBAC file
```
kubectl create -f k8s_rbac.yaml
```
**Note:** _The command has the broadest supported permission set. You can narrow the permissions down to specific resources, namespaces, etc. to suit your needs._

2. Install Custom Resource Definitions (CRD) for CIS Controller
```
export CIS_VERSION=<cis-version>
# For example
# export CIS_VERSION=v2.20.0
# or
# export CIS_VERSION=2.x-master
# the latter if using a CIS image with :latest label
kubectl create -f https://raw.githubusercontent.com/F5Networks/k8s-bigip-ctlr/${CIS_VERSION}/docs/config_examples/customResourceDefinitions/customresourcedefinitions.yml
```

3. Create secret bigip credential 
```
kubectl create secret generic bigip-login -n kube-system --from-literal=username=admin --from-literal=password=<password>
```
4. Install CIS
```
kubectl create -f cis-installation.yaml
```
