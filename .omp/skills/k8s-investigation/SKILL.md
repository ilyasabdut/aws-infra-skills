---
name: k8s-investigation
description: Read-only Kubernetes investigation patterns for diagnosing pod, deployment, node, and cluster issues
triggers:
  - kubernetes
  - k8s
  - pod
  - deployment
  - node
  - kubectl
  - crash
  - CrashLoopBackOff
  - OOMKilled
  - NotReady
  - Pending
---

# Kubernetes Investigation Skill

Read-only investigation patterns for Kubernetes/EKS clusters. All commands are non-destructive.

## Quick Reference

| What | Command |
|------|---------|
| Pods | `kubectl get pods -n <ns>` |
| Pod details | `kubectl describe pod <pod> -n <ns>` |
| Logs | `kubectl logs <pod> -n <ns>` |
| Previous logs | `kubectl logs <pod> -n <ns> --previous` |
| Events | `kubectl get events -n <ns> --sort-by='.lastTimestamp'` |
| Nodes | `kubectl get nodes` |
| Node details | `kubectl describe node <node>` |
| Resource usage | `kubectl top pods -n <ns>` / `kubectl top nodes` |

## Pod Investigation

### List pods
```bash
# All pods in namespace
kubectl get pods -n <namespace>

# Wide output with node info
kubectl get pods -n <namespace> -o wide

# All namespaces
kubectl get pods -A

# Filter by label
kubectl get pods -n <namespace> -l app=<name>

# Show labels
kubectl get pods -n <namespace> --show-labels
```

### Pod details
```bash
# Full description with events
kubectl describe pod <pod> -n <namespace>

# YAML output for config inspection
kubectl get pod <pod> -n <namespace> -o yaml
```

### Pod logs
```bash
# Current logs
kubectl logs <pod> -n <namespace>

# Specific container
kubectl logs <pod> -n <namespace> -c <container>

# Previous instance (after crash)
kubectl logs <pod> -n <namespace> --previous

# Follow logs
kubectl logs <pod> -n <namespace> -f

# Last N lines
kubectl logs <pod> -n <namespace> --tail=100

# Since timestamp
kubectl logs <pod> -n <namespace> --since=1h
```

## Deployment Investigation

### List deployments
```bash
kubectl get deployments -n <namespace>
kubectl get deploy -n <namespace> -o wide
```

### Deployment details
```bash
kubectl describe deployment <name> -n <namespace>
```

### Replica sets
```bash
# See revision history
kubectl get rs -n <namespace>
kubectl get rs -n <namespace> -l app=<name>
```

### StatefulSets and DaemonSets
```bash
kubectl get statefulsets -n <namespace>
kubectl get daemonsets -n <namespace>
kubectl describe statefulset <name> -n <namespace>
kubectl describe daemonset <name> -n <namespace>
```

## Node Investigation

### List nodes
```bash
kubectl get nodes
kubectl get nodes -o wide
```

### Node details
```bash
kubectl describe node <node-name>
```

Key sections to check:
- **Conditions**: Ready, MemoryPressure, DiskPressure, PIDPressure
- **Capacity vs Allocatable**: Resource limits
- **Non-terminated Pods**: What's running on this node

### Node resource usage
```bash
kubectl top nodes
kubectl top node <node-name>
```

### Pods on a specific node
```bash
kubectl get pods --all-namespaces --field-selector spec.nodeName=<node>
```

## Events Investigation

### Recent events
```bash
# Namespace events, sorted by time
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# All events
kubectl get events -A --sort-by='.lastTimestamp'
```

### Events for specific resource
```bash
kubectl get events -n <namespace> --field-selector involvedObject.name=<pod-name>
kubectl get events -n <namespace> --field-selector involvedObject.kind=Deployment,involvedObject.name=<name>
```

### Warning events only
```bash
kubectl get events -n <namespace> --field-selector type=Warning
```

## PVC Investigation

### List PVCs
```bash
kubectl get pvc -n <namespace>
kubectl get pv  # Cluster-wide persistent volumes
```

### PVC details
```bash
kubectl describe pvc <name> -n <namespace>
```

Key things to check:
- **Status**: Bound, Pending, Lost
- **StorageClass**: Which provisioner
- **Access Modes**: RWO, RWX, ROX
- **Events**: Provisioning issues

## HPA and Scaling

### Horizontal Pod Autoscalers
```bash
kubectl get hpa -n <namespace>
kubectl describe hpa <name> -n <namespace>
```

### KEDA ScaledObjects
```bash
kubectl get scaledobjects -n <namespace>
kubectl describe scaledobject <name> -n <namespace>

# KEDA operator status
kubectl get pods -n keda -l app=keda-operator
```

### Vertical Pod Autoscaler (if installed)
```bash
kubectl get vpa -n <namespace>
```

## Services and Networking

### Services
```bash
kubectl get services -n <namespace>
kubectl get svc -n <namespace>
kubectl describe service <name> -n <namespace>
```

### Endpoints
```bash
kubectl get endpoints -n <namespace>
kubectl get endpoints <service-name> -n <namespace>
```

### Ingress
```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <name> -n <namespace>
```

### Network Policies
```bash
kubectl get networkpolicies -n <namespace>
kubectl describe networkpolicy <name> -n <namespace>
```

## ConfigMaps and Secrets (metadata only)

```bash
# List
kubectl get configmaps -n <namespace>
kubectl get secrets -n <namespace>

# Describe (shows keys, not values for secrets)
kubectl describe configmap <name> -n <namespace>
kubectl describe secret <name> -n <namespace>
```

## Resource Quotas and Limits

```bash
kubectl get resourcequotas -n <namespace>
kubectl describe resourcequota <name> -n <namespace>

kubectl get limitranges -n <namespace>
kubectl describe limitrange <name> -n <namespace>
```

## Cluster Info

```bash
kubectl cluster-info
kubectl version
kubectl api-resources
kubectl api-versions
```

## Common Patterns

### Find unhealthy pods
```bash
kubectl get pods -A | grep -v Running | grep -v Completed
```

### Find high-restart pods
```bash
kubectl get pods -A -o wide | awk '$5 > 5'
```

### Check resource usage vs requests
```bash
kubectl top pods -n <namespace>
kubectl describe pod <pod> -n <namespace> | grep -A 5 "Requests:"
```

---

**Note**: This skill only covers read operations. Write operations (apply, delete, scale, exec) are blocked by the safety hook.
