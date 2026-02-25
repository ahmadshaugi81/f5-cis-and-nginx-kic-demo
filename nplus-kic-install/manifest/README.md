# Installation NGINX Plus Ingress Controller with Manifest

## Installation Steps

**Notes:** _Before begin, check the latest version of NGINX Ingress on this [link](https://github.com/nginx/kubernetes-ingress/releases)_ and make sure already clone this repository with command below:
```
git clone https://github.com/ahmadshaugi81/f5-cis-and-nginx-kic-demo.git
```
</br>

1. Go to folder for installation with manifest
```
cd nplus-kic-install/manifest
```

2. Create a namespace and a service account:
```
kubectl apply -f ns-and-sa.yaml
```

3. Create a cluster role and binding for the service account:
```
kubectl apply -f rbac.yaml
```

4. Create or upload Nginx Plus JWT license file, certificate, and key files. Paste the value on each file creation
```
vi nginx-one-eval.jwt
vi nginx-one-eval.crt
vi nginx-one-eval.key
```

5. Create Kubernetes secret to pull images from NGINX private registry
```
kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=`cat nginx-one-eval.jwt` --docker-password=none -n nginx-ingress
```

6. Create Kubernetes secret holding the NGINX Plus license
```
kubectl create secret generic license-token --from-file=license.jwt=nginx-one-eval.jwt --type=nginx.com/license -n nginx-ingress
```

7. Create a ConfigMap to customize your NGINX settings:
```
kubectl apply -f nginx-config.yaml
kubectl apply -f plus-mgmt-configmap.yaml
```

8. Create an IngressClass resource. NGINX Ingress Controller won’t start without an IngressClass resource.
```
kubectl apply -f ingress-class.yaml
```

9. Install CRDs from single YAML (without NAP). Update the **_version_** as needed
```
kubectl apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.3.1/deploy/crds.yaml
```

10. Deploy NGINX Ingress Controller with deployment: Choose this method for the flexibility to dynamically change the number of NGINX Ingress Controller replicas.
```
kubectl apply -f nginx-plus-ingress.yaml
```

11. Verify NGINX ingress installation
```
kubectl get pods -n nginx-ingress
```
</br>

## Uninstall NGINX Ingress Controller

To uninstall, please follow the [official documentation](https://docs.nginx.com/nginx-ingress-controller/install/manifests/#uninstall-nginx-ingress-controller).
</br>
</br>

## Sample Apps & Nginc Plus KIC virtualServer Creation

1. Create sample apps deployment and service:
```
kubectl apply -f /sample-apps/hello-nginx.yaml
```

2. To expose this app through Nginx Plus KIC, create KIC virtualServer:
```
kubectl apply -f nic-vs-sample-apps.yaml
```

3. To verify, check the ```virtualServer``` status on K8S, or you may check on Nginx Live Dashboard (explained on the next sections), or verify config file by having shell session directly to the pods (Using command like ```kubectl exec -it <pod-name> -- /bin/bash```) or via Nginx One Console (explained on **nginx-one-integration** section)
</br>

## Service Creation for NGINX Live Dashboard

1. To create service to expose NGINX Plus live dashboard:
```
kubectl apply -f np-svc-live-dash.yaml
```

2. To expose this live dashboard through BIG-IP, create CIS virtualServer:
```
kubectl apply -f /cis-install/cis-vs-nginx-live-dash.yaml
```
</br>

## Service Creation for NGINX Ingress Controller

1. To create service to expose NGINX ingress controller:
```
kubectl apply -f np-svc-ingress.yaml
```

2. To expose KIC through BIG-IP, create CIS virtualServer:
```
kubectl apply -f /cis-install/cis-vs-ingress.yaml
```
</br>

## Service Creation for NGINX Ingress Controller with HTTPS VS Offloading on BIG-IP

**Notes:** _If you already creating BIG-IP VS from the step before this, make sure to delete it first before executing command below to prevent configuration conflicts._

1. _(Skip if already created)_ To create service to expose NGINX ingress controller:
```
kubectl apply -f np-svc-ingress.yaml
```

2. To expose KIC through BIG-IP with HTTPS VS with TLS offloading mechanism, create CIS virtualServer:
```
kubectl apply -f /cis-install/cis-vs-ingress-443.yaml
```
</br>