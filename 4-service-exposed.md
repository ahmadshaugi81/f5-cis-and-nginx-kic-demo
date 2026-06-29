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