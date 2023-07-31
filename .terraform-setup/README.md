# Setup

https://foxutech.medium.com/how-to-create-azure-kubernetes-service-using-terraform-2f744473b5a7

az login

az account set --subscription="064c5254-2ba8-42ea-891d-1499413f70c5"

az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/064c5254-2ba8-42ea-891d-1499413f70c5

-> set vars in terraform.tfvars

