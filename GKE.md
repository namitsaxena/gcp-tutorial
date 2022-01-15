# GKE Clusters

## Autopilot Clusters

* Create an Autopilot Cluster (using default settings)
  ```
  gcloud container --project "nsx-sandbox" clusters create-auto "autopilot-cluster-1" --region "us-central1" --release-channel "regular" --network "projects/nsx-sandbox/global/networks/default" --subnetwork "projects/nsx-sandbox/regions/us-central1/subnetworks/default" --cluster-ipv4-cidr "/17" --services-ipv4-cidr "/22"
  ```

* kubectl: configuration to connect to the above cluster
  ```
  gcloud container clusters get-credentials autopilot-cluster-1 --region us-central1 --project nsx-sandbox
  ```  

* delete the cluster
  ```
  gcloud container clusters delete cluster-2
  ```

* Test the new cluster:
  ```
  # set the namespace
  kubectl config set-context --current --namespace=default

  kubectl cluster-info
  
  kubectl get nodes

  # run a simple nginx pod (http port 80 within the cluster)
  kubectl run nginx --image=nginx
  kubectl run get pods
  ```  

* Access the pod port (for temporary testing or debugging)
  * use kubectl port forwarding.
  *	Expose as nodeport service

* Create a Standard GKE cluster: We are creating a zonal cluster using a e2 micro (to keep the costs low) 
  ```
  gcloud beta container --project "nsx-sandbox" clusters create "cluster-1" --zone "us-central1-a" --no-enable-basic-auth --cluster-version "1.21.5-gke.1302" --release-channel "regular" --machine-type "e2-micro" --image-type "COS_CONTAINERD" --disk-type "pd-standard" --disk-size "50" --metadata disable-legacy-endpoints=true --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --max-pods-per-node "110" --preemptible --num-nodes "1" --logging=SYSTEM,WORKLOAD --monitoring=SYSTEM --enable-ip-alias --network "projects/nsx-sandbox/global/networks/default" --subnetwork "projects/nsx-sandbox/regions/us-central1/subnetworks/default" --no-enable-intra-node-visibility --default-max-pods-per-node "110" --no-enable-master-authorized-networks --addons HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver --enable-autoupgrade --enable-autorepair --max-surge-upgrade 1 --max-unavailable-upgrade 0 --enable-shielded-nodes --node-locations "us-central1-a"
  ```