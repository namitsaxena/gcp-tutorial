# Containers and Registries

## Create a container and Push to GCR
   See [Containers.md](Containers.md)

## Create a Service
  * Using Console
    * specify the GCR image
    * specify the container port to expose
    * Ingress: allow all traffic
    * Authentication: allow unauthenticated requests
    * Min Number of Instances: 0 (1 for keeping it warm)
    * Access on the URL specified: https://nginx-hello-kk3kws6gka-uc.a.run.app/
    * DNS mapping: you can map one of your verified domains or subdomains
      * DNS mapping provides with a CNAME record which you can add to your name provider
    * Observations
      * based on 'container instance count'  metrics the containers were active only when we accessed the URL which is expected since we set the min number to 0.
      * even after a day the web page was served almost instantly despite no running containers
  * Using gcloud
    * Creating a service
      ```
      gcloud run deploy nginx-hello-world-1 --image us-central1-docker.pkg.dev/nsx-sandbox/ns-docker-registry/nginx-hello:latest --min-instances=0 --max-instances=2 --port 80 --region us-central1 --allow-unauthenticated
      ```

      Interactive command prompt
      ```
      gcloud run deploy --image us-central1-docker.pkg.dev/nsx-sandbox/ns-docker-registry/nginx-hello:latest --max-instances=2
      
      Service name (nginx-hello):  nginx-hello-tmp
      Please specify a region:
       [1] asia-east1
       [23] us-central1
      Please enter your numeric choice:  23

      To make this the default region, run `gcloud config set run/region us-central1`.

      Allow unauthenticated invocations to [nginx-hello-tmp] (y/N)?  y

      Deploying container to Cloud Run service [nginx-hello-tmp] in project [nsx-sandbox] region [us-central1]
      ```    
    * List services
      ```
      | => gcloud run services list
         SERVICE          REGION       URL                                          LAST DEPLOYED BY       LAST DEPLOYED AT
      ✔  nginx-hello      us-central1  https://nginx-hello-kk3kws6gka-uc.a.run.app  namitsaxena@gmail.com  2022-01-28T06:16:06.761795Z
      X  nginx-hello-tmp  us-central1
      ```
    * Delete a service
      ```
      gcloud run services delete nginx-hello-tmp --region us-central1
      ```  

  * Notes
    It may take several minutes to create a service, esp if it's failing. (typical issue could be incorrect container port in service which assumes it to be 8080 by default)