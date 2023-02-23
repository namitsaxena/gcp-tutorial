#!/bin/bash
#############################################################
# script to demonstrate impersonation by a service account
#############################################################

# user account required to create the accounts
v_user_account="UPDATE_THIS_WITH_YOUR_USER_ID" #TODO remove, don't add @gmail.com

v_gcp_project="nsx-sandbox"
# service account that will be used for impersonating (could be available on a CI server, etc)
v_sa_impersonator="impersonator"
# SA that will have access to the project resources
v_sa_worker="worker"

function createSA()
{
	v_sa_name="$1"
	echo "creating SA: ${v_sa_name}"
	gcloud iam service-accounts create ${v_sa_name} --description="impersonation demo SA" --display-name="${v_sa_name}"
	
	echo "creating key for SA: ${v_sa_name}"
	gcloud iam service-accounts keys create ${v_sa_name}.json --iam-account=${v_sa_name}@${v_gcp_project}.iam.gserviceaccount.com

	echo "activating SA: ${v_sa_name}"
	gcloud auth activate-service-account ${v_sa_name}@${v_gcp_project}.iam.gserviceaccount.com --key-file=./${v_sa_name}.json
}

function deleteSA()
{
	v_sa_name="$1"
	echo "deleting SA: ${v_sa_name}"
	gcloud iam service-accounts delete ${v_sa_name}@${v_gcp_project}.iam.gserviceaccount.com --quiet

	echo "deleting local key file for SA: ${v_sa_name}"
	rm ./${v_sa_name}.json
}

function cleanup()
{
	gcloud config set account ${v_user_account}@gmail.com
	deleteSA ${v_sa_impersonator}
	deleteSA ${v_sa_worker}	
}

# reset to start from scratch each time (comment if needed)
cleanup

# CREATE service accounts
gcloud config set account ${v_user_account}@gmail.com
createSA ${v_sa_impersonator}

gcloud config set account ${v_user_account}@gmail.com
createSA ${v_sa_worker}


# CONFIGURE POLICIES
gcloud config set account ${v_user_account}@gmail.com
gcloud config get-value account

echo "** Granting worker SA read permissions for the project"
#let's grant project read access to the worker account (attached to project) --verbosity=debug
gcloud projects add-iam-policy-binding ${v_gcp_project} --member="serviceAccount:${v_sa_worker}@${v_gcp_project}.iam.gserviceaccount.com" --role="roles/viewer"
# gcloud projects get-iam-policy {v_gcp_project}

echo "** Granting impersonator SA permissions to impersonate worker"
# allow impersonator SA to impersonate the worker SA
# we need to explicity member type by prefixing with 'serviceAccount:' (defaults to user)
#  else error INVALID_ARGUMENT: The member impersonator@nsx-sandbox.iam.gserviceaccount.com is of an unknown type. Please set a valid type prefix for the member
# see https://cloud.google.com/sdk/gcloud/reference/alpha/functions/add-iam-policy-binding#REQUIRED-FLAGS
gcloud iam service-accounts add-iam-policy-binding ${v_sa_worker}@${v_gcp_project}.iam.gserviceaccount.com --member="serviceAccount:${v_sa_impersonator}@${v_gcp_project}.iam.gserviceaccount.com" --role="roles/iam.serviceAccountUser" --role="roles/iam.serviceAccountTokenCreator" 
gcloud iam service-accounts get-iam-policy ${v_sa_worker}@${v_gcp_project}.iam.gserviceaccount.com


# testing
# activate impersonator
gcloud auth activate-service-account ${v_sa_impersonator}@${v_gcp_project}.iam.gserviceaccount.com --key-file=./${v_sa_impersonator}.json
gcloud config get-value account

# test impersonation
echo "** Testing without impersonation (should fail)"
gcloud iam service-accounts list

echo "** Testing with impersonation (should work since we have given read permissions to the worker sa). This may take a few mins though"
for i in {1..15} ; do
	gcloud iam service-accounts list --impersonate-service-account="${v_sa_worker}@${v_gcp_project}.iam.gserviceaccount.com" 
	if [[ $? -eq 0 ]] ; then
		break
	fi	
	sleep 15
done

# if the above still fails, run below manually a couple of times
# gcloud iam service-accounts list --impersonate-service-account=worker@nsx-sandbox.iam.gserviceaccount.com

gcloud config set account ${v_user_account}@gmail.com