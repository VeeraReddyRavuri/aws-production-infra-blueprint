# ⚔️ 4. Terraform Concurrent Apply (Locking)

# Incident: Concurrent Terraform Apply Without State Locking

## 1. Symptoms

- Multiple Terraform runs caused inconsistent state
- Duplicate resources or conflicts observed

## 2. Root Cause

Terraform was executed simultaneously without locking.

Without DynamoDB locking:
- Multiple users/processes modify state at same time

---

## 3. Debugging Steps

1. Started two Terraform applies simultaneously:

```bash
terraform apply
```

2. Observed:

- Race condition
- Resource conflicts

3. Errors like:

Error: resource already exists

## 4. Fix Applied

Enabled state locking using DynamoDB:

```json
backend "s3" {
  bucket         = "tf-state-bucket"
  key            = "dev/terraform.tfstate"
  region         = "ap-south-1"
  dynamodb_table = "terraform-lock"
}
```

## 5. Key Learnings

- Terraform state must be locked during operations
- DynamoDB ensures safe concurrent usage
- Always use remote backend in team environments