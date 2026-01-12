# References
- https://docs.nginx.com/nginx-ingress-controller/install/manifests/

# Summary of step-by-step
1. Global configuration
    - Git clone script from git
    - Create namespace
2. Deploy the backend apps and it's service
3. Install the Nginx Plus as KIC and setup to publish the backend app services
    - KIC without NAP
    - KIC with NAP
4. Install CIS and setup to populate and load balance KIC
5. Integration to Monitoring Tools: F5 AST & Prometheus

# Global Configuration
1. Do git clone
```
git clone https://github.com/ahmadshaugi81/f5-cis-and-nginx-kic-demo.git
```
2. Go inside the new folder
3. Create namespace
```
kubectl create namespace nginx-ingress
```

# Deploy backend apps and services
1. Go to folder "b-deploy-backend-services"
2. Deploy sample backend apps and it's services
    - For service with ClusterIP 
    ``` 
    UNDER CONSTRUCTION 
    ```
    - For service with ClusterIP and enable nodeportlocal annotations (specific for use case with CNI Antrea)
    ```
    kubectl -n nginx-ingress apply -f 2-demo-app-and-svc-nplocal.yaml
    ```
    - For service with NodePort
    ```
    kubectl -n nginx-ingress apply -f 3-demo-app-and-svc-nodeport.yaml
    ```

# Installation Nginx+ Ingress Controller
1. Create or upload Nginx Plus JWT license file, certificate, and key files. Paste the value on each file creation

```
vi nginx-one-eval.jwt
vi nginx-one-eval.crt
vi nginx-one-eval.key
```
2. Create Kubernetes secret to pull images from NGINX private registry
```
kubectl create secret docker-registry regcred --docker-server=private-registry.nginx.com --docker-username=`cat nginx-one-eval.jwt` --docker-password=none -n nginx-ingress
```
3. Create Kubernetes secret holding the NGINX Plus license
```
kubectl create secret generic license-token --from-file=license.jwt=nginx-one-eval.jwt --type=nginx.com/license -n nginx-ingress
```
4. Optional: Create secret for Nginx ONE data plane key to integrate control plane monitoring with Nginx ONE console
```
kubectl create secret generic dataplane-key \
--from-literal=dataplane.key=<Your Dataplane Key> \
-n <namespace>
```
5. Create core custom resources
```
kubectl apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.3.1/deploy/crds.yaml
kubectl apply -f https://raw.githubusercontent.com/nginx/kubernetes-ingress/v5.3.1/deploy/crds-nap-waf.yaml
```
6. Install Nginx Plus KIC with Helm, choose one that suitable
Before doing installation, understand below parameters:
    - **controller.replicaCount**: use to define the number of KIC pods created
    - **controller.nginxStatus.allowCidrs**: use to define list of IP address allowed to access N+ live dashboard
    - **controller.service.type**: use to create service directly in single Helm command to exposed KIC (ex: ClusterIP or NodePort)
    - To integrate with Nginx ONE console for monitoring purposed, add this to the helm charts:
    ```
    --set controller.image.repository=myregistry.example.com/nginx-plus-ingress \
    --set controller.nginxplus=true \
    --set nginxAgent.enable=true \
    --set nginxAgent.dataplaneKeySecretName=<data_plane_key_secret_name> \
    --set nginxAgent.endpointHost=agent.connect.nginx.com
    ```
Choose on of the options below to install Nginx Plus ingress controller
- Install KIC only without service
- Install KIC with service nodeport
7. Enable nginx live dashboard
    a. Add access-list to allow access to N+ live dashboard 
    b. Enable service to access live dashboard
8. Verify KIC installations
```
kubectl get pods -n nginx-ingress
```
9. Check the ingressclass
```
kubectl get ingressclass
```
10. To uninstall through Helm chart
```
helm uninstall nginx-plus-kic -n nginx-ingress
```

