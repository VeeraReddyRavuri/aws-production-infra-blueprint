# 🔁 3. Ansible Idempotency Failure

# Incident: Non-Idempotent Ansible Tasks

## 1. Symptoms

- Running playbook multiple times resulted in changes
- Tasks marked as "changed" even when no updates required

## 2. Root Cause

Certain tasks were not idempotent:

Example:
- iptables rules appended every run
- Docker container recreated unnecessarily

---

## 3. Debugging Steps

1. Ran playbook twice:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

2. Observed:
- changed=3

3. Identified problematic tasks:

- iptables rules
- container deployment

## 4. Fix Applied

Added conditional checks:

Example:

```YAML
- name: Check MASQUERADE rule
  command: iptables -C POSTROUTING -o ens5 -j MASQUERADE
  register: masq_check
  failed_when: false
  changed_when: false
```

Only add rule if missing:

```YAML
when: masq_check.rc != 0
```

## 5. Key Learnings

- Idempotency is core principle of configuration management
- Always validate state before applying changes
- Re-running playbook should produce: changed = 0