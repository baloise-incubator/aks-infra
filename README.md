# Setup

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

## switch to terraform dir
```bash
terraform apply -auto-approve
```

