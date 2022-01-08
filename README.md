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

* Test the HTTP server: note sometime this doesn't work right away (most likely due to yum update delays which may take sometimes several minutes. same behavior in aws) (TBD). Get the public ip address from above and curl on it.
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

### VM Storage: Disks, Images and Snapshots 

* Create a snapshot of the disk from above instance
  ```
  gcloud compute disks snapshot instance-1 --project=nsx-sandbox --snapshot-names=snapshot-1 --zone=us-central1-a --storage-location=us-central1
  ```

* List Disks
  ```
  gcloud compute disks list
  ```

* List Images
  ```
  gcloud compute images list
  ```

* Create Image from Snapshot
  ```
  gcloud compute images create image-1 --project=nsx-sandbox --source-snapshot=snapshot-1 --storage-location=us
  ```

* Create a new disk using the above snapshot
  ```
  gcloud beta compute disks create disk-1-copy --project=nsx-sandbox --type=pd-standard --description=copy\ created\ from\ disk\ snapshot --size=20GB --zone=us-central1-a --source-snapshot=snapshot-1
  ```

* create a VM instance: with boot disk and additional disk both from the above snapshot. Note we didn't have to install httpd since it's already baked in the snapshot
  ```
  gcloud compute instances create instance-2 --project=nsx-sandbox --zone=us-central1-a --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=default --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --service-account=600132130055-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=http-server --create-disk=auto-delete=yes,boot=yes,device-name=instance-2,mode=rw,size=20,source-snapshot=projects/nsx-sandbox/global/snapshots/snapshot-1,type=projects/nsx-sandbox/zones/us-central1-a/diskTypes/pd-standard --create-disk=device-name=disk-1,mode=rw,name=disk-1,size=20,source-snapshot=projects/nsx-sandbox/global/snapshots/snapshot-1,type=projects/nsx-sandbox/zones/us-central1-a/diskTypes/pd-standard --reservation-affinity=any
  ```

* Listing both the disks in above instance
  ```
	[admin@instance-2 ~]$ lsblk
	NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
	sda      8:0    0   20G  0 disk 
	├─sda1   8:1    0  200M  0 part /mnt/disk2
	└─sda2   8:2    0 19.8G  0 part 
	sdb      8:16   0   20G  0 disk 
	├─sdb1   8:17   0  200M  0 part 
	└─sdb2   8:18   0 19.8G  0 part /
	[admin@instance-2 ~]$ df
	Filesystem     1K-blocks    Used Available Use% Mounted on
	devtmpfs          497480       0    497480   0% /dev
	tmpfs             505656       0    505656   0% /dev/shm
	tmpfs             505656    6732    498924   2% /run
	tmpfs             505656       0    505656   0% /sys/fs/cgroup
	/dev/sdb2       20754432 3712840  17041592  18% /
	/dev/sda1         204580   10096    194484   5% /boot/efi
	tmpfs             101132       0    101132   0% /run/user/1001
  ```

### Machine Image

* Create machine image of instance-2 above with two disks
  ```
  gcloud beta compute machine-images create instance-2-image --project=nsx-sandbox --source-instance=instance-2 --source-instance-zone=us-central1-a --storage-location=us
  ```

* Create instance directly from machine image. Again no need to install since everything is baked in. This also shows two separate disks
  ```
	[admin@instance-2-image-1 ~]$ df
	Filesystem     1K-blocks    Used Available Use% Mounted on
	devtmpfs          497480       0    497480   0% /dev
	tmpfs             505656       0    505656   0% /dev/shm
	tmpfs             505656    6732    498924   2% /run
	tmpfs             505656       0    505656   0% /sys/fs/cgroup
	/dev/sdb2       20754432 3712988  17041444  18% /
	/dev/sdb1         204580   10096    194484   5% /boot/efi
	tmpfs             101132       0    101132   0% /run/user/1001
	[admin@instance-2-image-1 ~]$ lsblk
	NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
	sda      8:0    0   20G  0 disk 
	├─sda1   8:1    0  200M  0 part 
	└─sda2   8:2    0 19.8G  0 part 
	sdb      8:16   0   20G  0 disk 
	├─sdb1   8:17   0  200M  0 part /boot/efi
	└─sdb2   8:18   0 19.8G  0 part /
  ```  
