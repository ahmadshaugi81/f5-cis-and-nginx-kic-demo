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

## References

## Deploying Sample Apps
1. Preconfigured iRules on F5 BIG-IP to pass SNI flag to Nginx Plus KIC

    *Why it is needed?* _BIG-IP is not by default adding SNI extension on server side ([check this as reference](https://my.f5.com/manage/s/article/K000157250#:~:text=Cause,-The%20server%20SSL)). To resolve that refer this [KB about injecting SNI on server-side from BIG-IP](https://my.f5.com/manage/s/article/K000160184), and refer to this [KB about why Nginx CIS need SNI flag enabled](https://my.f5.com/s/article/K000140717)_
    </br>

    **iRules Name:** _irules-sni_


    ```
    when CLIENTSSL_HANDSHAKE {
        if { [SSL::extensions exists -type 0] } then {
            set tls_sni_extension [SSL::extensions -type 0]
        }
    }
    when SERVERSSL_CLIENTHELLO_SEND {
        if { [info exists tls_sni_extension] } then {
            SSL::extensions insert $tls_sni_extension
        }
    }
    ```

2. Create new namespace and deploy apps-cafe
    ```
    kubectl apply -f /sample-apps/ns-and-apps-cafe.yaml
    ```

3. Create TLS profile to be used on VirtualServer objects on Nginx KIC and F5 CIS
    ```
    kubectl create secret tls cafe-secret --cert=sample-tls.crt --key=sample-tls.key -n apps-cafe
    kubectl create secret tls cafe-secret --cert=sample-tls.crt --key=sample-tls.key -n nginx-ingress
    ```
    
4. Apply this manifest to create several objects, such as:
    - Rate limit policy for KIC
    - TLS profile for F5 BIG-IP
    - VS on Nginx KIC and F5 CIS
    </br>

    ```
    kubectl apply -f nic-vs-cafe-adv-routing.yaml
    ```