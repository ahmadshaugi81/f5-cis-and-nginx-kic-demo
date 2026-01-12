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