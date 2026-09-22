## ADDED Requirements

### Requirement: Pod Crash Diagnosis

The agent MUST follow a systematic procedure to diagnose pod crashes.

#### Scenario: CrashLoopBackOff diagnosis
- **WHEN** a pod is in CrashLoopBackOff
- **THEN** agent collects:
  1. `kubectl describe pod <pod> -n <ns>` — container states, exit codes, events
  2. `kubectl logs <pod> -n <ns> --previous` — logs from crashed container
  3. `kubectl get events -n <ns> --field-selector involvedObject.name=<pod>` — pod events
  4. `kubectl describe node <node>` — if OOMKilled, check node memory pressure

#### Scenario: OOMKilled diagnosis
- **WHEN** a container was OOMKilled (exit code 137)
- **THEN** agent collects:
  1. Container memory limits from describe
  2. `kubectl top pod <pod> -n <ns>` — current memory usage (if running)
  3. Node memory pressure status
  4. Recent deployment changes

#### Scenario: ImagePullBackOff diagnosis
- **WHEN** a pod cannot pull its image
- **THEN** agent collects:
  1. Image name and tag from describe
  2. Events showing pull errors
  3. Registry authentication status (without exposing secrets)

---

### Requirement: Node Issue Diagnosis

The agent MUST follow a systematic procedure to diagnose node problems.

#### Scenario: NotReady node diagnosis
- **WHEN** a node is NotReady
- **THEN** agent collects:
  1. `kubectl describe node <node>` — conditions, taints
  2. `kubectl get events --field-selector involvedObject.name=<node>` — node events
  3. `aws ec2 describe-instance-status --instance-ids <id>` — EC2 status checks
  4. Pods on the node: `kubectl get pods --all-namespaces --field-selector spec.nodeName=<node>`

#### Scenario: Resource pressure diagnosis
- **WHEN** a node has DiskPressure, MemoryPressure, or PIDPressure
- **THEN** agent collects:
  1. `kubectl top node <node>` — current utilization
  2. `kubectl describe node <node>` — allocatable vs capacity
  3. High-resource pods on node

---

### Requirement: Deployment Issue Diagnosis

The agent MUST follow a systematic procedure to diagnose deployment problems.

#### Scenario: Unavailable replicas
- **WHEN** a deployment has unavailable replicas
- **THEN** agent collects:
  1. `kubectl describe deployment <name> -n <ns>` — conditions, strategy
  2. `kubectl get rs -n <ns> -l app=<name>` — replica sets
  3. `kubectl get pods -n <ns> -l app=<name>` — pod statuses
  4. Events for deployment and pods

#### Scenario: Rollout stuck
- **WHEN** a deployment rollout is not progressing
- **THEN** agent collects:
  1. `kubectl rollout status deployment/<name> -n <ns>` — rollout status
  2. New ReplicaSet pod status
  3. Resource quota status in namespace

---

### Requirement: Scaling Issue Diagnosis

The agent MUST follow a systematic procedure to diagnose scaling problems.

#### Scenario: HPA not scaling
- **WHEN** HPA is not scaling as expected
- **THEN** agent collects:
  1. `kubectl describe hpa <name> -n <ns>` — current metrics, conditions
  2. Target deployment/statefulset status
  3. Metrics-server availability: `kubectl get pods -n kube-system -l k8s-app=metrics-server`

#### Scenario: KEDA ScaledObject issues
- **WHEN** KEDA scaler is not working
- **THEN** agent collects:
  1. `kubectl describe scaledobject <name> -n <ns>` — triggers, conditions
  2. `kubectl get pods -n keda -l app=keda-operator` — KEDA operator status
  3. Target workload status

---

### Requirement: Service Connectivity Diagnosis

The agent MUST follow a systematic procedure to diagnose service issues.

#### Scenario: Service not reachable
- **WHEN** a service is not responding
- **THEN** agent collects:
  1. `kubectl describe service <name> -n <ns>` — selector, ports
  2. `kubectl get endpoints <name> -n <ns>` — backend pods
  3. Backend pod readiness status
  4. Network policy (if any) affecting the namespace

---

### Requirement: Diagnosis Output Format

The agent MUST present diagnostic findings in a structured format.

#### Scenario: Standard diagnosis report
- **WHEN** agent completes a diagnostic workflow
- **THEN** agent outputs:
  1. **Summary**: One-line description of likely cause
  2. **Evidence**: Key findings from each command
  3. **Likely Causes**: Ranked list of probable root causes
  4. **Next Steps**: What to investigate further or escalate
  5. **Note**: "No changes were made to the cluster"
