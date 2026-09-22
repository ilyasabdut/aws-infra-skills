## Why

AI agents (Hermes) need to investigate EKS/Kubernetes infrastructure — pods, deployments, PVCs, nodes, scaled objects, errors — without the ability to modify or destroy resources. Currently, giving agents AWS credentials means they can run any AWS/kubectl command, including destructive ones.

## What Changes

- Add **investigation skills** that teach agents how to diagnose common Kubernetes/AWS issues using read-only commands
- Add **safety hook** that blocks dangerous kubectl/AWS operations before execution
- Support temporary STS session credentials (environment variables)
- No custom CLI binary — leverage existing kubectl and aws-cli with command filtering

## Capabilities

### New Capabilities

- `k8s-investigation`: Kubernetes read-only investigation patterns — pods, deployments, PVCs, nodes, events, logs, HPA, scaled objects, resource utilization
- `aws-investigation`: AWS read-only investigation patterns — EKS cluster status, nodegroups, EC2 instances, CloudWatch logs/metrics
- `safety-hook`: Pre-command hook that blocks destructive kubectl/AWS operations (delete, apply, exec, terminate, modify)
- `diagnostic-workflows`: Higher-level diagnostic procedures — pod crash analysis, node issues, deployment failures, scaling problems

### Modified Capabilities

(none — greenfield project)

## Impact

- **New files**: Skills in `.omp/skills/`, hook configuration
- **Dependencies**: kubectl, aws-cli v2 (must be pre-installed)
- **Agent environment**: Requires AWS credentials as env vars (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN)
- **Security model**: Defense via hook command filtering, not IAM policy (IAM assumed to have broader permissions)
