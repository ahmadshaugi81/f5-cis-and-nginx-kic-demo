# F5 CIS and NGINX Plus Kubernetes Ingress Controller Demo

## About This Repo

This repository is a hands-on lab for integrating **NGINX Plus Ingress Controller (KIC)** with **F5 BIG-IP Container Ingress Services (CIS)** on Kubernetes. It contains installation manifests, Helm values, and step-by-step guides to stand up both components, expose sample applications through them, and walk through common ingress use cases (routing, TLS, authentication, traffic splitting, rate limiting, etc.).

It is organized as a set of self-contained folders, each with its own README:

- [`nplus-kic-install/`](nplus-kic-install) — Install NGINX Plus Ingress Controller via raw manifests or Helm
- [`cis-install/`](cis-install) — Install F5 Container Ingress Services (CIS)
- [`cis-with-nodeportlocal/`](cis-with-nodeportlocal) — CIS integration using Antrea CNI's NodePortLocal
- [`sample-apps/`](sample-apps) — Demo backend applications used as routing targets
- [`nginx-kic-use-cases/`](nginx-kic-use-cases) — Use case walkthroughs (routing, TLS, JWT auth, traffic splitting, rate limiting)
- [`nginx-one-integration/`](nginx-one-integration) — Integrating NGINX Plus KIC with NGINX One Console
- [`monitoring/`](monitoring) — Monitoring setup (Grafana, AST, ELK) — in progress

## Repo Flow

The lab is meant to be followed in this order:

1. **CIS Installation** — Install F5 Container Ingress Services on the Kubernetes cluster so BIG-IP can be driven by Kubernetes custom resources. See [`cis-install/README.md`](cis-install/README.md) (or [`cis-with-nodeportlocal/README.md`](cis-with-nodeportlocal/README.md) for the Antrea NodePortLocal variant).

2. **NGINX Plus Installation** — Install NGINX Plus as a Kubernetes Ingress Controller, either via manifests or Helm. See [`nplus-kic-install/manifest/README.md`](nplus-kic-install/manifest/README.md) or [`nplus-kic-install/helm/README.md`](nplus-kic-install/helm/README.md).

3. **Application Installation** — Deploy the sample backend applications that will be exposed through the ingress stack. See [`sample-apps/README.md`](sample-apps/README.md).

4. **Exposing the Service through BIG-IP + NGINX KIC** — Create a `VirtualServer` on NGINX Plus KIC to route to the application, then create a `VirtualServer` on F5 CIS to expose that KIC service through BIG-IP (NodePort, ClusterIP, or HTTPS offload).

5. **Use Case Testing** — Validate the end-to-end setup against real-world scenarios: cross-namespace routing, TLS termination, JWT authentication, traffic splitting, and rate limiting. See [`nginx-kic-use-cases/README.md`](nginx-kic-use-cases/README.md).

## Getting Started

1. Pull this repository to your local machine:
    ```
    git clone https://github.com/ahmadshaugi81/f5-cis-and-nginx-kic-demo.git
    cd f5-cis-and-nginx-kic-demo
    ```

2. Follow the steps in [Repo Flow](#repo-flow) above, starting with CIS installation.

## References

- [Official NGINX Plus Ingress Controller Documentation](https://docs.nginx.com/nginx-ingress-controller/)
- [NGINX One Documentation](https://docs.nginx.com/nginx-one/)
- [NGINX Ingress Controller Lab (f5devcentral GitHub)](https://github.com/f5devcentral/NGINX-Ingress-Controller-Lab/tree/main/labs)
- [F5 Container Ingress Services (CIS) Documentation](https://clouddocs.f5.com/containers/latest/userguide/kubernetes/)
- [F5 CIS GitHub (k8s-bigip-ctlr)](https://github.com/F5Networks/k8s-bigip-ctlr)
