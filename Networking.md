# Networking


## Creating
* create a VPC with [Dynamic routing mode](https://cloud.google.com/network-connectivity/docs/router/how-to/configuring-routing-mode)(also see [route advertisement mode](https://cloud.google.com/network-connectivity/docs/router/concepts/overview#route-advertisement))
  ```
  gcloud compute networks create my-vpc --project=nsx-sandbox --description="Test VPC" --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
  ```
  ```
  Created [https://www.googleapis.com/compute/v1/projects/nsx-sandbox/global/networks/my-vpc].
  NAME    SUBNET_MODE  BGP_ROUTING_MODE  IPV4_RANGE  GATEWAY_IPV4
  my-vpc  CUSTOM       REGIONAL

  Instances on this network will not be reachable until firewall rules
  are created. As an example, you can allow all internal traffic between
  instances as well as SSH, RDP, and ICMP by running:

  $ gcloud compute firewall-rules create <FIREWALL_NAME> --network my-vpc --allow tcp,udp,icmp --source-ranges <IP_RANGE>
  $ gcloud compute firewall-rules create <FIREWALL_NAME> --network my-vpc --allow tcp:22,tcp:3389,icmp  
  ```
* create subnet (subnets are region specific)
  we are also specifying a secondary ip range (this is optional)
  ```
  gcloud compute networks subnets create subnet-us-central-1 --project=nsx-sandbox --range=10.0.0.0/24 --network=my-vpc --region=us-central1 --secondary-range=my-range-2=192.168.0.0/24
  ```
* Routes - get automatically created
  ```
  | => gcloud compute routes list --filter="network=my-vpc"  
  NAME                            NETWORK  DEST_RANGE      NEXT_HOP                  PRIORITY
  default-route-14768f4cbd442b94  my-vpc   192.168.0.0/24  my-vpc                    0
  default-route-497bb39719a7ce35  my-vpc   10.0.0.0/24     my-vpc                    0
  default-route-e4562a7cf53dcd7c  my-vpc   0.0.0.0/0       default-internet-gateway  1000	
  ```
* create firewall rules
  - all internal 
    ```
    gcloud compute firewall-rules create my-vpc-allow-custom --project=nsx-sandbox --network my-vpc --direction=INGRESS --priority=65534 --source-ranges=10.0.0.0/24 --action=ALLOW --rules=all --description=Allows\ connection\ from\ any\ source\ to\ any\ instance\ on\ the\ network\ using\ custom\ protocols. 

    ```  
  - allow ssh
    ```
    gcloud compute firewall-rules create my-vpc-allow-ssh --project=nsx-sandbox --network my-vpc --direction=INGRESS --priority=65534 --source-ranges=0.0.0.0/0 --action=ALLOW --rules=tcp:22 --description="Allows TCP connections from\ any source to any instance on the network using port 22"
    ```  
  - allow http
    ```
    gcloud compute firewall-rules create my-vpc-allow-app-ports --network my-vpc --allow tcp:80,icmp
    ```  
    Created with priority of 1000
    ```
	Creating firewall...⠹Created [https://www.googleapis.com/compute/v1/projects/nsx-sandbox/global/firewalls/my-vpc-allow-app-ports].                                                                                                           
	Creating firewall...done.                                                                                                                                                                                                                    
	NAME                    NETWORK  DIRECTION  PRIORITY  ALLOW        DENY  DISABLED
	my-vpc-allow-app-ports  my-vpc   INGRESS    1000      tcp:80,icmp        False    
    ```

## Listing
* VPC
  ```
  gcloud compute networks list
  ```
* Subnets
  ```
  gcloud compute networks subnets list --network=my-vpc
  ```  
* Firewalls
  ```
  gcloud compute firewall-rules list --filter="network=my-vpc"
  ```
* Routes
  ```
  gcloud compute routes list --filter="network=my-vpc"
  ```  

## Deleting 
Before you can delete the VPC, you need to remove the resources assocaited with it (ex: firewall).

* Firewalls
  ```
  gcloud compute firewall-rules delete my-vpc-allow-custom my-vpc-allow-http my-vpc-allow-ssh 
  ```
* Subnets
  ```
  gcloud compute networks subnets delete subnet-us-central-1 --region us-central1
  ```
* Routes
  Routes may have issues in being deleted before subnets have been deleted (give cryptic errors). Routes which couldn't be deleted before disappareaed after subnets were deleted (It deleted only one that was created separately but couldn't delete the other 2 default routes - 'The local route cannot be deleted') - TBD ([protected resources?](https://github.com/genevieve/leftovers/issues/71)).
  ```
  gcloud compute routes delete default-route-c79a53f1246f86a9 default-route-fa2c06c93ede9518 internet-route
  ```  
* VPC
  ```
  gcloud compute networks delete my-vpc
  ```

## Scenario
Create a VPC with subnets in different regions. Create instances in each and test traffic between the two. Update routes to control the traffic.
Manage firewalls and tags using tags.
 - open instance with firewall tag for http/icmp/ssh port
 - open instance with route to internet gateway with tag

* create a VPC network with two regions (and subnets)
  ```
  gcloud compute networks create my-mutiregion-vpc --project=nsx-sandbox --description="vpc spanning multiple regions" --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional

  gcloud compute networks subnets create my-subnet-1 --project=nsx-sandbox --range=10.0.0.0/24 --network=my-mutiregion-vpc --region=us-central1

  gcloud compute networks subnets create my-subnet-2 --project=nsx-sandbox --range=10.0.1.0/24 --network=my-mutiregion-vpc --region=us-east1 --enable-private-ip-google-access
  ```

* create a firewall rule for typical access (http/https/ssh/icmp). This will be tag controlled using tag 'myaccess' defined below
  ```
  gcloud compute --project=nsx-sandbox firewall-rules create my-instance-access --description="typical access - http, https, ssh, icmp" --direction=INGRESS --priority=1000 --network=my-mutiregion-vpc --action=ALLOW --rules=tcp:80,tcp:443,tcp:22,icmp --source-ranges=0.0.0.0/0 --target-tags=myaccess
  ```

* create a route for internet access. This will be tag controlled using tag 'my-internet-access' defined below (we will also remove the regular internet route that got automatically created with subnet) - so by default no instance will have internet access unless this tag is applied to an instance.
  ```
  gcloud beta compute routes create my-instances-internet-route --project=nsx-sandbox --description="Tagged route to allow specific instances access to internet" --network=my-mutiregion-vpc --priority=1000 --tags=my-internet-access --destination-range=0.0.0.0/0 --next-hop-gateway=default-internet-gateway
  ```
  ```
  | => gcloud compute routes list --filter="network=my-mutiregion-vpc" 
  NAME                            NETWORK            DEST_RANGE   NEXT_HOP                  PRIORITY
  default-route-bb1df236379c2d35  my-mutiregion-vpc  10.0.1.0/24  my-mutiregion-vpc         0
  default-route-c14bd8d4e3b92a71  my-mutiregion-vpc  0.0.0.0/0    default-internet-gateway  1000
  default-route-f1f3dd5a93e9e3f4  my-mutiregion-vpc  10.0.0.0/24  my-mutiregion-vpc         0
  my-instances-internet-route     my-mutiregion-vpc  0.0.0.0/0    default-internet-gateway  1000
  ```
  ```
  gcloud compute routes delete default-route-c14bd8d4e3b92a71
  ```

* create an instance in my-subnet-1 (region 1)
  - my-subnet-1 (when the region is specified, only this one will show up on the console)
  - NOTE: firewall tag 'myaccess' has been applied to allow access via SSH/ICMP/HTTP
  - NOTE: Since the internet gateway route tag hasn't been applied yet, The http server would fail to install since this instance doesn't have a route to the internet
  ```
  gcloud compute instances create instance-1 --project=nsx-sandbox --zone=us-central1-a --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=my-subnet-1 --metadata=startup-script=\#\!/bin/bash\ -xe$'\n'sudo\ apt\ update$'\n'sudo\ apt\ install\ apache2 --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --service-account=600132130055-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=myaccess --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-10-buster-v20220118,mode=rw,size=10,type=projects/nsx-sandbox/zones/us-central1-a/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
  ```

* create an instance in my-subnet-2 (region 2) 
  - All the notes from instance-1 above apply to this too
  ```
  gcloud compute instances create instance-2 --project=nsx-sandbox --zone=us-east1-b --machine-type=e2-micro --network-interface=network-tier=PREMIUM,subnet=my-subnet-2 --metadata=startup-script=\#\!/bin/bash\ -xe$'\n'sudo\ apt\ update$'\n'sudo\ apt\ install\ apache2 --no-restart-on-failure --maintenance-policy=TERMINATE --preemptible --service-account=600132130055-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --tags=myaccess --create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/debian-cloud/global/images/debian-10-buster-v20220118,mode=rw,size=10,type=projects/nsx-sandbox/zones/us-central1-a/diskTypes/pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any
  ```

* Verify internet access for the above instances (no access)
  - regular ssh access doesn't work (this doesn't work)
  ```
  gcloud compute ssh --project=nsx-sandbox --zone=us-east1-b instance-2
  ```
  - ssh access with IAP will still work
  ```
  gcloud compute ssh --zone "us-central1-a" "instance-1"  --tunnel-through-iap --project "nsx-sandbox"

  ```
  - instance can't do apt update because it has no internet access
  ```
  admin@instance-1:~$ sudo apt update
  Err:1 http://packages.cloud.google.com/apt cloud-sdk-buster InRelease
    Could not connect to packages.cloud.google.com:80 (74.125.201.138), connection timed out Could not connect to packages.cloud.google.com:80 (74.125.201.100), connection timed out Could not connect to packages.cloud.google.com:80 (74.125.201.101), connection timed out Could not connect to packages.cloud.google.com:80 (74.125.201.139), connection timed out Could not connect to packages.cloud.google.com:80 (74.125.201.102), connection timed out Could not connect to packages.cloud.google.com:80 (74.125.201.113), connection timed out
    ...
  ```
  - Instance-1 can reach instance-2 since ICMP is enabled (even though the 'bgp-routing-mode' is regional). We can ping the instance-2 from instance-1 using it's internal IP address (but not through external IP address)
  ```
  hostname -I
  10.0.0.2 
  admin@instance-1:~$ ping 10.0.1.2
  PING 10.0.1.2 (10.0.1.2) 56(84) bytes of data.
  64 bytes from 10.0.1.2: icmp_seq=1 ttl=64 time=31.7 ms
  64 bytes from 10.0.1.2: icmp_seq=2 ttl=64 time=31.0 ms
  --- 10.0.1.2 ping statistics ---
  6 packets transmitted, 6 received, 0% packet loss, time 11ms
  rtt min/avg/max/mdev = 30.978/31.128/31.702/0.257 ms

  admin@instance-1:~$ ping 35.196.96.175
  PING 35.196.96.175 (35.196.96.175) 56(84) bytes of data.
  ^C
  --- 35.196.96.175 ping statistics ---
  7 packets transmitted, 0 received, 100% packet loss, time 158ms
  ```

* Add internet route tag to instance-1 (to give access to it)
  ```
  gcloud compute instances add-tags instance-1 --zone us-central1-a --tags my-internet-access
  ```

* Check internet access again (after adding the route above)
  - regular ssh should work now
  ```
  gcloud compute ssh --project=nsx-sandbox --zone=us-east1-b instance-1
  ```  
  - apt update will work and we can install http server (and can be accssed from anywhere)
  - from instance-2 (Which still doesn't have internet access), we can reach instance-1 using it's internal address
  ```
  admin@instance-2:~$ hostname -I
  10.0.1.2 
  admin@instance-2:~$ ping 10.0.0.2 
  PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
  64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=128 ms
  64 bytes from 10.0.0.2: icmp_seq=2 ttl=64 time=125 ms
  ^C
  --- 10.0.0.2 ping statistics ---
  2 packets transmitted, 2 received, 0% packet loss, time 2ms
  rtt min/avg/max/mdev = 125.228/126.714/128.200/1.486 ms
  admin@instance-2:~$ curl 10.0.0.2 

  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml">  
  ...
  ```
* cleanup
  ```
  gcloud compute instances delete instance-1
  gcloud compute instances delete instance-2
  ```  

## Misc ToDo's
  * create shared project to host VPCs
  * Install NAT Gateway to allow installing software
  * Create private VPC (convert subnet-2 to private by removing external ip, and no routes as before)