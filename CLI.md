# Basic Command Line Usage

## gcloud

* [gcloud](https://cloud.google.com/sdk/gcloud) [cheatsheet(official)](https://cloud.google.com/sdk/docs/cheatsheet)

* create a new configuration
  ```
  gcloud init
  ```
* configuration
  ```
  gcloud config list
  gcloud config set compute/zone us-central1-b
  ```
* list all configurations available
  ```
  gcloud config configurations list
  ``` 
* activate a configuration
  ```
  gcloud config configurations activate my-cfg
  ```
* List the account your are authenticated to
  ```
  gcloud config get-value account
  ```

  ```
  | => gcloud auth list
      Credentialed Accounts
  ACTIVE  ACCOUNT
  *       n********@gmail.com
  ```
* configure gcloud with a service account - see [IAM](IAM.md)
* List Organizations
  ```
  gcloud organizations list
  ```
* List Projects
  ```
  | => gcloud projects list
  PROJECT_ID          NAME                PROJECT_NUMBER
  ....
  ```
* Get active project  
  ```
  gcloud config get-value project
  ```

* Configuration Sample: create and configure a new configuration
  ```
  gcloud config configurations create test-cfg --activate
  gcloud config set account my.email@gmail.com
  gcloud config set project nsx-sandbox
  gcloud config set compute/region us-central1
  gcloud config set compute/zone us-central1-a
  gcloud config list  
  ```