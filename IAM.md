# GCP IAM

### Basic Notes
* The policy is attached to a resource. You can attach **only one** IAM policy to each resource(ex: project, compute engine). This is sufficient since it can have multiple policy bindings.
  Because of above the mechanism is the same regardless of resource (ie project or storage or pubsub) - you call the same methods on each resource to view, add policy bindings, etc
* Resources inherit the policies of all of their parent resources(transitive ie all the way up). It's a union of inherited and directly applied policies. 
  * So to grant a user/service account access to all instances of a resource (ex all buckets in a project), add policy binding at 'project' (or folder, etc) for the user with  the role (say, roles/storage.admin)
  * If you want to grant access for a specific instance of the resource (ex: one particular bucket), then add policy binding at the specific resource(for the specific bucket or cloud-run service. See below)
* policy changes sometimes take some time to take effect
* If you get ```PreconditionException: 412 At least one of the pre-conditions you specified did not hold.```, typically on setting iam policy via JSON, get the latest etag and make sure that's what you are setting the in JSON
  

### Roles

* List all predefined roles
  Example to filter all [cloud storage roles](https://cloud.google.com/iam/docs/understanding-roles#cloud-storage-roles)
  ```
  gcloud iam roles list | grep 'roles/storage'
  ```


### Service Accounts
Can be both identities and resources.

* [Manage access to Service Accounts](https://cloud.google.com/iam/docs/manage-access-service-accounts)
* [Creating and Managing](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
  ```
  gcloud iam service-accounts create my-test-sa --description="my test service account" --display-name="my-test-sa-tmp"
  Created service account [my-test-sa]
  ```
* List
  ```
  gcloud iam service-accounts list
  ```

* Allow Impersonating this Service Account (See [this](https://cloud.google.com/iam/docs/creating-managing-service-accounts#creating) and [this](https://cloud.google.com/iam/docs/manage-access-service-accounts#grant-single-role))
  Let's grant the owner/principal user (me) to impersonate this service account (which is somewhat redundant since i already have access to all resources). To create short-lived credentials for service accounts, or to use the --impersonate-service-account flag for the Google Cloud CLI, you also need the Service Account Token Creator role.
  ```
  gcloud iam service-accounts add-iam-policy-binding my-test-sa@nsx-sandbox.iam.gserviceaccount.com --member="user:my.email@gmail.com" --role="roles/iam.serviceAccountUser" --role="roles/iam.serviceAccountTokenCreator"
  ```

* [Impersonate](https://cloud.google.com/iam/docs/impersonating-service-accounts#allow-impersonation)
  Let's impersonate the above SA (ie I(my.email@gmail.com) am impersonating this account without using the token. gcloud has '--impersonate-service-account=yourSAID' option to allow this 
  Please note that we gave this SA view access to our project(see below)
  ```
  | => gcloud iam service-accounts list --impersonate-service-account=my-test-sa@nsx-sandbox.iam.gserviceaccount.com
  WARNING: This command is using service account impersonation. All API calls will be executed as [my-test-sa@nsx-sandbox.iam.gserviceaccount.com].
  WARNING: This command is using service account impersonation. All API calls will be executed as [my-test-sa@nsx-sandbox.iam.gserviceaccount.com].
  DISPLAY NAME                            EMAIL                                               DISABLED
  my-test-sa-tmp                          my-test-sa@nsx-sandbox.iam.gserviceaccount.com      False
  ```
  However if we try to run the list projects it will fail since this SA does not have these permissions. (the api had to be reenabled again for this SA~?)
  ```
  | => gcloud projects list --impersonate-service-account=my-test-sa@nsx-sandbox.iam.gserviceaccount.com
  WARNING: This command is using service account impersonation. All API calls will be executed as [my-test-sa@nsx-sandbox.iam.gserviceaccount.com].
  API [cloudresourcemanager.googleapis.com] not enabled on project [600132130055]. Would you like to enable and retry (this will take a few minutes)? (y/N)?  y

  Enabling service [cloudresourcemanager.googleapis.com] on project [600132130055]...
  WARNING: This command is using service account impersonation. All API calls will be executed as [my-test-sa@nsx-sandbox.iam.gserviceaccount.com].
  ERROR: (gcloud.projects.list) PERMISSION_DENIED: Permission denied to enable service [cloudresourcemanager.googleapis.com]  
  ```

* Impersonate with gsutil
  ```
  gsutil -i my-test-sa@nsx-sandbox.iam.gserviceaccount.com ls
  gsutil -i my-test-sa@nsx-sandbox.iam.gserviceaccount.com ls gs://namits
  ```  
 
* View Access: To see **who has** access to your service account(it's a **resource** in this case - it does not show what the account can access), get the IAM policy for the service account (may not list inherited policies).
  ```
  gcloud iam service-accounts get-iam-policy my-test-sa@nsx-sandbox.iam.gserviceaccount.com
  ```
  The above would show the user we allowed to impersonate this account
  ```
  bindings:
  - members:
    - user:my.email@gmail.com
    role: roles/iam.serviceAccountUser
  etag: BwXXomB3Tsw=
  version: 1  
  ```

* Setting the policy (to update or create multiple entries/changes at once)
  This accomplishes the same thing as above
  - get the existing policy and save to a file
    ```
    gcloud iam service-accounts get-iam-policy my-test-sa@nsx-sandbox.iam.gserviceaccount.com --format=json > sa-policy.json
    ``` 
  - update the policy file
  - set the new policy file
    ```
    gcloud iam service-accounts set-iam-policy my-test-sa@nsx-sandbox.iam.gserviceaccount.com sa-policy.json
    ```  
* [Service Account Keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)
  - [Creating service account keys](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating)
    ```
    gcloud iam service-accounts keys create my-test-sa.json --iam-account=my-test-sa@nsx-sandbox.iam.gserviceaccount.com
    ```
    This will create a key file my-test-sa.json in current dir(we can specify the path)
  - listing keys
    ```
    gcloud iam service-accounts keys list --iam-account my-test-sa@nsx-sandbox.iam.gserviceaccount.com
    ```  
    This may list two keys. Apparently one key gets created with service account creation
  - configuring gcloud with service account
    [gcloud auth activate-service-account](https://cloud.google.com/sdk/gcloud/reference/auth/activate-service-account)
    ```
    gcloud auth activate-service-account my-test-sa@nsx-sandbox.iam.gserviceaccount.com --key-file=./my-test-sa.json
    ```
    Optionally, it's also preferable to run the above with a new gcloud configuration. Use 'gcloud init' to create a new configuration(cancel when it comes to authentication) and activate the above.
    


### [Manage access to projects, folders, and organizations](https://cloud.google.com/iam/docs/granting-changing-revoking-access)

Only lists accounts/service accounts with access to the resource level specified (ie to project/folder/etc )
NOTE: in our case the my-cloud-run SA only has access to GCS storage bucket (And not to the project itslef) so does not get listed here.

* [View Access](https://cloud.google.com/iam/docs/granting-changing-revoking-access#view-access) (get-iam-policy)
  To view who has access to your organization/folders/projects. Ex: below for project. 
  ```
  gcloud projects get-iam-policy nsx-sandbox --format=json
  ```

* Grant Access (add-iam-policy-binding)
  Let's grant our test service account read access to the whole project and all of it's resources (since they will inherit this)
  We will give basic viewer [role](https://cloud.google.com/iam/docs/understanding-roles)
  ```
  gcloud projects add-iam-policy-binding nsx-sandbox --member="serviceAccount:my-test-sa@nsx-sandbox.iam.gserviceaccount.com" --role="roles/viewer"
  ```
  The above list the updated binding (same that you get with get-iam-policy nsx-sandbox).
  ```
  - members:
    - serviceAccount:my-test-sa@nsx-sandbox.iam.gserviceaccount.com
    role: roles/viewer
  ```  

### [Other Resources](https://cloud.google.com/iam/docs/manage-access-other-resources)
In Identity and Access Management (IAM), access is managed through IAM policies. An IAM policy **is attached to a Google Cloud resource**. Each policy contains a collection of role bindings that associate one or more principals, such as users or service accounts, with an IAM role. These role bindings grant the specified roles to the principals, both on the resource that the policy is attached to and on all of that **resource's descendants**. 

To get the IAM policy for the resource, run the get-iam-policy command for the resource. (Note: A resource's IAM policy **does not show any roles gained through policy inheritance**. To view inherited roles, use the Cloud Console.)

* Cloud Run: get iam policy for a specific service
  Note below shows that allUsers have the invoker role so that they can access this service.
  ```
  | => gcloud run services get-iam-policy nginx-hello
  bindings:
  - members:
    - allUsers
    role: roles/run.invoker
  etag: BwXWnjxVKKA=
  version: 1
  ```  

* GCS Storage: get iam policy bindings for a specific bucket
  ```
  gsutil iam get gs://namits
  ```

* Artifact registry
  ```
  gcloud artifacts repositories get-iam-policy ns-docker-registry --location us-central1
  ```

### Sample Scenario
The following lists a simple scenario to create a new service account, grant our principal user(owner) to impersonate it and give it read access only to a specific bucket.
This uses the basic commands described in the rest of the document

1. create the service account
   ```
   gcloud iam service-accounts create my-bucket-sa --description="sa to read namits bucket" --display-name="my-bucket-sa-tmp"
   ```
2. create the service account key
   ```
   gcloud iam service-accounts keys create my-bucket-sa.json --iam-account=my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com
   ```
2. Configure gcloud to use the service account using the key generated above
   ```
   gcloud auth activate-service-account my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com --key-file=./my-bucket-sa.json
   ```   
2. Allow it to be impersonated by the owner (for testing)
   ```
   gcloud iam service-accounts add-iam-policy-binding my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com --member="user:my.email@gmail.com" --role="roles/iam.serviceAccountUser" --role="roles/iam.serviceAccountTokenCreator"   
   ```
3. create policy on one of the buckets to read a specific path
   get the policy
   ```
   gsutil iam get gs://namits > bucket.json
   ```

   Add the binding to json file
   ```
    {
      "members": [
        "serviceAccount:my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectViewer"
    }
   ```

   Set the policy back
   ```
   gsutil iam set bucket.json gs://namits
   ```
4. Test the service account
   doesn't allow you list all bucket, but you can do ls on the bucket (since the permissions are only for a specific bucket)
   ```
    | => gsutil -i my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com ls 
    WARNING: This command is using service account impersonation. All API calls will be executed as [my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com].
    AccessDeniedException: 403 my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com does not have storage.buckets.list access to the Google Cloud project.   

    | => gsutil -i my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com ls gs://namits
    WARNING: This command is using service account impersonation. All API calls will be executed as [my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com].
    gs://namits/test.txt
    gs://namits/data/   
   ```

   Note: specifying condition to restrict based on resource name **didn't work(below)** (as described [here](https://cloud.google.com/iam/docs/conditions-overview))
   ```
    ,{
      "condition": {
        "description": "Grant bucket service account access to only to a specific path in the bucket",
        "expression": "resource.type == \"storage.googleapis.com/Bucket\" && resource.name.startsWith(\"projects/_/buckets/namits/data\")",
        "title": "access to only data/ in the bucket"
      },
      "members": [
        "serviceAccount:my-bucket-sa@nsx-sandbox.iam.gserviceaccount.com"
      ],
      "role": "roles/storage.objectViewer"
    }

   ```   


  