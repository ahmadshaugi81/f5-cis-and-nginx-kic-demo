# UNDER CONSTRUCTION!!
# NGINX PLUS KIC INSTALLATION WITH MANIFEST

1. Go to folder for installation with manifest
```
cd nginx-plus-kic-installation/installation-with-manifest
```

2. Create a namespace and a service account:
```
kubectl apply -f deployments/common/ns-and-sa.yaml
```

3. Create a cluster role and binding for the service account:
```
kubectl apply -f deployments/rbac/rbac.yaml
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
kubectl apply -f deployments/deployment/nginx-plus-ingress.yaml
```

11. Verify NGINX ingress installation
```
kubectl get pods -n nginx-ingress
```












2. Create Kubernetes secret to pull images from NGINX private registry
```
kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=`cat nginx-one-eval.jwt` --docker-password=none -n nginx-ingress
```
