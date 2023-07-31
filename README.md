# aks-infra

Setup of an aks cluster including argocd.

You need:
- azure cli
- terraform cli
- kubectl

## Login
```bash
az login
```

## Switch to your subscription
```bash
az account set --subscription="YOUR_SUBSCRIPTION_ID"
```

## switch to terraform dir
```bash
cd ./terraform-setup
```

## Initalize
```bash
terraform init -upgrade
```

## Cleanup afterwars to destroy all ressources
```bash
terraform destroy -upgrade
```

## switch to terraform dir
```bash
terraform apply -auto-approve
```

