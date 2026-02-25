# Integration NGINX Plus Ingress Controller with NGINX One Console

_This guide provides the official steps to install NGINX Plus as a Kubernetes Ingress Controller (KIC) using manifests and integrating it into the NGINX One console for centralized monitoring._

## Prerequisites
Before beginning, ensure you have the following from the official F5 NGINX Reports and NGINX One Console:

1. NGINX Plus License: A valid JWT token (license) to pull the NGINX Plus Ingress image.

2. NGINX One Data Plane Key: Generated from the NGINX One Console (Manage > Data Plane Keys).

3. A Kubernetes Cluster: Access via kubectl.
</br>

## KIC Installation & One Console Integrations Steps

**Notes:** _For Nginx Plus KIC installation you may follow the previous guide on Nginx Plus KIC installation guide, but with a few changes on additional Configmap configurations and need to update the manifest for Ingress installations_
</br>

1. Prepare the installation as needed, if haven't been done, like create namespace and service account, create license secret key, and so on as needed for installing Nginx Plus KIC. NGINX One monitoring requires an NGINX Agent running alongside the controller

2. Create the Data Plane Key Secret for integration with NGINX One Console. 

```
kubectl create secret generic nginx-one-key --from-literal=data-plane-key=<YOUR_DATA_PLANE_KEY> -n nginx-ingress
```

3. Create the NGINX Agent ConfigMap

```
kubectl apply -f nginx-agent-config.yaml
```

4. Deploy NGINX Plus Ingress Controller: Modify the standard nginx-plus-ingress.yaml manifest to include the NGINX One agent configuration. Apply the deployment:

```
kubectl apply -f nginx-plus-ingress-with-oneconsole.yaml
```
</br>

## Verification
Once the pods are running, verify the connection:

1. Check Pod Logs: ```kubectl logs <pod-name> -n nginx-ingress```. Look for "NGINX Agent started" and "Successfully registered with NGINX One".

2. Check NGINX One Console: Log in to the NGINX One Console, navigate to Manage > Instances. Your Kubernetes Ingress Controller should appear as a "Control Plane" with its associated pods listed as instances.
