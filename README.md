# Read-Only Infrastructure Agent

[![Test Hook](https://github.com/ilyasabdut/aws-infra-skills/actions/workflows/test.yml/badge.svg)](https://github.com/ilyasabdut/aws-infra-skills/actions/workflows/test.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/v/release/ilyasabdut/aws-infra-skills)](https://github.com/ilyasabdut/aws-infra-skills/releases)

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
| **aws-investigation** | AWS CLI patterns for EKS, EC2, CloudWatch, S3, RDS, Lambda, SQS, SNS, Route53, Secrets Manager, SSM, ECS, DynamoDB, API Gateway, ElastiCache, Step Functions, EventBridge, CloudFront, WAF, Kinesis, CodeBuild, CodePipeline, Auto Scaling, ACM, Cognito, OpenSearch, Redshift, Athena, CloudTrail, EFS, Service Quotas, Cost Explorer, Glue, EMR, Backup, Security Hub, GuardDuty, Inspector, Config, X-Ray |
| **diagnostic-workflows** | Step-by-step diagnosis for pod crashes, RDS, Lambda, SQS, ALB, EC2, API Gateway, CloudFront, DynamoDB, ElastiCache, Step Functions, Kinesis, CodeBuild, CodePipeline, EventBridge, Cognito, OpenSearch, ECS, Auto Scaling, SNS, WAF, Route53, ACM, Secrets Manager, S3, SSM, VPC, CloudTrail, EFS, Service Quotas, Redshift, Athena, Glue, EMR, Backup, Cost Explorer, Security Hub, GuardDuty, Inspector, Config, X-Ray |
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
- `aws *` with 132 mutation verb patterns:
  - CRUD: `delete-`, `create-`, `put-`, `remove-`, `update-`, `modify-`
  - Lifecycle: `terminate-`, `start-`, `stop-`, `reboot-`, `enable-`, `disable-`, `suspend-`, `resume-`
  - Attachment: `attach-`, `detach-`, `register-`, `deregister-`, `associate-`, `disassociate-`
  - Security: `authorize-`, `revoke-`
  - Resource: `import-`, `copy-`, `allocate-`, `release-`, `cancel-`
  - Approval: `accept-`, `reject-`
  - Tagging: `tag-resource`, `untag-resource`
  - Messaging: `send-`, `invoke`, `publish`, `send-command`
  - Compute: `run-`
  - Execution: `execute-`
  - Configuration: `set-`, `reset-`, `change-`
  - Recovery: `restore-`, `failover-`, `promote-`, `revert-`, `switchover-`
  - Movement: `move-`, `migrate-`
  - Batch: `batch-write-`, `batch-delete-`, `batch-put-`, `batch-associate-`, `batch-disassociate-`, `batch-update-`, `batch-import-`
  - Replacement: `replace-`
  - Provisioning: `request-`, `purchase-`, `provision-`, `deprovision-`
  - Assignment: `assign-`, `unassign-`
  - Submission: `submit-`, `apply-`
  - Packaging: `bundle-`
  - Confirmation: `confirm-`
  - Export/Clone: `export-`, `clone-`
  - Locking: `lock-`, `unlock-`
  - BYOIP: `advertise-`, `withdraw-`
  - Rotation: `rotate-`, `renew-`
  - Scaling: `scale-`
  - Completion: `complete-`, `abort-`, `continue-`
  - Monitoring: `monitor-`, `unmonitor-`
  - Cleanup: `purge-`
  - Rebuild: `rebuild-`
  - Merge: `merge-`
  - Swap: `swap-`
  - Compose: `compose-`
  - Retry: `retry-`
  - Trigger: `trigger-`
  - Invalidate: `invalidate-`
  - Override: `override-`
  - Post: `post-`
  - Resend: `resend-`
  - Split: `split-`
  - Cache: `flush-`
  - Admin (mutations only): `admin-delete-`, `admin-disable-`, `admin-enable-`, `admin-reset-`, `admin-set-`, `admin-update-`, `admin-create-`, `admin-confirm-`, `admin-forget-`, `admin-initiate-`, `admin-respond-`, `admin-link-`, `admin-add-`, `admin-remove-`
  - Device: `forget-`
  - Session: `global-`
  - Service control: `pause-`
  - Signaling: `signal-`
  - Upload: `upload-`
  - Deprecation: `deprecate-`, `undeprecate-`
  - Disposal: `dispose-`
  - Delivery: `deliver-`
  - Reservation: `reserve-`
  - Decline: `decline-`
  - Deploy: `deploy-`
  - Grant: `grant-`
  - Group: `group-`, `ungroup-`
  - Issue: `issue-`
  - Peer: `peer-`, `unpeer-`
  - Resolve: `resolve-`
  - Notify: `notify-`
  - Connect: `connect-`
  - Transfer: `transfer-`
  - Expire: `expire-`
  - Index: `index-`
  - Other: `add-`, `write-`
- `aws s3 rm`, `aws s3 cp ... s3://` (upload)
- `env`, `printenv` (credential protection)
- **Exception**: `aws logs start-query` allowed (CloudWatch Logs Insights is read-only)

### Blocked (IaC & shell bypass)
- `terraform`, `pulumi`, `eksctl`, `helm` (all operations)
- `bash -c` / `sh -c` with dangerous kubectl/aws commands
- `eval` with dangerous kubectl/aws commands
- `xargs aws/kubectl` and `| aws/kubectl` with mutation verbs
- `$(dangerous)` and `` `dangerous` `` command substitution
- `<(dangerous)` process substitution
- `<<< "dangerous"` here-string, `<<EOF dangerous EOF` heredoc
- `cmd; kubectl delete` / `cmd && aws iam` / `cmd || dangerous` chained commands
- Multiline scripts with dangerous commands after newlines
- `curl`/`wget` to `*.amazonaws.com`
- `node`/`bun` with `@aws-sdk`
- `declare -x`, `export -p` (environment inspection)

### Blocked (eval kernel bypass)
- `import boto3` / `from boto3 import` in Python eval
- `import kubernetes` / kubernetes client API instantiation
- `os.environ["AWS_SECRET_ACCESS_KEY"]` access
- `subprocess.run(["kubectl", ...])` / `subprocess.run(["aws", ...])`
- `@aws-sdk/client-*` imports in JavaScript eval
- `@kubernetes/client-node` imports and API instantiation
- `process.env.AWS_SECRET_ACCESS_KEY` access
- `child_process.exec("kubectl ...")` / `Bun.spawn(["aws", ...])`

## Example Usage

Once skills are installed, ask Claude:

- "Why is my pod in CrashLoopBackOff?"
- "Check the EKS cluster health for prod-cluster"
- "Show me CloudWatch logs for the api service"
- "What's causing memory pressure on node ip-10-0-1-42?"

Claude will use the investigation skills to run appropriate read-only commands.

## Security Model

This is **application-level filtering**, not IAM-based:

- The hook blocks bash commands before execution
- The hook blocks Python/JS eval with AWS/K8s SDK patterns
- Underlying AWS credentials may have broader permissions
- Defense in depth: combine with short-lived STS credentials

**Known limitations**:
- Shell metaprogramming (variable/array expansion) cannot be statically analyzed
- The hook operates on raw command strings, not executed code

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
