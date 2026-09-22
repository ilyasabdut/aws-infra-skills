---
name: Infrastructure Safety Hook
description: Documents the read-only infrastructure safety hook that blocks dangerous kubectl and AWS operations for AI agents.
---

# Infrastructure Safety Hook

This skill documents the pre-command safety hook that blocks dangerous kubectl and AWS operations. The hook ensures AI agents can only perform read-only investigation.

## When to Use

Reference this skill when:
- A command is blocked and you need to understand why
- You need to know what operations are allowed vs blocked
- Setting up the hook in a new environment
- Troubleshooting hook behavior

## How It Works

The hook intercepts bash commands and:

1. Parses the command
2. Checks against allowlists (kubectl) and blocklists (AWS)
3. Blocks dangerous operations with a helpful message
4. Allows read-only operations to proceed

## Installation

### For Claude (claude.ai)

Copy the `readonly-infra-hook.sh` script to your project and reference it in your CLAUDE.md or system instructions.

### For Claude Code / omp

Place the extension in your project's `.omp/extensions/` directory or user's `~/.omp/agent/extensions/`. It auto-loads on session start.

### Manual Testing

```bash
# Test that dangerous commands are blocked
./readonly-infra-hook.sh kubectl delete pod test
# Should output: BLOCKED: kubectl delete is a write operation...

# Test that safe commands are allowed
./readonly-infra-hook.sh kubectl get pods -n default
# Should exit 0 (no output)
```

## What's Allowed

### kubectl (allowlist approach)

| Command | Purpose |
|---------|---------|
| `kubectl get` | List resources |
| `kubectl describe` | Detailed resource info |
| `kubectl logs` | Container logs |
| `kubectl top` | Resource usage |
| `kubectl api-resources` | Available resource types |
| `kubectl api-versions` | API versions |
| `kubectl cluster-info` | Cluster information |
| `kubectl version` | Version info |
| `kubectl config view` | View config (read-only) |
| `kubectl config get-contexts` | List contexts |
| `kubectl config current-context` | Current context |
| `kubectl rollout status` | Rollout status only |

### AWS CLI (blocklist approach)

Read operations are generally allowed:
- `describe-*`
- `list-*`
- `get-*`

## What's Blocked

### kubectl

| Command | Reason |
|---------|--------|
| `kubectl apply` | Creates/updates resources |
| `kubectl create` | Creates resources |
| `kubectl delete` | Deletes resources |
| `kubectl patch` | Modifies resources |
| `kubectl edit` | Modifies resources |
| `kubectl scale` | Changes replica count |
| `kubectl exec` | Arbitrary code execution |
| `kubectl cp` | File transfer |
| `kubectl port-forward` | Network access |
| `kubectl drain` | Node evacuation |
| `kubectl cordon/uncordon` | Node scheduling |
| `kubectl taint` | Node modification |

### AWS CLI

| Category | Patterns | Reason |
|----------|----------|--------|
| **Services** | `aws iam *`, `aws organizations *` | Full service block |
| **CRUD** | `delete-`, `create-`, `put-`, `remove-`, `update-`, `modify-` | Resource mutation |
| **Lifecycle** | `terminate-`, `start-`, `stop-`, `reboot-`, `enable-`, `disable-`, `suspend-`, `resume-` | State changes |
| **Attachment** | `attach-`, `detach-`, `register-`, `deregister-`, `associate-`, `disassociate-` | Resource linking |
| **Security** | `authorize-`, `revoke-` | Security group rules |
| **Resource** | `import-`, `copy-`, `allocate-`, `release-`, `cancel-` | Resource operations |
| **Approval** | `accept-`, `reject-` | Approval workflows |
| **Tagging** | `tag-resource`, `untag-resource` | Resource tagging |
| **Messaging** | `send-`, `invoke`, `publish`, `send-command` | Message/execution |
| **Compute** | `run-` | Instance/task launch |
| **Execution** | `execute-` | Code/SQL execution |
| **Configuration** | `set-`, `reset-`, `change-` | Configuration changes |
| **Recovery** | `restore-`, `failover-`, `promote-`, `revert-`, `switchover-` | DR operations |
| **Movement** | `move-`, `migrate-` | Resource movement |
| **Batch** | `batch-write-`, `batch-delete-`, `batch-put-`, `batch-associate-` | Batch mutations |
| **Replacement** | `replace-` | Route/ACL replacement |
| **Provisioning** | `request-`, `purchase-`, `provision-`, `deprovision-` | Spot/reserved/IPAM |
| **Assignment** | `assign-`, `unassign-` | IP address assignment |
| **Submission** | `submit-`, `apply-` | State/maintenance changes |
| **Packaging** | `bundle-` | Instance bundling |
| **Confirmation** | `confirm-` | Product confirmation |
| **Export/Clone** | `export-`, `clone-` | Image/snapshot export, RDS cloning |
| **Locking** | `lock-`, `unlock-` | Snapshot locking |
| **BYOIP** | `advertise-`, `withdraw-` | BYOIP advertisement |
| **Rotation** | `rotate-`, `renew-` | Secret/certificate rotation |
| **Scaling** | `scale-` | Autoscaling operations |
| **Completion** | `complete-`, `abort-` | Lifecycle actions, multipart uploads |
| **Monitoring** | `monitor-`, `unmonitor-` | EC2 detailed monitoring |
| **Other** | `add-`, `write-` | Additional mutations |
| **S3** | `aws s3 rm`, `aws s3 cp <local> s3://` | Object deletion/upload |
| **STS** | `aws sts assume-role` | Privilege escalation |

**Exception**: `aws logs start-query`, `stop-query`, `get-query-results` are allowed (CloudWatch Logs Insights is read-only)

### Credential Protection

| Pattern | Reason |
|---------|--------|
| `env` | Lists all environment variables |
| `printenv` | Prints environment variables |
| `export` (bare) | Lists exports |
| `/proc/*/environ` | Process environment |
| `echo $AWS_SECRET*` | Credential echoing |

### Bypass Prevention (bash)

| Pattern | Reason |
|---------|--------|
| `python* boto3` | Direct AWS SDK |
| `node/bun @aws-sdk` | Direct AWS SDK (JS) |
| `curl *.amazonaws.com` | Direct API access |

### IaC Tools Blocking

| Tool | Reason |
|------|--------|
| `terraform` | Infrastructure mutation |
| `pulumi` | Infrastructure mutation |
| `eksctl` | EKS cluster mutation |
| `helm` | Kubernetes deployment |

### Shell Indirection Blocking

| Pattern | Reason |
|---------|--------|
| `bash -c "kubectl delete..."` | Shell bypass |
| `sh -c "aws iam..."` | Shell bypass |
| `eval "kubectl delete..."` | Eval bypass |
| `xargs aws/kubectl` | Pipe bypass |
| `| aws/kubectl` | Pipe bypass |

### Command Substitution Blocking

| Pattern | Reason |
|---------|--------|
| `$(kubectl delete...)` | Subshell bypass |
| `` `aws iam...` `` | Backtick bypass |
| `$(aws terminate-...)` | Subshell bypass |
| `<(kubectl delete...)` | Process substitution bypass |
| `<<< "kubectl delete..."` | Here-string bypass |
| `<<EOF kubectl delete EOF` | Heredoc bypass |

### Chained Command Blocking

| Pattern | Reason |
|---------|--------|
| `cmd; kubectl delete...` | Semicolon chaining |
| `cmd && kubectl delete...` | AND chaining |
| `cmd \|\| kubectl delete...` | OR chaining |
| `cmd\nkubectl delete...` | Newline chaining |

### Environment Inspection Blocking

| Pattern | Reason |
|---------|--------|
| `declare -x` | Lists exported variables |
| `export -p` | Prints exports |

### Eval Kernel Protection (Python)

| Pattern | Reason |
|---------|--------|
| `import boto3` | AWS SDK import |
| `boto3.client()` | SDK client creation |
| `import kubernetes` | K8s client import |
| `client.CoreV1Api()` | K8s API instantiation |
| `os.environ["AWS_*"]` | Credential access |
| `subprocess.run(["kubectl"...])` | CLI bypass |

### Eval Kernel Protection (JavaScript)

| Pattern | Reason |
|---------|--------|
| `@aws-sdk/client-*` | AWS SDK import |
| `new EKSClient()` | SDK client creation |
| `@kubernetes/client-node` | K8s client import |
| `new k8s.CoreV1Api()` | K8s API instantiation |
| `process.env.AWS_*` | Credential access |
| `child_process.exec("kubectl"...)` | CLI bypass |
| `Bun.spawn(["aws"...])` | Bun shell bypass |

## Block Messages

When a command is blocked, you'll see a helpful message:

```
BLOCKED: kubectl delete is a write operation.
For investigation, use: kubectl get, kubectl describe, kubectl logs
```

```
BLOCKED: kubectl exec allows arbitrary code execution in containers.
To see container output, use: kubectl logs <pod> -n <namespace>
```

```
BLOCKED: aws iam operations are not permitted.
This agent has read-only infrastructure access.
```

## Limitations

1. **Not IAM-based**: This hook is application-level filtering. The underlying AWS credentials may have broader permissions.

2. **Eval protection scope**: The eval kernel protection blocks common SDK patterns but cannot catch all possible code obfuscation. Defense in depth is recommended.

3. **Allowlist maintenance**: New kubectl subcommands won't be allowed until added to the allowlist.

4. **Shell metaprogramming**: The hook operates on the raw command string. It cannot catch:
   - Variable expansion: `CMD="kubectl delete"; $CMD pod test`
   - Array expansion: `arr=(kubectl delete); "${arr[@]}"`
   - Dynamically constructed commands in multi-line scripts

5. **Alias bypass**: Aliases are not expanded in non-interactive shells (not a risk in agent context).

## When Commands Are Blocked

If a legitimate command is blocked:

1. Report what you wanted to do
2. A human operator can run the command directly
3. Or request the hook be updated to allow the operation

The hook is intentionally conservative. False positives (blocking safe commands) are preferred over false negatives (allowing dangerous commands).
