# Sample Apps Installation

This step deploys the sample "cafe" demo backend apps (`coffee-v1`, `coffee-v2`, `tea`, `tea-post`, `webapp`) into a new `apps-cafe` namespace. These apps act as the routing targets used later when exposing services through NGINX Plus KIC and F5 CIS, and when testing the ingress use cases.

1. Create sample apps deployment and service. This creates the `apps-cafe` namespace along with the backend Deployments and ClusterIP Services:
    ```
    kubectl apply -f sample-apps/ns-and-apps-cafe.yaml
    ```

2. Verify the apps and services are running. This is to check the Pods and Services in the `apps-cafe` namespace, confirming the deployments are up before exposing them through NGINX Plus KIC:
    ```
    kubectl get pods,svc -n apps-cafe
    ```