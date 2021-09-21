
# Create a demo pod 

## YAML location

```
cd yaml/demo-ns

```
# Kubenet Cluster

 ```
 k config use-context aks-basic
 k create ns demo-ns
 k apply -f deployment.yaml 
 k apply -f service-internal-lb.yaml 

``` 

## Observe the POD and NODE IPs in different networks

```
k get pods,service,nodes -n demo-ns -o wide
NAME                                    READY   STATUS    RESTARTS   AGE   IP            NODE                                NOMINATED NODE   READINESS GATES
pod/nginx-deployment-6c46465cc6-6l6zt   1/1     Running   0          73m   10.244.1.15   aks-nodepool1-62766439-vmss000002   <none>           <none>
pod/nginx-deployment-6c46465cc6-npv4k   1/1     Running   0          73m   10.244.0.15   aks-nodepool1-62766439-vmss000001   <none>           <none>
pod/nginx-deployment-6c46465cc6-z6gmz   1/1     Running   0          73m   10.244.2.15   aks-nodepool1-62766439-vmss000000   <none>           <none>

NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE   SELECTOR
service/nginx-service-internal   LoadBalancer   10.101.43.199   172.16.239.7   8080:31125/TCP   73m   app=nginx

NAME                                     STATUS   ROLES   AGE   VERSION    INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
node/aks-nodepool1-62766439-vmss000000   Ready    agent   64d   v1.19.11   172.16.239.4   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-62766439-vmss000001   Ready    agent   64d   v1.19.11   172.16.239.5   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-62766439-vmss000002   Ready    agent   64d   v1.19.11   172.16.239.6   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure

```


# Advanced CNI

## Observe POD And NODE IPs in the same subnet
```
 k config use-context aks-advanced
 k create ns demo-ns
 k apply -f deployment.yaml 
 k apply -f service-internal-lb.yaml 

```

```
k get pods,service,nodes -n demo-ns -o wide
NAME                                    READY   STATUS    RESTARTS   AGE    IP              NODE                                NOMINATED NODE   READINESS GATES
pod/nginx-deployment-6c46465cc6-ghhn7   1/1     Running   0          100s   172.16.240.12   aks-nodepool1-38290826-vmss000000   <none>           <none>
pod/nginx-deployment-6c46465cc6-j7gpw   1/1     Running   0          100s   172.16.240.43   aks-nodepool1-38290826-vmss000001   <none>           <none>
pod/nginx-deployment-6c46465cc6-tm2sp   1/1     Running   0          100s   172.16.240.80   aks-nodepool1-38290826-vmss000002   <none>           <none>

NAME                             TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE   SELECTOR
service/nginx-service-internal   LoadBalancer   10.101.136.122   172.16.240.97   8080:30219/TCP   75s   app=nginx

NAME                                     STATUS   ROLES   AGE   VERSION    INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
node/aks-nodepool1-38290826-vmss000000   Ready    agent   63d   v1.19.11   172.16.240.4    <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-38290826-vmss000001   Ready    agent   63d   v1.19.11   172.16.240.35   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
node/aks-nodepool1-38290826-vmss000002   Ready    agent   63d   v1.19.11   172.16.240.66   <none>        Ubuntu 18.04.5 LTS   5.4.0-1049-azure   containerd://1.4.4+azure
```

# Cleanup
k delete ns demo-ns



# Create an API

k apply -f api.yaml
k get pods,service -o wide -n app-ns
NAME                                  READY   STATUS    RESTARTS   AGE     IP            NODE                                NOMINATED NODE   READINESS GATES
pod/app-deployment-658fdb4c98-9gkj8   1/1     Running   0          4m23s   10.244.1.16   aks-nodepool1-62766439-vmss000002   <none>           <none>
pod/app-deployment-658fdb4c98-9xz7h   1/1     Running   0          4m23s   10.244.0.16   aks-nodepool1-62766439-vmss000001   <none>           <none>
pod/app-deployment-658fdb4c98-blghg   1/1     Running   0          4m23s   10.244.2.16   aks-nodepool1-62766439-vmss000000   <none>           <none>

NAME                           TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE    SELECTOR
service/app-service-internal   LoadBalancer   10.101.11.159   172.16.239.7   3000:32309/TCP   100s   app=app


k describe service app-service-internal -n app-ns
Name:                     app-service-internal
Namespace:                app-ns
Labels:                   <none>
Annotations:              service.beta.kubernetes.io/azure-load-balancer-internal: true
Selector:                 app=app
Type:                     LoadBalancer
IP Families:              <none>
IP:                       10.101.11.159
IPs:                      <none>
LoadBalancer Ingress:     172.16.239.7
Port:                     <unset>  3000/TCP
TargetPort:               3000/TCP
NodePort:                 <unset>  32309/TCP
Endpoints:                10.244.0.16:3000,10.244.1.16:3000,10.244.2.16:3000
Session Affinity:         None
External Traffic Policy:  Cluster
Events:
  Type    Reason                Age   From                Message
  ----    ------                ----  ----                -------
  Normal  EnsuringLoadBalancer  15m   service-controller  Ensuring load balancer
  Normal  EnsuredLoadBalancer   13m   service-controller  Ensured load balancer

## validations
curl http://172.16.239.7:3000/red
red

## Cleanup
k delete ns app-ns