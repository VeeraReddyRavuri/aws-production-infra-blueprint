# Incident: Terraform Drift Due to Manual Resource Deletion

## 1. Symptoms

- Infrastructure appeared healthy in AWS Console
- However, Terraform state was outdated
- Running `terraform plan` showed unexpected changes

## 2. Root Cause

A resource (EC2 instance) was manually deleted in AWS console.

Terraform state still believed:
- Resource exists

Actual AWS state:
- Resource missing

This created **drift** between:
- Terraform state
- Real infrastructure

---

## 3. Debugging Steps

1. Ran Terraform plan:

   ```bash
   terraform plan
    ```

2. Observed:

+ create aws_instance.private_ec2

3. Verified in AWS:

- EC2 instance was missing

4. Compared with Terraform state:

```bash
terraform state list
```

## 4. Fix Applied

Re-applied infrastructure:
```bash
terraform apply -var-file="dev.tfvars"
```
Terraform recreated missing resource.

## 5. Key Learnings

- Terraform does NOT auto-detect external changes
- `terraform plan` is the primary tool to detect drift
- Never modify infra manually in production
- State is source of truth — not AWS console