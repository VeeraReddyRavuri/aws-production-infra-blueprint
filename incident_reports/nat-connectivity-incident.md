# Incident Report: Private EC2 Unable to Access Internet via NAT Instance

## Summary
Private EC2 instance in a private subnet was unable to reach the internet despite NAT instance configuration.

## Architecture
- VPC: 10.0.0.0/16
- Public Subnet: 10.0.1.0/24 (NAT, Bastion)
- Private Subnet: 10.0.2.0/24 (Application EC2)
- NAT Instance used for outbound internet access

## Impact
- Private EC2 could not:
  - Ping external IPs (8.8.8.8)
  - Access internet (curl failed)
- Blocked ability to install packages / external communication

## Timeline of Debugging

### 1. Verified NAT instance internet access
- `curl google.com` → SUCCESS  
- Conclusion: IGW + public subnet working

### 2. Verified private EC2 routing
- `ip route` showed default via VPC router (10.0.2.1)  
- Conclusion: subnet routing correct

### 3. Verified route table
- `0.0.0.0/0 → NAT ENI`  
- Conclusion: VPC routing correct

### 4. Verified NAT instance configuration
- Enabled `ip_forward`
- Configured iptables MASQUERADE
- Added FORWARD rules  
- Still failed

## Root Cause

NAT instance Security Group did not allow traffic from VPC CIDR.

### Incorrect:
- Allowed inbound from `0.0.0.0/0`

### Correct:
- Must allow inbound from `10.0.0.0/16`

## Resolution

Updated NAT security group:

- Allowed all traffic from `10.0.0.0/16`
- Retained outbound access to internet

## Validation

From private EC2:

```bash
ping 8.8.8.8 → SUCCESS
curl google.com → SUCCESS
```

## Key Learnings
- Routing ≠ connectivity
- Security Groups can silently block traffic even if routing is correct
- NAT requires:
    - OS-level config (iptables, ip_forward)
    - AWS-level config (route tables, SG)

## Preventive Measures
- Always validate:
    - Route tables
    - Security groups
    - Instance-level networking
- Use structured debugging approach:
    - Source
    - Route
    - Target
    - Firewall