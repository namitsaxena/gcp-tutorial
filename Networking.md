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
  Routes may have issues in being deleted before subnets have been deleted (give cryptic errors). Routes which couldn't be deleted before disappareaed after subnets were deleted (It deleted only one that was created separately but couldn't delete the other 2 default routes - 'The local route cannot be deleted') - TBD ([protected resources?](https://github.com/genevieve/leftovers/issues/71).
  ```
  gcloud compute routes delete default-route-c79a53f1246f86a9 default-route-fa2c06c93ede9518 internet-route
  ```  
* VPC
  ```
  gcloud compute networks delete my-vpc
  ```



