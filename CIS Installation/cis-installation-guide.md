# **UNDER CONSTRUCTION !!!**

References: https://clouddocs.f5.com/containers/latest/userguide/kubernetes/#installing-cis-manually

Install CIS

1. Create RBAC file
2. Install CRD
3. Create secret bigip credential 
4. Install CIS

kubectl create secret generic f5-bigip-ctlr-login -n kube-system --from-literal=username=admin --from-literal=password=<password>

kubectl create secret generic bigip-login -n kube-system --from-literal=username=admin --from-literal=password=C3d3t3POC!

```
# for reference only
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-bigip-ctlr-deployment
  namespace: kube-system
spec:
  # DO NOT INCREASE REPLICA COUNT
  replicas: 1
  selector:
    matchLabels:
      app: k8s-bigip-ctlr-deployment
  template:
    metadata:
      name: k8s-bigip-ctlr-deployment
      labels:
        app: k8s-bigip-ctlr-deployment
    spec:
      serviceAccountName: bigip-ctlr
      containers:
        - name: k8s-bigip-ctlr
            image: "f5networks/k8s-bigip-ctlr: latest"
            imagePullPolicy: IfNotPresent
            env:
            - name: BIGIP_USERNAME 
                valueFrom:
                secretKeyRef:
                    name: bigip-login
                    key: username
            - name: BIGIP_PASSWORD
                valueFrom:
                secretKeyRef:
                    name: bigip-login
                    key: password
        command: ["/app/bin/k8s-bigip-ctlr"]
        args: [
            "--bigip-username=$(BIGIP_USERNAME)",
            "--bigip-password=$(BIGIP_PASSWORD)",
            "--bigip-url=https://192.168.18.11",
            "--insecure=true",
            "--bigip-partition=kubernetes",
            "--custom-resource-mode=true",
            "--as3-validation=true",
            "--log-as3-response=true",
            "--pool-member-type=nodeport"
        ]
```


      securityContext:
        runAsUser: 1000
        runAsGroup: 3000
        fsGroup: 2000
      volumes:
        - name: bigip-creds
          secret:
            secretName: f5-bigip-ctlr-login


        - name: k8s-bigip-ctlr
          image: "f5networks/k8s-bigip-ctlr:latest"
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: /health
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 15
            periodSeconds: 120
            successThreshold: 1
            timeoutSeconds: 15
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /health
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 30
            periodSeconds: 120
            successThreshold: 1
            timeoutSeconds: 15
          volumeMounts:
            - name: bigip-creds
              mountPath: "/tmp/creds"
              readOnly: true
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: [ "ALL" ]
            runAsNonRoot: true
            seccompProfile:
              type: RuntimeDefault
          command: ["/app/bin/k8s-bigip-ctlr"]
          args: [
            # See the k8s-bigip-ctlr documentation for information about
            # all config options
            # https://clouddocs.f5.com/containers/latest/userguide/config-parameters.html
            # here are some deployment parameters for your considerations
            "--credentials-directory=/tmp/creds",
            # Logging level
            "--log-level=INFO",
            # Replace with the name of the BIG-IP partition you want to manage
            "--bigip-partition=k8s",
            # See the page for pool member type support, https://clouddocs.f5.com/containers/latest/userguide/config-options.html
            "--pool-member-type=nodeport",
            # if pool-member-type is set to cluster,
            # see static routes support, https://clouddocs.f5.com/containers/latest/userguide/static-route-support.html
            # for Calico CNI see https://clouddocs.f5.com/containers/latest/userguide/calico-config.html
            # for Clilium CNI see https://clouddocs.f5.com/containers/latest/userguide/cilium-config.html
            # for vxlan tunnel configuration see https://clouddocs.f5.com/containers/latest/userguide/cis-installation.html#creating-vxlan-tunnels
            # for vxlan tunnel parameters see https://clouddocs.f5.com/containers/latest/userguide/config-parameters.html#vxlan
            # below parameter is a recommended parameter to verify the bigip certificate
            # "--trusted-certs-cfgmap=<namespace/config-map-with-bigip-certificates>"
            "--trusted-certs-cfgmap=kube-system/trusted-certs",
            # Use below parameter only for non-production environments
            # "--insecure",
            "--as3-validation=true",
            # for using custom resources, see more on https://clouddocs.f5.com/containers/latest/userguide/crd/
            "--custom-resource-mode=true",
            # for configuring nextgen openshift routes, see more on https://clouddocs.f5.com/containers/latest/userguide/next-gen-routes/
            # "--controller-mode=openshift",
            # "--extended-spec-configmap=default/extended-cm",
            # for configuring the multi-cluster mode, see more on https://clouddocs.f5.com/containers/latest/userguide/multicluster/
            # "--multi-cluster-mode=primary",
            # "--local-cluster-name=cluster1",
            # "--extended-spec-configmap=default/extended-cm",
            # for using the F5 IPAM Controller, see more on https://clouddocs.f5.com/containers/latest/userguide/ipam/
            # "--ipam=true",
          ]