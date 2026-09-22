---
name: diagnostic-workflows
description: Step-by-step diagnostic procedures for common Kubernetes and AWS infrastructure issues
triggers:
  - diagnose
  - debug
  - troubleshoot
  - why
  - crash
  - CrashLoopBackOff
  - OOMKilled
  - ImagePullBackOff
  - NotReady
  - Pending
  - unavailable
  - not working
  - failing
  - error
---

# Diagnostic Workflows

Systematic procedures for diagnosing common infrastructure issues. All commands are read-only.

## Pod Crash Diagnosis

### CrashLoopBackOff

When a pod keeps restarting:

```bash
# 1. Get pod status and restart count
kubectl get pod <pod> -n <namespace>

# 2. Get detailed status - check container states, exit codes
kubectl describe pod <pod> -n <namespace>

# 3. Get logs from the PREVIOUS (crashed) container
kubectl logs <pod> -n <namespace> --previous

# 4. If multi-container, specify container
kubectl logs <pod> -n <namespace> -c <container> --previous

# 5. Check events
kubectl get events -n <namespace> --field-selector involvedObject.name=<pod> --sort-by='.lastTimestamp'
```

**What to look for:**
- Exit code 137 → OOMKilled (see below)
- Exit code 1 → Application error (check logs)
- Exit code 127 → Command not found (image issue)
- Exit code 126 → Permission denied

### OOMKilled (Exit Code 137)

Container exceeded memory limit:

```bash
# 1. Confirm OOMKilled
kubectl describe pod <pod> -n <namespace> | grep -A5 "Last State"

# 2. Check memory limits
kubectl describe pod <pod> -n <namespace> | grep -A5 "Limits:"

# 3. Current memory usage (if running)
kubectl top pod <pod> -n <namespace>

# 4. Check node memory pressure
kubectl describe node <node> | grep -A5 "Conditions:"

# 5. Check events for OOM
kubectl get events -n <namespace> --field-selector reason=OOMKilling
```

**Likely causes:**
- Memory limit too low for workload
- Memory leak in application
- Unexpected traffic spike

### ImagePullBackOff

Container image cannot be pulled:

```bash
# 1. Get events showing pull errors
kubectl describe pod <pod> -n <namespace> | grep -A10 "Events:"

# 2. Check image name and tag
kubectl get pod <pod> -n <namespace> -o jsonpath='{.spec.containers[*].image}'

# 3. Check image pull secrets
kubectl get pod <pod> -n <namespace> -o jsonpath='{.spec.imagePullSecrets}'

# 4. Verify secret exists
kubectl get secrets -n <namespace> | grep docker
```

**Likely causes:**
- Image doesn't exist (typo in name/tag)
- Registry authentication failed
- Network cannot reach registry
- Image was deleted

### Pending Pod

Pod not scheduling:

```bash
# 1. Check why pending
kubectl describe pod <pod> -n <namespace> | grep -A10 "Events:"

# 2. Check resource requests
kubectl describe pod <pod> -n <namespace> | grep -A5 "Requests:"

# 3. Check node capacity
kubectl describe nodes | grep -A5 "Allocated resources:"

# 4. Check for node selector/affinity
kubectl get pod <pod> -n <namespace> -o yaml | grep -A10 "nodeSelector\|affinity"

# 5. Check taints
kubectl describe nodes | grep Taints
```

**Likely causes:**
- Insufficient CPU/memory on nodes
- Node selector doesn't match any node
- PVC cannot be bound
- Taint without toleration

## Node Issues

### NotReady Node

```bash
# 1. Get node conditions
kubectl describe node <node> | grep -A15 "Conditions:"

# 2. Check kubelet status (from node events)
kubectl get events --field-selector involvedObject.name=<node> --sort-by='.lastTimestamp'

# 3. Check EC2 instance status
aws ec2 describe-instance-status --instance-ids <instance-id>

# 4. Check pods on this node
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node>

# 5. Check system pods
kubectl get pods -n kube-system --field-selector spec.nodeName=<node>
```

**Likely causes:**
- Kubelet not running
- Network issues (CNI problems)
- Disk pressure
- EC2 instance issue

### Resource Pressure (DiskPressure, MemoryPressure, PIDPressure)

```bash
# 1. Check which pressure
kubectl describe node <node> | grep -E "(DiskPressure|MemoryPressure|PIDPressure)"

# 2. Check resource usage
kubectl top node <node>

# 3. Check capacity vs allocatable
kubectl describe node <node> | grep -A10 "Capacity:\|Allocatable:"

# 4. Find resource-heavy pods
kubectl top pods --all-namespaces --sort-by=memory | head -20
kubectl top pods --all-namespaces --sort-by=cpu | head -20

# 5. Check node disk (from EC2)
aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=<instance-id>"
```

## Deployment Issues

### Unavailable Replicas

```bash
# 1. Check deployment status
kubectl get deployment <name> -n <namespace>

# 2. Check conditions
kubectl describe deployment <name> -n <namespace> | grep -A10 "Conditions:"

# 3. Check replica sets
kubectl get rs -n <namespace> -l app=<name>

# 4. Check pod status
kubectl get pods -n <namespace> -l app=<name>

# 5. Check pod events
kubectl describe pods -n <namespace> -l app=<name> | grep -A10 "Events:"
```

### Rollout Stuck

```bash
# 1. Check rollout status
kubectl rollout status deployment/<name> -n <namespace>

# 2. Check new ReplicaSet
kubectl get rs -n <namespace> -l app=<name> --sort-by='.metadata.creationTimestamp'

# 3. Check new pods
kubectl get pods -n <namespace> -l app=<name> | grep -v Running

# 4. Check resource quotas
kubectl get resourcequotas -n <namespace>
kubectl describe resourcequota -n <namespace>

# 5. Check events
kubectl get events -n <namespace> --sort-by='.lastTimestamp' | head -20
```

## Scaling Issues

### HPA Not Scaling

```bash
# 1. Check HPA status
kubectl get hpa <name> -n <namespace>

# 2. Check HPA details and conditions
kubectl describe hpa <name> -n <namespace>

# 3. Check metrics-server
kubectl get pods -n kube-system -l k8s-app=metrics-server
kubectl top pods -n <namespace>  # Should work if metrics-server is healthy

# 4. Check target deployment
kubectl get deployment <target> -n <namespace>

# 5. Check current resource usage
kubectl top pod -n <namespace> -l app=<name>
```

### KEDA ScaledObject Issues

```bash
# 1. Check ScaledObject status
kubectl get scaledobject <name> -n <namespace>
kubectl describe scaledobject <name> -n <namespace>

# 2. Check KEDA operator
kubectl get pods -n keda -l app=keda-operator
kubectl logs -n keda -l app=keda-operator --tail=100

# 3. Check target workload
kubectl get deployment <target> -n <namespace>

# 4. Check trigger authentication (if used)
kubectl get triggerauthentications -n <namespace>
```

## Service Connectivity

### Service Not Reachable

```bash
# 1. Check service exists
kubectl get service <name> -n <namespace>

# 2. Check endpoints (should have IP:port entries)
kubectl get endpoints <name> -n <namespace>

# 3. Check backend pods are ready
kubectl get pods -n <namespace> -l <service-selector>

# 4. Check pod readiness
kubectl describe pods -n <namespace> -l <service-selector> | grep -A5 "Readiness:"

# 5. Check network policies
kubectl get networkpolicies -n <namespace>
```

### Load Balancer Issues

```bash
# 1. Check LB service
kubectl get svc <name> -n <namespace>

# 2. Check external hostname/IP
kubectl get svc <name> -n <namespace> -o jsonpath='{.status.loadBalancer.ingress}'

# 3. Check AWS LB
aws elbv2 describe-load-balancers --query 'LoadBalancers[?contains(LoadBalancerName, `<partial-name>`)]'

# 4. Check target health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# 5. Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

## EKS Cluster Issues

### Cluster Health Check

```bash
# 1. Cluster status
aws eks describe-cluster --name <cluster> --query 'cluster.status'

# 2. Control plane logs (if enabled)
aws logs filter-log-events \
  --log-group-name /aws/eks/<cluster>/cluster \
  --filter-pattern "error" \
  --limit 50

# 3. Nodegroup status
aws eks list-nodegroups --cluster-name <cluster>
aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <ng> --query 'nodegroup.status'

# 4. Node health via kubectl
kubectl get nodes
kubectl describe nodes | grep -A5 "Conditions:"

# 5. kube-system pods
kubectl get pods -n kube-system
```

## Standard Diagnosis Output Format

When completing a diagnosis, report:

```
## Summary
<One-line likely cause>

## Evidence
- <Finding 1 from command output>
- <Finding 2>
- ...

## Likely Causes (ranked)
1. <Most likely> - <why>
2. <Second likely> - <why>

## Recommended Next Steps
1. <What to investigate further>
2. <Or what action to take>

---
*No changes were made to the cluster.*
```

---

**Note**: All commands in this workflow are read-only. The safety hook blocks any write operations.
