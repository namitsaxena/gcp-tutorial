# Containers and Registries

## Artifact Registry

* Docs: [How To's](https://cloud.google.com/artifact-registry/docs/how-to)

* gcloud setup
  Artifact Registry does not automatically add all registry hosts to the Docker configuration file. Docker response time is significantly slower when there is a large number of configured registries. To minimize the number of registries in the configuration file, you add the hosts that you need to the file.]  
  ```
  | => gcloud auth configure-docker us-central1-docker.pkg.dev
  Adding credentials for: us-central1-docker.pkg.dev
  After update, the following will be written to your Docker config file located at [~/.docker/config.json]:
   {
    "credHelpers": {
      "us-central1-docker.pkg.dev": "gcloud"
    }
  }

  Do you want to continue (Y/n)?  Y

  Docker configuration file updated.

  # In the .docker/config.json file, it adds the following section.
  "credHelpers": {
    "us-central1-docker.pkg.dev": "gcloud"
  }

  ```

* Repository
  - Console, create a new repository for docker type images. Supply the region.
  - [Creating Repositories](https://cloud.google.com/artifact-registry/docs/manage-repos#create)
  - List
    ```
    | => gcloud artifacts repositories list
    Listing items under project nsx-sandbox, across all locations.

                                                          ARTIFACT_REGISTRY
    REPOSITORY          FORMAT  DESCRIPTION      LOCATION     LABELS  ENCRYPTION          CREATE_TIME          UPDATE_TIME
    ns-docker-registry  DOCKER  docker registry  us-central1          Google-managed key  2022-01-27T23:19:16  2022-01-27T23:19:16    
    ```

* [Authentication Options](https://cloud.google.com/artifact-registry/docs/docker/authentication)


* Pushing and listing an image
  - The maximum artifact size is 5 TB.  
  - We are pushing an [nginx-hello](https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-hello) demo image. This can be run locally using
    ```
     docker run -p 8080:80 -d nginxdemos/hello
    ```
    The web page can be acessed over: http://localhost:8080/


  ```
  | => docker tag nginxdemos/hello us-central1-docker.pkg.dev/nsx-sandbox/ns-docker-registry/nginx-hello
  | => docker push us-central1-docker.pkg.dev/nsx-sandbox/ns-docker-registry/nginx-hello
      Using default tag: latest
      The push refers to repository [us-central1-docker.pkg.dev/nsx-sandbox/ns-docker-registry/nginx-hello]  
      ...

  | => gcloud artifacts packages list --repository ns-docker-registry --location us-central1
  Listing items under project nsx-sandbox, location us-central1, repository ns-docker-registry.

  PACKAGE      CREATE_TIME          UPDATE_TIME
  nginx-hello  2022-01-27T23:54:37  2022-01-27T23:54:37  
  ```