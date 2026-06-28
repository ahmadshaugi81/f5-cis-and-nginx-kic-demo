# Installation NGINX Plus Ingress Controller with Manifest

## Installation Steps

**Notes:** _Before begin, check the latest version of NGINX Ingress on this [link](https://github.com/nginx/kubernetes-ingress/releases)_ and make sure already clone this repository and has been inside the working folder:
    ```
    git clone https://github.com/ahmadshaugi81/f5-cis-and-nginx-kic-demo.git
    cd f5-cis-and-nginx-kic-demo
    ```
</br>

1. Create a namespace and a service account. This is to create a Namespace, which is the isolated workspace for all NGINX Plus KIC resources, and a Service Account, which is the identity the controller pod uses to talk to the Kubernetes API:
    ```
    kubectl apply -f nplus-kic-install/ns-and-sa.yaml
    ```

2. Create a cluster role and binding for the service account. This is to create a ClusterRole, which defines the permissions needed across the cluster (watching Ingress/Service/Endpoints, etc.), and a ClusterRoleBinding, which grants those permissions to the service account:
    ```
    kubectl apply -f nplus-kic-install/rbac.yaml
    ```

3. Create or upload the Nginx Plus JWT license file. Paste the value on file creation. This is to create the JWT license file, which authorizes use of NGINX Plus and is used to pull the image and activate the license:
    ```
    vi nplus-kic-install/nginx-eval.jwt
    ```

4. Create Kubernetes secret to pull images from NGINX private registry. This is to create a docker-registry Secret, which stores the credentials (the JWT as username) needed to authenticate and pull the NGINX Plus image:
    ```
    kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=`cat nplus-kic-install/nginx-eval.jwt` --docker-password=none -n nginx-ingress
    ```

5. Create Kubernetes secret holding the NGINX Plus license. This is to create a generic Secret, which stores the JWT license so the running controller can load and activate it:
    ```
    kubectl create secret generic license-token --from-file=license.jwt=nplus-kic-install/nginx-eval.jwt --type=nginx.com/license -n nginx-ingress
    ```

6. Create a ConfigMap to customize your NGINX settings. This is to create a ConfigMap for general NGINX configuration, and another ConfigMap for management-plane settings, which controls how the controller reports usage/license to NGINX:
    ```
    kubectl apply -f nplus-kic-install/nginx-config.yaml
    kubectl apply -f nplus-kic-install/plus-mgmt-configmap.yaml
    ```

7. Create an IngressClass resource. NGINX Ingress Controller won't start without an IngressClass resource. This is to create an IngressClass, which is what Ingress/VirtualServer resources reference so this specific controller knows to handle them:
    ```
    kubectl apply -f nplus-kic-install/ingress-class.yaml
    ```

8. Install CRDs from single YAML (without NAP). Update the **_version_** as needed. This is to register the Custom Resource Definitions, which add new resource kinds like VirtualServer and Policy that the controller uses instead of plain Ingress objects:
    ```
    kubectl apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.3.1/deploy/crds.yaml
    ```

9. Deploy NGINX Ingress Controller with deployment. Choose this method for the flexibility to dynamically change the number of NGINX Ingress Controller replicas. This is to create the Deployment, which runs the actual NGINX Plus Ingress Controller pods using the namespace, RBAC, secrets, and ConfigMaps prepared in the previous steps:
    ```
    kubectl apply -f nplus-kic-install/nginx-plus-ingress.yaml
    ```

10. Verify NGINX ingress installation. This is to check the Pods, which confirms the controller is up and running before exposing any application through it:
    ```
    kubectl get pods -n nginx-ingress
    ```
</br>

## Uninstall NGINX Ingress Controller

To uninstall, please follow the [official documentation](https://docs.nginx.com/nginx-ingress-controller/install/manifests/#uninstall-nginx-ingress-controller).
</br>
</br>