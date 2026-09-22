---
name: safety-hook
description: Documents the read-only infrastructure safety hook that blocks dangerous operations
triggers:
  - hook
  - safety
  - blocked
  - not allowed
  - permission
  - write
  - delete
  - modify
---

# Safety Hook Documentation

This project includes a pre-command safety hook that blocks dangerous kubectl and AWS operations. The hook ensures agents can only perform read-only investigation.

## How It Works

The TypeScript extension (`.omp/extensions/readonly-infra-hook.ts`) intercepts `bash` tool calls and:

1. Parses the command
2. Checks against allowlists (kubectl) and blocklists (AWS)
3. Returns `{ block: true, reason: "..." }` to block, or allows execution
4. Provides helpful alternatives when blocking

## How It's Loaded

### omp (automatic)

The extension auto-loads when omp starts in this project directory. No configuration needed.

omp discovers extensions from:
1. Project: `<cwd>/.omp/extensions/`
2. User: `~/.omp/agent/extensions/`

### Claude Code

Claude Code doesn't use omp extensions. For Claude Code, reference the bash script in your configuration or CLAUDE.md rules.

### Manual Testing

```bash
# Test that dangerous commands are blocked
.omp/hooks/readonly-infra.sh kubectl delete pod test
# Should output: BLOCKED: kubectl delete is a write operation...

# Test that safe commands are allowed
.omp/hooks/readonly-infra.sh kubectl get pods -n default
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

| Pattern | Reason |
|---------|--------|
| `aws iam *` | All IAM operations blocked |
| `aws * delete-*` | Resource deletion |
| `aws * terminate-*` | Instance termination |
| `aws * create-*` | Resource creation |
| `aws * modify-*` | Resource modification |
| `aws * update-*` | Resource updates |
| `aws * put-*` | Configuration writes |
| `aws s3 rm` | Object deletion |
| `aws s3 cp <local> s3://` | Object upload |
| `aws sts assume-role` | Privilege escalation |

### Credential Protection

| Pattern | Reason |
|---------|--------|
| `env` | Lists all environment variables |
| `printenv` | Prints environment variables |
| `export` (bare) | Lists exports |
| `/proc/*/environ` | Process environment |
| `echo $AWS_SECRET*` | Credential echoing |

### Bypass Prevention

| Pattern | Reason |
|---------|--------|
| `python* boto3` | Direct AWS SDK |
| `curl *.amazonaws.com` | Direct API access |

## Block Messages

When a command is blocked, you'll see a helpful message:

```
Blocked: kubectl delete is a write operation.
For investigation, use: kubectl get, kubectl describe, kubectl logs
```

```
Blocked: kubectl exec allows arbitrary code execution in containers.
To see container output, use: kubectl logs <pod> -n <namespace>
```

```
Blocked: aws iam operations are not permitted.
This agent has read-only infrastructure access.
```

## Limitations

1. **Not IAM-based**: This hook is application-level filtering. The underlying AWS credentials may have broader permissions.

2. **Bypass risk**: If the agent can write files and execute them, or use eval with boto3, it could potentially bypass the hook. The hook blocks common patterns but is not a security boundary.

3. **Allowlist maintenance**: New kubectl subcommands won't be allowed until added to the allowlist.

## When Commands Are Blocked

If a legitimate command is blocked:

1. Report what you wanted to do
2. A human operator can run the command directly
3. Or request the hook be updated to allow the operation

The hook is intentionally conservative. False positives (blocking safe commands) are preferred over false negatives (allowing dangerous commands).
