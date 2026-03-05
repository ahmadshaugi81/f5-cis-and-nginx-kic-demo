# **UNDER CONSTRUCTION !!!**
# NGINX Plus Ingress Controller Use Cases

We are going to demonstrate several use cases for Nginx Plus KIC & F5 Container Ingress Service, including:
- Inter namespace routing
- Basic & advanced routing
- TLS termination on BIG-IP and Nginx Plus Ingress Controller
- Authentication with JWT
- Traffic splitting (weight)
- Rate limiting
- Log integration with Prometheus & Grafana - next development
</br>

## References

All use cases was copied from [this repo](https://github.com/f5devcentral/NGINX-Ingress-Controller-Lab/tree/main/labs) with some adjustment.
</br>

## Configuration Steps

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

2. Create new namespace and deploy sample apps
    ```
    kubectl apply -f /sample-apps/ns-and-apps-cafe.yaml
    ```

3. Create TLS profile to be used on VirtualServer objects on Nginx Plus KIC and F5 CIS
    ```
    kubectl create secret tls cafe-secret --cert=sample-tls.crt --key=sample-tls.key -n apps-cafe
    kubectl create secret tls cafe-secret --cert=sample-tls.crt --key=sample-tls.key -n nginx-ingress
    ```
    
4. Apply this manifest to create several objects, such as:
    - Rate limit policy for KIC
    - JWK secret & JWT validation policy for KIC
    - TLS profile for F5 BIG-IP
    - VS on Nginx Plus KIC and F5 CIS
    </br>

    ```
    kubectl apply -f nic-vs-cafe-adv-routing.yaml
    ```

5. Create test.sh file on server that will simulate request from client on **traffic splitting** scenario. This shell script will generate traffic to _https://cafe.f5demo.io/split_, then it will print the results. Make sure that cafe.f5demo.io was can be reached from clients simulator (ex: creating /etc/hosts configuration), or modify the script as needed.

    ```
    #!/bin/bash

    coffee_v1_count=0
    coffee_v2_count=0

    for i in {1..100}
    do
    response=$(curl -k https://cafe.f5demo.io/split | grep "Server name" | awk '{print $3}')

    if [[ "$response" == *"v1"* ]]; then
        coffee_v1_count=$((coffee_v1_count + 1))
    elif [[ "$response" == *"v2"* ]]; then
        coffee_v2_count=$((coffee_v2_count + 1))
    fi
    done

    echo "Summary of responses:"
    echo "Coffee v1: $coffee_v1_count times"
    echo "Coffee v2: $coffee_v2_count times"
    ```

6. Create **_token.jwt_** file for **JWT authentication** scenario
    ```
    eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IjAwMDEifQ.eyJuYW1lIjoiUXVvdGF0aW9uIFN5c3RlbSIsInN1YiI6InF1b3RlcyIsImlzcyI6Ik15IEFQSSBHYXRld2F5In0.ggVOHYnVFB8GVPE-VOIo3jD71gTkLffAY0hQOGXPL2I
    ```
</br>


## Testing the Use Cases
### Advanced Routing Scenario
Basically all scenario here are doing advanced routing, where Nginx Plus KIC will do routing in various conditions.
1. When requesting to URI /tea with method POST, it will routed to service tea-post
    ```
    curl -ik https://cafe.f5demo.io/tea -X POST
    ```

    Expected result:
    ```
    HTTP/1.1 200 OK
    Server: nginx/1.29.3
    Date: Thu, 05 Mar 2026 15:21:07 GMT
    Content-Type: text/plain
    Content-Length: 160
    Connection: keep-alive
    Expires: Thu, 05 Mar 2026 15:21:06 GMT
    Cache-Control: no-cache
    Set-Cookie: BIGipServer~kubernetes~Shared~svc_nginx_ingress_npl_443_nginx_ingress_cafe_f5demo_io=117506314.19182.0000; path=/; Httponly; Secure

    Server address: 192.168.2.12:8080
    **_Server name: tea-post-ff7789454-g997n_**
    Date: 05/Mar/2026:15:21:07 +0000
    URI: /tea
    Request ID: f533fa08c8ea44634be43538c4f2991c
    ```