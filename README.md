# aks-infra

Setup of an aks cluster with terraform.

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

## Initialize
```bash
terraform init -upgrade
```

## apply scripts and start provisioning (takes ~8 minutes)
```bash
terraform apply --auto-approve
```

## Cleanup afterwars to destroy all ressources
```bash
terraform destroy --auto-approve
```