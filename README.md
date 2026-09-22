# Read-Only Infrastructure Agent

AI agent skills and safety hook for read-only AWS/Kubernetes infrastructure investigation.

## Overview

This project provides skills that teach AI agents (Claude, Claude Code, omp) how to investigate EKS/Kubernetes infrastructure without the ability to modify or destroy resources.

```
┌─────────────────────────────────────────────────┐
│                   AI Agent                      │
│                      │                          │
│                      ▼                          │
│              ┌──────────────┐                   │
│              │    Skills    │ ← what to check   │
│              └──────────────┘                   │
│                      │                          │
│                      ▼                          │
│              ┌──────────────┐                   │
│              │ Safety Hook  │ ← blocks writes   │
│              └──────────────┘                   │
│                      │                          │
│          ┌──────────┴──────────┐               │
│          ▼                     ▼               │
│    ┌──────────┐          ┌──────────┐          │
│    │ kubectl  │          │ AWS CLI  │          │
│    └──────────┘          └──────────┘          │
└─────────────────────────────────────────────────┘
```

## Skills

| Skill | Description |
|-------|-------------|
| **k8s-investigation** | kubectl patterns for pods, deployments, nodes, logs, events |
| **aws-investigation** | AWS CLI patterns for EKS, EC2, CloudWatch, S3, load balancers |
| **diagnostic-workflows** | Step-by-step diagnosis for CrashLoopBackOff, OOMKilled, NotReady, etc. |
| **safety-hook** | Documentation + script that blocks dangerous operations |

## Installation

### Claude (claude.ai)

1. Go to **Settings > Skills**
2. Click **Add Skill**
3. Upload each skill folder from `skills/` as a ZIP

### Claude Code / omp

```bash
# Copy skills to your user directory
cp -r skills/* ~/.omp/agent/skills/

# Or to a specific project
cp -r skills/* /path/to/project/.omp/skills/
```

### Safety Hook Setup

The safety hook blocks dangerous commands before execution:

```bash
# Copy the hook script
cp skills/safety-hook/readonly-infra.sh ~/.local/bin/infra-hook
chmod +x ~/.local/bin/infra-hook

# Test it
infra-hook kubectl get pods        # ✓ allowed
infra-hook kubectl delete pod x    # ✗ blocked
infra-hook aws eks describe-cluster --name x  # ✓ allowed
infra-hook aws iam list-users      # ✗ blocked
```

## Hook Performance

The safety hook is optimized for minimal latency (~5ms per command check). Optimizations include:
- No subprocesses (pure bash with `BASH_REMATCH`)
- O(1) allowlist lookup via `case` statements
- Early exit for non-infrastructure commands

## What's Allowed vs Blocked

### Allowed (read-only)
- `kubectl get`, `describe`, `logs`, `top`, `version`
- `aws * describe-*`, `list-*`, `get-*`
- `aws s3 ls`, `aws s3 cp s3://... -` (download)

### Blocked (write operations)
- `kubectl apply`, `delete`, `exec`, `scale`, `edit`, `patch`
- `kubectl drain`, `cordon`, `taint`
- `aws iam *` (all IAM operations)
- `aws * delete-*`, `create-*`, `modify-*`, `terminate-*`
- `aws s3 rm`, `aws s3 cp ... s3://` (upload)
- `env`, `printenv` (credential protection)

## Example Usage

Once skills are installed, ask Claude:

- "Why is my pod in CrashLoopBackOff?"
- "Check the EKS cluster health for prod-cluster"
- "Show me CloudWatch logs for the api service"
- "What's causing memory pressure on node ip-10-0-1-42?"

Claude will use the investigation skills to run appropriate read-only commands.

## Security Model

This is **application-level filtering**, not IAM-based:

- The hook blocks commands before execution
- Underlying AWS credentials may have broader permissions
- Defense in depth: combine with short-lived STS credentials

For production, consider:
1. Short-lived STS session credentials (1 hour expiry)
2. CloudTrail monitoring for unexpected API patterns
3. Agent transcript review

## Project Structure

```
skills/
├── README.md
├── k8s-investigation/
│   └── skill.md
├── aws-investigation/
│   └── skill.md
├── diagnostic-workflows/
│   └── skill.md
└── safety-hook/
    ├── skill.md
    └── readonly-infra.sh
```

## License

MIT
