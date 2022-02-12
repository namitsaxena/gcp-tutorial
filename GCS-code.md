# GCS Code Samples

## Prerequisites
* Setup Buckets
  - the code use one public and one private bucket
* Setup Service Account
  - with adequate access to read the private bucket
    - See [IAM](IAM.md#sample-scenario)
  - public bucket doesn't need any authentication

## Python

* code to read an object from the bucket
  ```python
  from google.cloud import storage


  def get_bucket(bucket_name, service_account_key_file=None):
      print(f"Reading Bucket: {bucket_name}")
      # create storage client
      if service_account_key_file:
          storage_client = storage.Client.from_service_account_json(service_account_key_file)
      else:
          storage_client = storage.Client.create_anonymous_client()

      # get bucket with name
      # project needs to be set to None esp if accessing public buckets
      return storage_client.bucket(bucket_name=bucket_name, user_project=None)


  def get_object(bucket, object_name):
      # get bucket data as blob
      blob = bucket.get_blob(object_name)
      # convert to string
      return blob.download_as_string()


  # Press the green button in the gutter to run the script.
  if __name__ == '__main__':
      service_account_key = './my-bucket-sa.json'

      bucket = get_bucket("namits", service_account_key)
      obj = get_object(bucket, "test.txt")
      print(f'Data: {obj}')

      # key file not needed for public bucket
      bucket = get_bucket("terraform-registry", None)
      obj = get_object(bucket, "data.txt")
      print(f'Data: {obj}')
  ```


## References
* [feedbackReading and Writing to Cloud Storage](https://cloud.google.com/appengine/docs/standard/python/googlecloudstorageclient/read-write-to-cloud-storage)
* [Cloud Run - Build and deploy a Python service](https://cloud.google.com/run/docs/quickstarts/build-and-deploy/python)
