# GKE Clusters

* Create an **Autopilot Cluster** (using default settings)

  ```
  # short, regional must be specified since 'Autopilot clusters must be regional clusters'
  gcloud container --project "nsx-sandbox" clusters create-auto "autopilot-cluster-1" --region "us-central1" 

  # or with more options
  gcloud container --project "nsx-sandbox" clusters create-auto "autopilot-cluster-1" --region "us-central1" --release-channel "regular" --network "projects/nsx-sandbox/global/networks/default" --subnetwork "projects/nsx-sandbox/regions/us-central1/subnetworks/default" --cluster-ipv4-cidr "/17" --services-ipv4-cidr "/22"
  ```

* Create a **Standard** GKE cluster: We are creating a zonal cluster using a e2 micro (to keep the costs low) 
  ```
  gcloud beta container --project "nsx-sandbox" clusters create "cluster-1" --zone "us-central1-a" --no-enable-basic-auth --cluster-version "1.21.5-gke.1302" --release-channel "regular" --machine-type "e2-micro" --image-type "COS_CONTAINERD" --disk-type "pd-standard" --disk-size "50" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --max-pods-per-node "110" --preemptible --num-nodes "1" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/nsx-sandbox/global/networks/default" --subnetwork "projects/nsx-sandbox/regions/us-central1/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes --node-locations "us-central1-a"
  ```

* kubectl: configuration to connect to the above cluster
  ```
  gcloud container clusters get-credentials autopilot-cluster-1 --region us-central1 --project nsx-sandbox
  ```  

* delete the cluster
  ```
  gcloud container clusters delete cluster-2
  ```

* Test the new cluster (basic):
  ```
  # set the namespace
  kubectl config set-context --current --namespace=default

  kubectl cluster-info
  
  kubectl get nodes
  ```  

* Test the cluster (run something):
  Run a simple pod. Running pods can be seen in console under 'Workloads'
  ```
  kubectl run nginx-1 --image=nginx
  kubectl get pods

  # exec into the container and test localhost
  # since the service is not exposed outside (also autopilot doesn't assign public ip to the nodes so NodePort won't work either)
  | => kubectl exec -it nginx-1 -- bash
  root@nginx-1:/# curl localhost
  <!DOCTYPE html>
  <html>

  # Access the nginx pod using kubectl port-forwarding
  # alternatively we can also expose this a ClusterIP service and use port-forwarding on that
  | => kubectl port-forward nginx-1 8080:80 
  Forwarding from 127.0.0.1:8080 -> 80
  Forwarding from [::1]:8080 -> 80
  Handling connection for 8080
  Handling connection for 8080

  Access the pod in browser: http://localhost:8080/
  ```

  Run a deployment and expose as a LoadBalancer servie do that it gets an external ip to connect to. This automatcally creates a load balancer which is also available in Network services -> Load Balancing (and has the two cluster nodes associated with it). The service is visible both via kubectl and in console kubernetes Engine -> Services and Ingress.
  ```
  # create a deployment 
  kubectl create deployment nginx --image=nginx:latest 
  kg deployments -o yaml
  kubectl get pods
  
  # create a LoadBalancer service for this deployment
  kubectl expose deployment nginx --port 80 --type LoadBalancer

  # | => kg svc
  NAME         TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
  kubernetes   ClusterIP      10.8.128.1     <none>           443/TCP        30m
  nginx        LoadBalancer   10.8.129.187   104.198.68.245   80:31298/TCP   93s

  # test/access the exposed service
  # go to the external IP above or open in browser: https://104.198.68.245/
  | => curl 104.198.68.245
  <!DOCTYPE html>
  ...

  # cleanup
  kubectl delete svc nginx
  kubectl delete deploy nginx

  ```