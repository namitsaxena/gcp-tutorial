# Google Cloud Platform(GCP) Tutorial
Notes and command line for testing basic features

** NOTE: most of the command line arguments can be auto created from GCP console **

## Compute Engine

### VM Instances

* Create a VM instance: This creates a very cheap instance for testing. This uses RHEL since we are using yum in startup script. Debian Images could be slightly cheaper but with lowering disk quality and preemptive they are nearly the same. This costs $2.63/month at the time of this writing. The below has a startup script to install httpd and hosts a simple static page for testing.
  ``` 
  gcloud compute instances create instance-1 --project=nsx-sandbox --zone=us-central1-a --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --metadata=startup-script=\#\!/bin/bash\ -xe$'\n'sudo\ yum\ update\ -y$'\n'sudo\ yum\ install\ -y\ httpd$'\n'sudo\ service\ httpd\ start$'\n'sudo\ chkconfig\ httpd\ on$'\n'cd\ /var/www/html$'\n'sudo\ su$'\n'echo\ \"This\ is\ a\ HTTP\ only\ Website\ running\ on\ host\ \(\$\{HOSTNAME\}\)\"\ \>\ index.html$'\n' --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --service-account=600132130055-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-2,image=projects/rhel-cloud/global/images/rhel-7-v20211214,mode=rw,size=20,type=projects/nsx-sandbox/zones/us-central1-a/diskTypes/pd-standard --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
  ```

* Create a VM instance using templae: You can create an instance template in console (or via cli), and use to create an instance. Same as above with equivalent template.
  ``` 
  gcloud compute instances create instance-1 --source-instance-template cheapest-instance-httpd 
  ```

* Test the HTTP server: note sometime this doesn't work right away until we login and do the same with localhost for some reason. (same behavior in aws so probably something to do with httpd behavior) (TBD). Get the public ip address from above and curl on it.
  ```
  curl 34.134.86.209
  ```

* SSH to the instance: basic mechanism to connect to the above instance (there are other ways aswell)
  ```
  gcloud compute ssh --project=nsx-sandbox --zone=us-central1-a instance-1
  ```

* List Instances: 
   ```
   gcloud compute instances list
   ```

* Delete Instance: 
   ```
   gcloud compute instances delete instance-1
   ```

### Disk Images