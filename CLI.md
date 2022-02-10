# Basic Command Line Usage

## gcloud

* [gcloud](https://cloud.google.com/sdk/gcloud) [cheatsheet(official)](https://cloud.google.com/sdk/docs/cheatsheet)

* configuration
  ```
  gcloud config list
  gcloud config set compute/zone us-central1-b
  ```

* List the account your are authenticated to
  ```
  | => gcloud auth list
      Credentialed Accounts
  ACTIVE  ACCOUNT
  *       n********@gmail.com
  ```

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
