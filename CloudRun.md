# Cloud Run

## Create a container and Push to GCR
   See [Containers.md](Containers.md)

## Configuration (Misc)
   Set region: useful (if not set you need to specify it with each command) 
   ```
   gcloud config set run/region us-central1
   ```

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
    * creating a service using manifest yaml file
      See [Copying a service](https://cloud.google.com/run/docs/managing/services#copy): typically using the exported yaml and renaming the service name is not sufficient and may give errors
      * create a yaml file
        ```
        apiVersion: serving.knative.dev/v1
        kind: Service
        metadata:
          name: nginx-hello-yml
          labels:
            cloud.googleapis.com/location: us-central1
          annotations:
            autoscaling.knative.dev/maxScale: "100"
        spec:
          template:
            spec:
              containerConcurrency: 80
              timeoutSeconds: 300
              containers:
              - image: us-central1-docker.pkg.dev/nsx-sandbox/ns-docker-registry/nginx-hello@sha256:f5a0b2a5fe9af497c4a7c186ef6412bb91ff19d39d6ac24a4997eaed2b0bb334
                ports:
                - name: http1
                  containerPort: 80
                resources:
                resources:
                  limits:
                    cpu: "1"
                    memory: 512Mi
                # optional
                env:
                - name: LOG_LEVEL
                  value: debug        
        ``` 
      * deploy
        ```
         gcloud run services replace cloud-run-nginx-hello.yaml --region us-central1
        ```
      * Allowing unauthenticated access: By default, the above will give the following error: Error: Forbidden Your client does not have permission to get URL / from this server, when accessed using it's URL.
        To allow unauthenticated invocations, add "allUsers" as a principal and assign it the "Cloud Run invoker" role. See [Allowing public (unauthenticated) access](https://cloud.google.com/run/docs/authenticating/public#command-line)
        ```
        gcloud run services add-iam-policy-binding nginx-hello-yml --member="allUsers" --role="roles/run.invoker"
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

  * Further reading
    * [Cloud Run Docs](https://cloud.google.com/run/docs#docs)
    * Build and deploy
      * [Hello Cloud Run - cloud skill boost](https://www.cloudskillsboost.google/focuses/5162?parent=catalog)
      * [Deploy a website with Cloud Run - codelabs](https://codelabs.developers.google.com/codelabs/cloud-run-deploy#0)
      * [Deploying to Cloud Run](https://cloud.google.com/build/docs/deploying-builds/deploy-cloud-run#cloud-run_1)
      * [Simplifying Continuous Deployment to Cloud Run with Cloud Build including Custom Domain Setup(SSL) - medium](https://medium.com/google-cloud/simplifying-continuous-deployment-to-cloud-run-with-cloud-build-including-custom-domain-setup-ssl-22d23bed5cd6)
    * Setup a CD pipeline to continously deploy changes: setup cloud build to build a conatiner, setup triggers and automatically create a new revision  
      

  * Notes
    * the service urls are https by default (http gets redirect to https). See [Invoking with an HTTPS Request](https://cloud.google.com/run/docs/triggering/https-request)
    * It may take several minutes to create a service if it's failing (see timeout value). (typical issue could be incorrect container port in service which assumes it to be 8080 by default)