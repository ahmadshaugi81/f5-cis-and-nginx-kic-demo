# UNDER CONSTRUCTION!!
# F5 CIS Integration using Nodeportlocal on CNI Antrea

## Step-by-step Implementations
1. Update CIS installation to use Nodeportlocal for pool member
    ```
    kubectl -f apply cis-installation-nodeportlocal.yaml
    ```

2. Create new ingress VS on Nginx Plus KIC
    ```
    kubectl -f apply nic-vs-sample-apps-nodeportlocal.yaml
    ```

3. Create new ingress service with ClusterIP using annotations nodeportlocal
    ```
    kubectl -f apply clusterip-svc-ingress-nodeportlocal.yaml
    ```
    After service created, you can check on the service that now it had annotations with nodeportlocal.

4. Create new CIS VS
    ```
    kubectl -f apply cis-vs-ingress-443-nodeportlocal.yaml
    ```

5. For verification process, first check the existing number of Nginx Plus KIC installed with ```kubectl -n nginx-ingress get pod -l app=nginx-ingress``` and check the number of pool member on the last created VS on BIG-IP, where it should be match. Then scale the deployment number using command below:
    ```
    kubectl -n nginx-ingress scale deployment nginx-ingress --replicas=6
    ```
Now check again the number of Nginx Plus KIC pod and BIG-IP pool member after scaling the replica.
</br>

## Rollback to Nodeport (if needed)

When need to rollback to pool-member-type Nodeport, just apply the manifest that was used previously during first CIS installation (cis-install/cis-installation.yaml)