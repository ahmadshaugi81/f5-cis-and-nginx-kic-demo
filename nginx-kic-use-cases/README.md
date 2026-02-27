# **UNDER CONSTRUCTION !!!**
# NGINX Plus Ingress Controller Use Cases

We are going to demonstrate several use cases for Nginx Plus KIC, including:
- Inter namespace routing
- Basic & advanced routing
- TLS termination
- Authentication
- Traffic splitting
- Access control
- Rate limiting
- Log integration with Prometheus & Grafana

## Deploying Sample Apps
1. Create new namespace and deploy apps-cafe
```
kubectl apply -f /sample-apps/ns-and-apps-cafe.yaml
```

2.