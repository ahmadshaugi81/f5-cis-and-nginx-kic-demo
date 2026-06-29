# **UNDER CONSTRUCTION !!!**

References: https://clouddocs.f5.com/containers/latest/userguide/kubernetes/#installing-cis-manually

# F5 Container Ingress Service (CIS) Installation

## Pre-requisites Before Installation

There are several steps we need to do directly on F5 BIG-IP instance before moving to F5 CIS installation & integration.

2. AS3 Module Installation and Validation

    Validate AS3 package installation on BIG-IP at menu **iApps ›› Package Management LX**, and search for **f5-appsvc**. If there is no AS3 package installed, download the package from this [link](https://github.com/f5networks/f5-appsvcs-extension) and install from Configuration Utility as explain on this [link](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/installation.html#installing-big-ip-as3-using-the-big-ip-configuration-utility).

    ![AS3 Verification](assets/as3-verification.png)

- login as admin -> click iApps -> click "Package Management LX" -> validate that f5-avvsvcs installed ( we use 3.54 version )

<img width="1687" alt="Image" src="https://github.com/user-attachments/assets/e16b4f93-08af-4d7a-9076-f75a177df0b3" />
  
### Check HA Sync Type (Should be Manual)

HA Sync Type should be set to Manual to avoid conflict sync between CIS and TMOS HA. When we deploy CIS for BigIP CLuster HA, we will have 2 CIS per each node (standby and active) to do monitoring and config provisioning. If Sync Type is Auto, CIS will trigger issue that cis cannot update the config

<img width="300" alt="Image" src="https://github.com/user-attachments/assets/8fee055b-f3bf-48fd-b42a-89330783c8a7" />

- click "Device Management" -> click "Device Groups" -> Choose bigip-a_bigip-b_dg (Includes Self)

 <img width="1672" alt="Image" src="https://github.com/user-attachments/assets/430144a8-f271-47a4-b272-b893271c90e6" />
 <img width="1672" alt="Image" src="https://github.com/user-attachments/assets/54266b8e-74fc-46b7-8d6c-e869e9ed0e80" />

### Create a BIG-IP partition to manage OpenShift routing

CIS will add a static route on the BIG-IP to reach OpenShift pod services via the OpenShift nodes.
Therefore, we need to prepare a dedicated partition on BIG-IP for this purpose. In this lab , we use opp1-routing as partition name

- Click System -> Select Users -> Select Partition List -> Click "Plus" Sign
<img width="421" alt="Image" src="https://github.com/user-attachments/assets/66c707dd-29d3-45ae-99ea-908a1fbfd034" />

- Add opp1-routing , select route domain rd-10 -> click Finished
<img width="1023" height="686" alt="Image" src="https://github.com/user-attachments/assets/6a8513de-2c85-465b-bf12-6d3ca8eeb859" />

#### Notes : we can add partition manually on pair node or sync config from configured node

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

## CIS VirtualServer

After installing CIS pods on k8s system and create an application service on the cluster, then we need to create a VirtualServer object to exposed this service on K8S through F5 BIG-IP via CIS. This VirtualServer must be **_created on the same namespace as the application service_**. Run this command to create VirtualServer object:

```
kubectl -n <target-namespace> create -f cis-vs-creation.yaml
```

Refer to the official F5 CIS documentation for other [VirtualServer](https://clouddocs.f5.com/containers/latest/userguide/crd/virtualserver.html) components.