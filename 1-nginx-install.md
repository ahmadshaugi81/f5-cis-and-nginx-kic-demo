# Installation NGINX Plus Ingress Controller with Manifest

## Installation Steps

**Notes:** _Before begin, check the latest version of NGINX Ingress on this [link](https://github.com/nginx/kubernetes-ingress/releases)_ and make sure already clone this repository and has been inside the working folder:
    ```
    git clone https://github.com/ahmadshaugi81/f5-cis-and-nginx-kic-demo.git
    cd f5-cis-and-nginx-kic-demo
    ```
</br>

1. Create a namespace and a service account:
    ```
    kubectl apply -f nplus-kic-install/ns-and-sa.yaml
    ```

2. Create a cluster role and binding for the service account:
    ```
    kubectl apply -f nplus-kic-install/rbac.yaml
    ```

3. Create or upload Nginx Plus JWT license file, certificate, and key files. Paste the value on each file creation
    ```
    vi nplus-kic-install/nginx-one-eval.jwt
    vi nplus-kic-install/nginx-one-eval.crt
    vi nplus-kic-install/nginx-one-eval.key
    ```

4. Create Kubernetes secret to pull images from NGINX private registry
    ```
    kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=`cat nplus-kic-install/nginx-one-eval.jwt` --docker-password=none -n nginx-ingress
    ```

5. Create Kubernetes secret holding the NGINX Plus license
    ```
    kubectl create secret generic license-token --from-file=license.jwt=nplus-kic-install/nginx-one-eval.jwt --type=nginx.com/license -n nginx-ingress
    ```

6. Create a ConfigMap to customize your NGINX settings:
    ```
    kubectl apply -f nplus-kic-install/nginx-config.yaml
    kubectl apply -f nplus-kic-install/plus-mgmt-configmap.yaml
    ```

7. Create an IngressClass resource. NGINX Ingress Controller won’t start without an IngressClass resource.
    ```
    kubectl apply -f nplus-kic-install/ingress-class.yaml
    ```

8. Install CRDs from single YAML (without NAP). Update the **_version_** as needed
    ```
    kubectl apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.3.1/deploy/crds.yaml
    ```

9. Deploy NGINX Ingress Controller with deployment: Choose this method for the flexibility to dynamically change the number of NGINX Ingress Controller replicas.
    ```
    kubectl apply -f nplus-kic-install/nginx-plus-ingress.yaml
    ```

10. Verify NGINX ingress installation
    ```
    kubectl get pods -n nginx-ingress
    ```
</br>

## Uninstall NGINX Ingress Controller

To uninstall, please follow the [official documentation](https://docs.nginx.com/nginx-ingress-controller/install/manifests/#uninstall-nginx-ingress-controller).
</br>
</br>