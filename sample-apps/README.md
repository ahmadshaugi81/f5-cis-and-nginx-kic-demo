# Sample Apps for Demo

We are using several apps for this lab. We already prepared the manifest to deploy the demo apps, which at some manifest already including the service creation.

- hello-nginx-with-svc.yaml --> Deployment manifest using ```ahmadshaugi81/hello-nginx``` images for very simple demo, only to show proxying process is success. Include _nodeport_ service creation in the manifest. Both **hello-nginx-with-svc.yaml** & **hello-nginx.yaml** are creating service with exactly same name. Be aware to update the service name when need to deploy both manifest in the same time.
- hello-nginx.yaml --> Deployment manifest using ```ahmadshaugi81/hello-nginx``` images for very simple demo, only to show proxying process is success. Include _clusterip_ service creation in the manifest. Both **hello-nginx-with-svc.yaml** & **hello-nginx.yaml** are creating service with exactly same name. Be aware to update the service name when need to deploy both manifest in the same time.
- Nginx Demo Apps (Will be added soon for several use cases!)