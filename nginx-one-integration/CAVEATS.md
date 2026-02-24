# Caveats Found during NGINX One Console Integrations

## Environments Error

</br>

## Metrics not showing with Nginx Agent permission error

### **Issues:**
Ingress instance is successfully integrated to Nginx One Console, but no metrics show. When check the log Nginx Agent (kubectl exec -it -n nginx-ingress <pod-name> -- nginx-agent) then an error events found.

**Sample Logs:**

The errors you are seeing now are permission denied errors for local disk writes:
    ```open /var/log/nginx-agent/opentelemetry-collector-agent.log: permission denied```
    ```open /var/lib/nginx-agent/manifest.json: permission denied```

**Why & Resolutions:**

Why this is happening:
Per F5 NGINX official security best practices, your manifest is correctly configured to run the pod as a non-root user (runAsUser: 101 and runAsNonRoot: true). However, the NGINX Agent needs to write telemetry data and local state files to /var/log and /var/lib. In standard container images, these system directories are owned by root. Because the Agent is running as user 101, it is being blocked from writing its metrics and manifest files to the disk.

🛠️ The Official Kubernetes Fix: emptyDir Volumes

To fix this without compromising the security of your non-root pod, you need to provide the Agent with temporary, writable scratch space. In Kubernetes, this is done using emptyDir volumes.

You just need to add two volume mounts to your container and two matching emptyDir volumes to your pod spec.

✅ What this does:

When the pod starts, Kubernetes will create empty, ephemeral directories specifically for this pod and mount them over those restricted /var/ paths. Because Kubernetes provisions them for the pod, your non-root user (101) will have full read/write access to them. The Agent will be able to write its OpenTelemetry logs and manifest.json files without crashing.