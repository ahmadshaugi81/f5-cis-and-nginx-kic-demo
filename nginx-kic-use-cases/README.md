# NGINX Plus Ingress Controller Use Cases

We are going to demonstrate several use cases for Nginx Plus Ingress Controller & F5 Container Ingress Service, including:
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

1. Preconfigured iRules on F5 BIG-IP to pass SNI flag to Nginx Plus Ingress Controller

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

3. Create TLS profile to be used on VirtualServer objects on Nginx Plus Ingress Controller and F5 CIS
    ```
    kubectl create secret tls cafe-secret --cert=sample-tls.crt --key=sample-tls.key -n apps-cafe
    kubectl create secret tls cafe-secret --cert=sample-tls.crt --key=sample-tls.key -n nginx-ingress
    ```
    
4. Apply this manifest to create several objects, such as:
    - Rate limit policy for KIC
    - JWK secret & JWT validation policy for KIC
    - TLS profile for F5 BIG-IP
    - VS on Nginx Plus Ingress Controller and F5 CIS
    </br>

    ```
    kubectl apply -f nic-vs-cafe-adv-routing.yaml
    ```

5. Create **test.sh** file on server that will simulate request from client on **traffic splitting** scenario. This shell script will generate traffic to _https://cafe.f5demo.io/split_, then it will print the results. Make sure that cafe.f5demo.io can be reached from client simulator server (ex: creating /etc/hosts configuration), or modify the script as needed.

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

7. Create **rate-limit-test.sh** file on server that will simulate request from client on **rate limit** scenario. This shell script will generate traffic to _https://cafe.f5demo.io/tea_, with various time interval between 0.25, 0.5, 0.75, and 1 second, then it will print the total number of response code received, whether it is 200 or 429 (rate limited). Make sure that cafe.f5demo.io can be reached from client simulator server (ex: creating /etc/hosts configuration), or modify the script as needed.

    ```
    #!/bin/bash

    # Target URL
    URL="https://cafe.f5demo.io/tea"
    TOTAL_REQUESTS=100
    INTERVALS=(0.25 0.5 0.75 1)

    # Associative array to store response code counts
    declare -A status_counts

    echo "Starting $TOTAL_REQUESTS requests to $URL..."

    for ((i=1; i<=TOTAL_REQUESTS; i++)); do
        # Pick a random interval from the list
        SLEEP_TIME=${INTERVALS[$RANDOM % ${#INTERVALS[@]}]}
        
        # Perform the request and capture the HTTP status code
        # -s: silent, -o /dev/null: discard body, -w: output format
        HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" "$URL")
        
        # Increment the count for this specific status code
        ((status_counts[$HTTP_CODE]++))
        
        echo "Request $i: Received $HTTP_CODE (Next wait: ${SLEEP_TIME}s)"
        
        # Wait for the interval before the next request (unless it's the last one)
        if [ $i -lt $TOTAL_REQUESTS ]; then
            sleep $SLEEP_TIME
        fi
    done

    echo -e "\n--- Final Results ---"
    for code in "${!status_counts[@]}"; do
        echo "Response $code: ${status_counts[$code]} times"
    done
    ```
</br>


## Testing the Use Cases
### Inter namespace routing
In Kubernetes, Inter-namespace routing is a common architecture where a shared Ingress Controller (the "front door") resides in one namespace, but the actual applications (the "tenants") live in others.

Even though the Ingress Controller and your Service are in different namespaces, they communicate seamlessly because Kubernetes Networking is flat—meaning every Pod can reach every Service across the entire cluster by default.

From the **ns-and-apps-cafe.yaml** manifest file, it will create new namespace **_apps-cafe_**, then deploy several service on this new namespace. Our Nginx Plus Ingress Controller will stay on namespace **_nginx-ingress_**, but it will be able to discover service on the different namespace, which apps-cafe on this case, and routed traffic there. 

The Nginx Plus Ingress Controller VirtualServer should be created inside **_apps-cafe_** namespace, while the F5 CIS VirtualServer will be created inside **_nginx-ingress_** namespace. When all object created and successfully deployed, then the inter namespace routing will work as expected.

In our lab, one of the key on how it is possible is because the RBAC that we deployed during Nginx Plus Ingress Controller installation, that will permit Nginx Plus Ingress Controller to work across all namespaces in the cluster.
</br>

### TLS termination on BIG-IP and Nginx Plus Ingress Controller
When applying the **nic-vs-cafe-adv-routing.yaml** manifest file, we can see:
    - On the Nginx Plus Ingress Controller spec.tls, it will used the **cafe-secret** secret that was created before for doing TLS termination (offloading on this case) when handling incoming request
    - For the F5 CIS, we are creating a **TLSProfile** named **bridging-tls-profile-npl**, that will do TLS termination with mode bridging (termination: reencrypt). For the clientside SSL, it will used the same **cafe-secret** secret cert & key, and for the serverside SSL it will used the preconfigured **serverssl-insecure-compatible** profile on BIGIP. Because using combination of clientside and serverside SSL profile, then the **reference** on the manifest are using **hybrid** mode.

On the F5 CIS VirtualServer **cis-vs-cafe-443-npl** creation, it will also attaching the iRules **/Common/irules-sni** that must be manually configured on BIG-IP as a prerequsites as mention above. This iRules will pass the SNI extension flag on the serverside, which then will be used by Nginx Plus Ingress Controller to determine on how to handle the incoming request.

### Advanced Routing Scenario
Basically all scenario here are doing advanced routing, where Nginx Plus Ingress Controller will do routing in various conditions.
1. When requesting to URI /tea with method POST, it will routed to service _tea-post_
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
    Server name: tea-post-ff7789454-g997n <<--- routed to service tea-post
    Date: 05/Mar/2026:15:21:07 +0000
    URI: /tea
    Request ID: f533fa08c8ea44634be43538c4f2991c
    ```

2. When requesting to URI /tea with all other method, it will routed to service _tea_
    ```
    curl -ik https://cafe.f5demo.io/tea
    ```

    Expected result:
    ```
    HTTP/1.1 200 OK
    Server: nginx/1.29.3
    Date: Thu, 05 Mar 2026 15:25:50 GMT
    Content-Type: text/plain
    Content-Length: 156
    Connection: keep-alive
    Expires: Thu, 05 Mar 2026 15:25:49 GMT
    Cache-Control: no-cache
    Set-Cookie: BIGipServer~kubernetes~Shared~svc_nginx_ingress_npl_443_nginx_ingress_cafe_f5demo_io=117506314.19182.0000; path=/; Httponly; Secure

    Server address: 192.168.1.16:8080
    Server name: tea-6fbfdcb95d-qfb9h <<--- routed to service tea
    Date: 05/Mar/2026:15:25:50 +0000
    URI: /tea
    Request ID: e83dcd104bac90c2ee2110d197f648d4
    ```

3. When requesting to URI /coffee with cookies "v2", it will routed to service _coffee-v2_
    ```
    curl -ik https://cafe.f5demo.io/coffee --cookie "version=v2"
    ```

    Expected result:
    ```
    HTTP/1.1 200 OK
    Server: nginx/1.29.3
    Date: Thu, 05 Mar 2026 15:27:56 GMT
    Content-Type: text/plain
    Content-Length: 165
    Connection: keep-alive
    Expires: Thu, 05 Mar 2026 15:27:55 GMT
    Cache-Control: no-cache
    Set-Cookie: BIGipServer~kubernetes~Shared~svc_nginx_ingress_npl_443_nginx_ingress_cafe_f5demo_io=117506314.19182.0000; path=/; Httponly; Secure

    Server address: 192.168.2.10:8080
    Server name: coffee-v2-677787799d-kqkhh <<---
    Date: 05/Mar/2026:15:27:56 +0000
    URI: /coffee
    Request ID: 9739f2d304c2ac3cd7e6efd13a0bf863
    ```

4. When requesting to URI /coffee without custom cookie, it will routed to service _coffee-v1_
    ```
    curl -ik https://cafe.f5demo.io/coffee
    ```

    Expected result:
    ```
    HTTP/1.1 200 OK
    Server: nginx/1.29.3
    Date: Thu, 05 Mar 2026 15:29:42 GMT
    Content-Type: text/plain
    Content-Length: 163
    Connection: keep-alive
    Expires: Thu, 05 Mar 2026 15:29:41 GMT
    Cache-Control: no-cache
    Set-Cookie: BIGipServer~kubernetes~Shared~svc_nginx_ingress_npl_443_nginx_ingress_cafe_f5demo_io=117506314.19182.0000; path=/; Httponly; Secure

    Server address: 192.168.2.9:8080
    Server name: coffee-v1-767764946-wj2qq <<----
    Date: 05/Mar/2026:15:29:42 +0000
    URI: /coffee
    Request ID: fbd65a25ffda7a11c6f71be9f1c760f3
    ```
    </br>

### JWT Authentication Scenario
This use case shows how to enforce JWT authentication at the Nginx Plus Ingress Controller level. It will show how Nginx Plus Ingress Controller will inspect request to check it's authentication header, pass every authenticated request, and reject the unauthorized access.

1. Simulate unauthorized request without token
    ```
    curl -ik https://cafe.f5demo.io/webapp
    ```

    Request will be rejected and received **401 Unauthorized** response:
    ```
    HTTP/1.1 401 Unauthorized
    Server: nginx/1.29.3
    Date: Thu, 05 Mar 2026 15:33:35 GMT
    Content-Type: text/html
    Content-Length: 179
    Connection: keep-alive
    WWW-Authenticate: Bearer realm="MyProductAPI"
    Set-Cookie: BIGipServer~kubernetes~Shared~svc_nginx_ingress_npl_443_nginx_ingress_cafe_f5demo_io=117506314.19182.0000; path=/; Httponly; Secure

    <html>
    <head><title>401 Authorization Required</title></head>
    <body>
    <center><h1>401 Authorization Required</h1></center>
    <hr><center>nginx/1.29.3</center>
    </body>
    </html>
    ```

2. Simulate request with JWT token on request header
    ```
    curl -ik https://cafe.f5demo.io/webapp -H "token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IjAwMDEifQ.eyJuYW1lIjoiUXVvdGF0aW9uIFN5c3RlbSIsInN1YiI6InF1b3RlcyIsImlzcyI6Ik15IEFQSSBHYXRld2F5In0.ggVOHYnVFB8GVPE-VOIo3jD71gTkLffAY0hQOGXPL2I"
    ```

    Request will be accepted and received **200 OK** response:
    ```
    HTTP/1.1 200 OK
    Server: nginx/1.29.3
    Date: Thu, 05 Mar 2026 15:35:01 GMT
    Content-Type: text/plain
    Content-Length: 162
    Connection: keep-alive
    Expires: Thu, 05 Mar 2026 15:35:00 GMT
    Cache-Control: no-cache
    Set-Cookie: BIGipServer~kubernetes~Shared~svc_nginx_ingress_npl_443_nginx_ingress_cafe_f5demo_io=117506314.19182.0000; path=/; Httponly; Secure

    Server address: 192.168.2.20:8080
    Server name: webapp-7b7dfbff54-fx6w6
    Date: 05/Mar/2026:15:35:01 +0000
    URI: /webapp
    Request ID: f88b2c66308ed80fea5d920309ea1410
    ```
    </br>

### Traffic Splitting Scenario
This use case configures traffic splitting for a sample application with two services: coffee-v1-svc and coffee-v2-svc 70% of the coffee application traffic is sent to coffee-v1-svc the remaining 30% to coffee-v2-svc. To simulate a series of 100 requests, test access using the script provided. It sends 100 requests and shows the traffic split ratio

```
./test.sh
```

Output should be similar to:
```
Summary of responses:
Coffee v1: 70 times
Coffee v2: 30 times
```
</br>

### Rate Limiting Scenario
This use case applies rate limiting for an application exposed through Nginx Plus Ingress Controller. The **rate-limit-policy** will limit request with maximum 3 request/seconds. Run the rate-limit-test.sh script:
```
./rate-limit-test.sh
```

Output should be similar to:
```
--- Final Results ---
Response 429: 27 times
Response 200: 73 times
```