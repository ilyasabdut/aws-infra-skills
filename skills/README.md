# Read-Only Infrastructure Skills

Skills for AI agents to investigate AWS and Kubernetes infrastructure without the ability to modify or destroy resources.

## Skills Included

| Skill | Description |
|-------|-------------|
| **k8s-investigation** | kubectl patterns for pods, deployments, nodes, events, logs |
| **aws-investigation** | AWS CLI patterns for EKS, EC2, CloudWatch, S3, load balancers |
| **diagnostic-workflows** | Step-by-step procedures for CrashLoopBackOff, OOMKilled, etc. |
| **safety-hook** | Documentation + bash script to block dangerous operations |

## Installation

### Claude (claude.ai)

1. Go to **Settings > Skills**
2. Click **Add Skill**
3. Upload the skill folder as a ZIP (or drag the folder)

### Claude Code / omp

Copy the skill folders to your skills directory:

```bash
# User-level (all projects)
cp -r skills/* ~/.omp/agent/skills/

# Or project-level
cp -r skills/* .omp/skills/
```

## Usage

Once installed, Claude will automatically use these skills when you ask about:
- Kubernetes troubleshooting
- AWS infrastructure investigation
- Pod crashes, node issues, deployment problems
- CloudWatch logs and metrics

### Example Prompts

- "Why is my pod in CrashLoopBackOff?"
- "Check the health of EKS cluster prod-cluster"
- "What's consuming memory on node ip-10-0-1-42?"
- "Show me the logs for the api deployment in production namespace"

## Safety Hook

The `safety-hook` skill includes a bash script (`readonly-infra.sh`) that blocks dangerous commands. To use it:

1. Copy `skills/safety-hook/readonly-infra.sh` to your project
2. Make it executable: `chmod +x readonly-infra.sh`
3. Configure your agent to run commands through it

The hook blocks:
- `kubectl delete`, `apply`, `exec`, `scale`, etc.
- `aws iam *`, `aws * delete-*`, `aws * terminate-*`, etc.
- Credential inspection (`env`, `printenv`, etc.)

## Requirements

- AWS CLI configured with credentials
- kubectl configured with cluster access
- Credentials should ideally be read-only (but the hook provides defense-in-depth)

## License

MIT
