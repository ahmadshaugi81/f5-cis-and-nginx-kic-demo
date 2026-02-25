# Caveats on NGINX One Console Integrations
While building this lab, I was experiencing some issues while integrating Nginx KIC to Nginx One Console. Thanks to Google Gemini ❤️❤️, it help me to found some reference, help finding the root cause, and also the resolutions. This caveats might not be relevant when future updates was release, but it will help at least for current release version and for my lab! 🙂👍🏻
</br>
</br>

## 1# Nginx Ingress Controller crash when using environments NGINX_AGENT_SERVER_TOKEN

### Issues
When installing Nginx Plus Ingress, the pod are failed to created, and there is an error log on the pods like when we check with this command ```kubectl -n nginx-ingress logs <pod-name>```.

### Sample Logs

```
E20260224 05:16:55.210235 1 main.go:1092] Error updating pod with labels on attempt 1 of 10: Pod "nginx-ingress-6c566b4697-cwtvk" is invalid: [metadata.labels: Invalid value: "2026/02/24 05:16:55 WARN Detected deprecated or unknown environment variables. Please update to use the latest environment variables. For more information, visit https://docs.nginx.com/nginx-one/agent/configure-instances/configuration-overview/. deprecated_env_var=NGINX_AGENT_SERVER_TOKEN\nnginx-agent version v3.6.1-17fbae9": must be no more than 63 characters, metadata.labels: Invalid value: "2026/02/24 05:16:55 WARN Detected deprecated or unknown environment variables. Please update to use the latest environment variables. For more information, visit https://docs.nginx.com/nginx-one/agent/configure-instances/configuration-overview/. deprecated_env_var=NGINX_AGENT_SERVER_TOKEN\nnginx-agent version v3.6.1-17fbae9": a valid label must be an empty string or consist of alphanumeric characters, '-', '_' or '.', and must start and end with an alphanumeric character (e.g. 'MyValue', or 'my_value', or '12345', regex used for validation is '(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?')]
```

### Why & Resolutions

🔍 **What caused this crash?**

You are experiencing a bug caused by how the KIC (Kubernetes Ingress Controller) interacts with the newly updated NGINX Agent (version v3.6.1) bundled inside your 5.3.1 image.

Here is the exact chain of events:

1. When the KIC pod starts, it runs a command (like nginx-agent -v) to find out what version of the agent is running. It wants to take that version number and apply it as a Kubernetes label to your Pod (app.nginx.org/agent-version).
2. However, NGINX Agent v3.6.1 recently marked the NGINX_AGENT_SERVER_TOKEN environment variable as deprecated.
3. Because you used that environment variable, the Agent spits out a massive, multi-line warning message to the console before outputting its version number.
4. The KIC blindly captures that entire warning string and tries to inject it as the Kubernetes Pod label.
5. Kubernetes throws a fatal error because Pod labels have a strict 63-character limit and do not allow spaces or special characters. The KIC crashes.

🛠️ **The Official Solution: Use the File Mount**

Because KIC cannot handle the deprecation warning, we must avoid using the environment variable. We will go back to mounting the secret as a file, but we will fix the file name so the Agent finds it automatically without complaining!

By default, NGINX Agent looks for the token in exactly this file: /etc/nginx-agent/secrets/dataplane.key.

Here is how you format your manifest to force Kubernetes to rename your secret key to the exact filename the Agent wants.

1. Keep the env block commented out (or delete it):
```
# - name: NGINX_AGENT_SERVER_TOKEN
#   valueFrom:
#     secretKeyRef:
#       name: nginx-one-key
#       key: data-plane-key
```

2. Keep the volumeMounts exactly as you had them:
```
volumeMounts:
- name: nginx-agent-config
    mountPath: /etc/nginx-agent/nginx-agent.conf
    subPath: nginx-agent.conf
- name: dataplane-key
    mountPath: /etc/nginx-agent/secrets
```

3. Update the volumes section at the very bottom:
This is the magic fix. We add the items array to explicitly map your Kubernetes secret key to the dataplane.key file.

```
volumes:
- name: nginx-plus-license
secret:
    secretName: license-token
- name: nginx-agent-config
configMap:
    name: nginx-agent-config
- name: dataplane-key
secret:
    secretName: nginx-one-key
    items:
    - key: data-plane-key   # The key inside your k8s secret
    path: dataplane.key   # The specific file name the Agent wants
```

✅ **What this does:**
By doing this, the NGINX Agent gets the token securely from the file it expects, the deprecation warning never triggers, KIC successfully reads the short version string, labels the pod, and connects to the NGINX One Console!

</br>

## 2# Metrics not showing with Nginx Agent permission error

### Issues
Ingress instance is successfully integrated to Nginx One Console, but no metrics show. When check the log Nginx Agent (kubectl exec -it -n nginx-ingress <pod-name> -- nginx-agent) then an error events found.

### Sample Logs

The errors you are seeing now are permission denied errors for local disk writes:

```
open /var/log/nginx-agent/opentelemetry-collector-agent.log: permission denied
open /var/lib/nginx-agent/manifest.json: permission denied
```

### Why & Resolutions

🔍 **Why this is happening:**
Per F5 NGINX official security best practices, your manifest is correctly configured to run the pod as a non-root user (runAsUser: 101 and runAsNonRoot: true). However, the NGINX Agent needs to write telemetry data and local state files to /var/log and /var/lib. In standard container images, these system directories are owned by root. Because the Agent is running as user 101, it is being blocked from writing its metrics and manifest files to the disk.

🛠️ **The Official Kubernetes Fix: emptyDir Volumes**

To fix this without compromising the security of your non-root pod, you need to provide the Agent with temporary, writable scratch space. In Kubernetes, this is done using emptyDir volumes.

You just need to add two volume mounts to your container and two matching emptyDir volumes to your pod spec.

1. Add these to your volumeMounts list:

```
- name: nginx-agent-lib
    mountPath: /var/lib/nginx-agent
- name: nginx-agent-log
    mountPath: /var/log/nginx-agent
```

2. Add these to your volumes list (at the very bottom of the manifest):

```
- name: nginx-agent-lib
emptyDir: {}
- name: nginx-agent-log
emptyDir: {}
```

✅ **What this does:**

When the pod starts, Kubernetes will create empty, ephemeral directories specifically for this pod and mount them over those restricted /var/ paths. Because Kubernetes provisions them for the pod, your non-root user (101) will have full read/write access to them. The Agent will be able to write its OpenTelemetry logs and manifest.json files without crashing.