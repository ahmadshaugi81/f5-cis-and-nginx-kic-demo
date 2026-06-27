# F5 CIS Integration using Nodeportlocal for CNI Antrea

Enabling NodePortLocal (NPL) is exactly what you want to do if you are running Antrea with F5 BIG-IP. It is arguably the most efficient way to route external traffic into a Kubernetes cluster.

To understand why, let's look at how F5 Container Ingress Services (CIS) normally routes traffic, and why Antrea's NPL makes it so much better.

**Why F5 CIS + Antrea NPL is the Best of Both Worlds**

Historically, you had two main choices when integrating BIG-IP with Kubernetes:

1. **NodePort Mode:** BIG-IP sends traffic to a NodeIP on a high port (e.g., 31000). The traffic hits kube-proxy, which then load-balances it (again) to the actual Pod, potentially hopping to another node. Downside: Extra network hops, double load-balancing, and loss of source IP visibility.

2. **ClusterIP Mode:** BIG-IP routes traffic directly to the Pod's internal IP. Downside: This requires setting up complex VXLAN or BGP tunnels between the BIG-IP and the Kubernetes nodes so the BIG-IP can reach the internal Pod network.

**The NPL Solution:**
With Antrea's NodePortLocal, Antrea assigns a specific port on the Node (from that 61000-62000 range we saw earlier) directly mapped to a specific Pod. F5 CIS simply reads this mapping and tells the BIG-IP: "To reach Pod A, send traffic to Node 1 on port 61000." Traffic goes directly from the BIG-IP to the Node IP, and straight into the Pod. No kube-proxy hops, and no complex VXLAN/BGP tunnels required!
</br>

## References
1. [F5 BIG-IP Container Ingress Services - VMWare Tanzu](https://clouddocs.f5.com/containers/latest/userguide/vmware-tanzu/)
2. [BIG-IP integration with Antrea and NodePortLocal on VMware Tanzu](https://community.f5.com/kb/technicalarticles/big-ip-integration-with-antrea-and-nodeportlocal-on-vmware-tanzu/293812)
</br>

## Pre-Requisites - Verify or Enable Nodeportlocal in Antrea Agent

1. Verify the Live Configuration Inside the Pod

    Run this command to print the nodePortLocal section directly from the configuration file mounted inside the running Pod:

    ```
    kubectl exec -it -n kube-system $(kubectl get pods -n kube-system -l component=antrea-agent --field-selector spec.nodeName=[your-worker-name] -o jsonpath='{.items[0].metadata.name}') -- grep -A 5 -i "nodePortLocal:" /etc/antrea/antrea-agent.conf
    ```

    Change the _[your-worker-name]_ value with your actual worker name

2. If the output shows **_enable: true_**, then the nodeportlocal already running on your cluster and you can go to the implementation steps

3. If the output shows **_enable: false_**, then the nodeportlocal is not enable yet and we need to edit the antrea-config ConfigMap configurations
   - **Step 1: Force the ConfigMap Update**

     Let's edit the ConfigMap again and make absolutely sure it saves.

     ```
     kubectl edit configmap antrea-config -n kube-system
     ```
    
     Scroll down until you find the ```antrea-agent.conf``` section (make sure you aren't in the ```antrea-controller.conf``` section by mistake). Find the ```nodePortLocal``` block and change ```false``` to ```true```.

     Make sure it looks exactly like this, with the exact same spacing:

     ```
     nodePortLocal:
     # Enable NodePortLocal, a feature used to make Pods reachable using port forwarding on the host. To
     # enable this feature, you need to set "enable" to true.
     enable: true
     # Provide the port range used by NodePortLocal. When the NodePortLocal feature is enabled, a port
     # from that range will be assigned...
     ```

     Save and close the editor. If it saves successfully, Kubernetes will output: ```configmap/antrea-config edited```.

   - **Step 2: Nuke the Old Agent Pods**
     Instead of a graceful rollout, let's just forcefully delete the agent pods so the DaemonSet is forced to recreate them immediately with the fresh configuration.

     Run this command:

     ```
     kubectl delete pods -n kube-system -l component=antrea-agent
     ```
     
     Wait a few seconds for the new pods to spin up and reach the Running state:

     ```
     kubectl get pods -n kube-system -l component=antrea-agent
     ```
    

   - Step 3: Verify the Config is Actually Loaded

     Run your exact same grep command again to prove the new pod actually picked up the true setting:

     ```
     kubectl exec -it -n kube-system $(kubectl get pods -n kube-system -l component=antrea-agent --field-selector spec.nodeName=[your-worker-name] -o jsonpath='{.items[0].metadata.name}') -- grep -A 5 -i "nodePortLocal:" /etc/antrea/antrea-agent.conf
     ```

     Change the _[your-worker-name]_ value with your actual worker name

     If this now says ```enable: true```, we are in business and go to implementation steps!
</br>

## Step-by-step Implementations
1. Update CIS installation to use Nodeportlocal for pool member
    ```
    kubectl apply -f cis-installation-nodeportlocal.yaml
    ```

2. Create new ingress VS on Nginx Plus KIC
    ```
    kubectl apply -f nic-vs-sample-apps-nodeportlocal.yaml
    ```

3. Create new ingress service with ClusterIP using annotations nodeportlocal
    ```
    kubectl apply -f clusterip-svc-ingress-nodeportlocal.yaml
    ```
    After service created, you can check on the service that now it had annotations with nodeportlocal.

4. Create new CIS VS
    ```
    kubectl apply -f cis-vs-ingress-443-nodeportlocal.yaml
    ```

5. For verification process, first check the existing number of Nginx Plus KIC installed with ```kubectl -n nginx-ingress get pod -l app=nginx-ingress``` and check the number of pool member on the last created VS on BIG-IP, where it should be match. Then scale the deployment number using command below:
    ```
    kubectl -n nginx-ingress scale deployment nginx-ingress --replicas=6
    ```
    Now check again the number of Nginx Plus KIC pod and BIG-IP pool member after scaling the replica.
</br>

## Rollback to Nodeport (if needed)

When need to rollback to pool-member-type Nodeport, just apply the manifest that was used previously during first CIS installation (cis-install/cis-installation.yaml)