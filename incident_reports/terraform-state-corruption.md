# 💣 2. Terraform State Corruption

# Incident: Terraform State File Corruption

## 1. Symptoms

- Terraform apply failed unexpectedly
- Errors related to missing resources or duplicate creation

## 2. Root Cause

State file was renamed/missing:
```bash
mv terraform.tfstate terraform.tfstate.backup
```
Terraform lost track of existing resources.

## 3. Debugging Steps

1. Ran:
```bash
terraform apply
```

2. Observed:
- Resource already exists

3. Checked state:
```bash
terraform state list
```
- No resources found

4. Verified AWS:
- Resources still exist

## 4. Fix Applied

Restored state file:
```bash
mv terraform.tfstate.backup terraform.tfstate
```

OR re-imported resources:
```bash
terraform import aws_instance.private_ec2 <instance-id>
```

## 5. Key Learnings

- State file is critical for Terraform
- Losing state = losing control of infrastructure
- Always use remote backend (S3 + DynamoDB)
- Never manually modify or delete state