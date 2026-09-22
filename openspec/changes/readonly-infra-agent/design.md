## Context

AI agents (Hermes running on omp) need to investigate production EKS infrastructure. The agent runs in an environment with AWS credentials passed as environment variables (STS temporary credentials). Currently, nothing prevents the agent from running destructive commands like `kubectl delete` or `aws eks delete-cluster`.

**Deployment**: Agent runs in EKS itself, credentials provided via environment variables.

**Existing tools**: kubectl and aws-cli v2 are already installed and functional.

## Goals / Non-Goals

**Goals:**
- Agent can investigate pods, deployments, PVCs, nodes, events, logs, HPA, scaled objects
- Agent can investigate EKS cluster health, nodegroups, EC2 instances, CloudWatch
- Agent cannot run destructive operations (delete, apply, exec, terminate, modify)
- Works with temporary STS session credentials
- No custom CLI binary — use existing kubectl/aws with filtering

**Non-Goals:**
- IAM-based security (credentials already have broader permissions)
- Custom CLI wrapper binary
- MCP server integration
- Write operations of any kind
- Real-time alerting or monitoring

## Decisions

### D1: Use omp hook for command blocking (not wrapper script)

**Choice**: omp pre-command hook that inspects bash commands before execution

**Rationale**: 
- omp already has hook infrastructure
- Runs before command execution, can block
- No PATH manipulation needed
- Agent still uses familiar kubectl/aws syntax

**Alternatives considered**:
- Wrapper binary: More overhead, needs compilation, PATH tricks
- Shell alias: Easily bypassed
- Separate IAM role: Not available per constraints

### D2: Allowlist approach for kubectl

**Choice**: Block by default, allow specific read-only subcommands

**Allowed kubectl operations**:
```
get, describe, logs, top, api-resources, api-versions, cluster-info, version
```

**Blocked kubectl operations**:
```
apply, create, delete, patch, edit, replace, scale, rollout, exec, cp, 
port-forward, run, expose, set, label, annotate, taint, cordon, uncordon, 
drain, attach, debug, auth can-i (write checks)
```

**Rationale**: Kubernetes has many subcommands; easier to maintain an allowlist of known-safe operations than chase every dangerous one.

### D3: Blocklist approach for AWS CLI

**Choice**: Allow by default, block known dangerous patterns

**Blocked AWS patterns**:
```
aws .* (delete-|terminate-|modify-|update-|create-|put-|remove-|deregister-)
aws iam .*
aws sts assume-role  # prevent privilege escalation
aws s3 (rm|mv|cp .* s3://|sync .* s3://)  # block writes to S3
```

**Allowed implicitly**: All describe-*, list-*, get-* operations

**Rationale**: AWS API is read-heavy; most commands are safe. Blocking the mutation verbs covers the risk.

### D4: Skills structure

**Choice**: Four skill files in `.omp/skills/`

```
.omp/skills/
├── k8s-investigation/SKILL.md      # kubectl patterns
├── aws-investigation/SKILL.md      # aws cli patterns
├── diagnostic-workflows/SKILL.md   # higher-level procedures
└── safety-hook/SKILL.md            # documents the hook, not the hook itself
```

Hook configuration lives in `.omp/hooks/` or agent config, not in skills.

### D5: Hook implementation location

**Choice**: TypeScript extension in `.omp/extensions/` (project-local)

**Implementation**: 
- omp loads TypeScript extensions from `.omp/extensions/` at session start
- Extension hooks `tool_call` event, checks `event.toolName === "bash"`
- Extracts command string, pattern-matches against blocked operations
- Returns `{ block: true, reason: "..." }` to block, or `undefined` to allow

**File**: `.omp/extensions/readonly-infra-hook.ts`

**Claude Code compatibility**: 
- Claude Code uses a different hook mechanism (settings.json or CLAUDE.md rules)
- For Claude Code, provide equivalent bash script at `.omp/hooks/readonly-infra.sh` that can be referenced in pre-command hooks
- Both implementations share the same logic; TypeScript is primary, bash is fallback

**Why project-local**: 
- Portable with the repo
- Different projects can have different security policies
- Easy to review/audit alongside the code

## Risks / Trade-offs

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Hook bypass via eval kernel | Medium | High | Block `python`/`node` with boto3/k8s-client imports in hook |
| Incomplete blocklist | Medium | Medium | Start strict, expand allowlist as needed |
| Credential leak via `env`/`printenv` | Low | Medium | Block `env`, `printenv`, `cat /proc/*/environ` |
| Agent figures out bypass | Low | High | Audit logs, review agent transcripts |
| Legitimate operation blocked | High | Low | Agent reports block, human can run manually |

**Accepted trade-off**: Some legitimate edge-case commands may be blocked. This is acceptable — the agent can report what it wanted to do, and a human can execute if needed.
