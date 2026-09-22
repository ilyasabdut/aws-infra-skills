# Read-Only Infrastructure Agent

AI agent skills and safety hook for read-only AWS/Kubernetes infrastructure investigation.

## Overview

This project enables AI agents (like Hermes on omp) to investigate EKS/Kubernetes infrastructure without the ability to modify or destroy resources.

```
┌─────────────────────────────────────────────────────────┐
│                    AI Agent                             │
│                       │                                 │
│                       ▼                                 │
│               ┌──────────────┐                          │
│               │   Skills     │  ← what to investigate   │
│               └──────────────┘                          │
│                       │                                 │
│                       ▼                                 │
│               ┌──────────────┐                          │
│               │  Safety Hook │  ← blocks dangerous ops  │
│               └──────────────┘                          │
│                       │                                 │
│            ┌──────────┴──────────┐                      │
│            ▼                     ▼                      │
│        kubectl                aws cli                   │
│            │                     │                      │
│            ▼                     ▼                      │
│          EKS                 AWS APIs                   │
└─────────────────────────────────────────────────────────┘
```

## Components

### Skills (`.omp/skills/`)

| Skill | Description |
|-------|-------------|
| `k8s-investigation` | kubectl patterns for pods, deployments, nodes, events, logs |
| `aws-investigation` | AWS CLI patterns for EKS, EC2, CloudWatch, S3 |
| `diagnostic-workflows` | Step-by-step procedures for common issues |
| `safety-hook` | Documentation of what's blocked and why |

### Safety Hook

| File | Purpose |
|------|---------|
| `.omp/extensions/readonly-infra-hook.ts` | **Primary** — omp TypeScript extension (auto-loads) |
| `.omp/hooks/readonly-infra.sh` | Bash fallback for Claude Code or manual testing |
| `.omp/hooks/readonly-infra.yaml` | Configuration reference |

## Quick Start

### 1. Set AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."  # if using STS
export AWS_DEFAULT_REGION="ap-southeast-1"
```

### 2. Configure kubeconfig

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

### 3. The Hook is Automatic (omp)

When you start `omp` in this directory, the extension at `.omp/extensions/readonly-infra-hook.ts` auto-loads. No configuration needed.

To verify it's working:
```bash
# In an omp session, try a blocked command - it should fail with a message
kubectl delete pod test
# Expected: "Blocked: kubectl delete is a write operation..."
```

### Manual Testing (without omp)

```bash
# Test the bash script directly
.omp/hooks/readonly-infra.sh kubectl delete pod test
# Output: BLOCKED: kubectl delete is a write operation...

.omp/hooks/readonly-infra.sh kubectl get pods -n default
# (no output, exit 0 = allowed)
```

## What's Allowed

### kubectl

- `get`, `describe`, `logs`, `top`
- `api-resources`, `api-versions`, `cluster-info`, `version`
- `config view`, `config get-contexts`, `config current-context`
- `rollout status` (read-only)

### AWS CLI

- `describe-*`, `list-*`, `get-*` across most services
- `aws s3 ls`, `aws s3 cp s3://... -` (download to stdout)
- CloudWatch logs and metrics queries

## What's Blocked

### kubectl

- `apply`, `create`, `delete`, `patch`, `edit`, `replace`
- `exec`, `cp`, `port-forward`, `attach`, `debug`
- `scale`, `rollout` (except status)
- `drain`, `cordon`, `uncordon`, `taint`

### AWS CLI

- All `aws iam` operations
- `delete-*`, `terminate-*`, `create-*`, `modify-*`, `update-*`, `put-*`
- `aws s3 rm`, `aws s3 mv`, uploads to S3
- `aws sts assume-role`

### Credential Protection

- `env`, `printenv`, `export` (bare)
- `/proc/*/environ` access
- `echo $AWS_SECRET*`

### Bypass Prevention

- `python* boto3`, `python -c "import boto*"`
- `curl *.amazonaws.com`

## Usage Examples

### Diagnose a crashing pod

```bash
kubectl describe pod api-xxx -n production
kubectl logs api-xxx -n production --previous
kubectl get events -n production --field-selector involvedObject.name=api-xxx
```

### Check EKS cluster health

```bash
aws eks describe-cluster --name my-cluster --query 'cluster.status'
aws eks list-nodegroups --cluster-name my-cluster
kubectl get nodes
kubectl top nodes
```

### Investigate node issues

```bash
kubectl describe node ip-10-0-1-123
aws ec2 describe-instance-status --instance-ids i-0123456789
```

## Project Structure

```
.omp/
├── extensions/
│   └── readonly-infra-hook.ts      # omp TypeScript extension (primary)
├── skills/
│   ├── k8s-investigation/SKILL.md
│   ├── aws-investigation/SKILL.md
│   ├── diagnostic-workflows/SKILL.md
│   └── safety-hook/SKILL.md
└── hooks/
    ├── readonly-infra.sh           # Bash fallback
    ├── readonly-infra.yaml         # Configuration reference
    └── readonly_infra_hook.py      # Python alternative
```

## Security Model

This is **application-level filtering**, not IAM-based security:

- The hook blocks commands before execution
- Underlying AWS credentials may have broader permissions
- Defense in depth: use with short-lived STS credentials
- Not a security boundary against determined adversaries

For production use, consider:
1. Short-lived STS session credentials (1 hour expiry)
2. CloudTrail monitoring for unexpected API patterns
3. Agent transcript review
4. Network-level controls if possible

## License

MIT
