## ADDED Requirements

### Requirement: Pod Investigation

The agent MUST be able to inspect pod status, containers, and logs to diagnose failures.

#### Scenario: List pods in namespace
- **WHEN** agent needs to see pods in a namespace
- **THEN** agent runs `kubectl get pods -n <namespace>` and receives pod names, status, restarts, age

#### Scenario: Get pod details
- **WHEN** agent needs detailed pod information
- **THEN** agent runs `kubectl describe pod <pod> -n <namespace>` and receives events, conditions, container states

#### Scenario: Get current logs
- **WHEN** agent needs to see pod logs
- **THEN** agent runs `kubectl logs <pod> -n <namespace> [-c container]` and receives stdout/stderr

#### Scenario: Get previous container logs
- **WHEN** agent needs to see logs from crashed container
- **THEN** agent runs `kubectl logs <pod> -n <namespace> --previous` and receives logs from previous instance

---

### Requirement: Deployment Investigation

The agent MUST be able to inspect deployments, replica sets, and rollout status.

#### Scenario: List deployments
- **WHEN** agent needs to see deployments
- **THEN** agent runs `kubectl get deployments -n <namespace>` and receives deployment names, ready/desired counts

#### Scenario: Get deployment details
- **WHEN** agent needs deployment configuration
- **THEN** agent runs `kubectl describe deployment <name> -n <namespace>` and receives strategy, selectors, conditions, events

#### Scenario: Get replica sets
- **WHEN** agent needs to see replica set history
- **THEN** agent runs `kubectl get rs -n <namespace>` and receives replica set versions

---

### Requirement: Node Investigation

The agent MUST be able to inspect node health and resource utilization.

#### Scenario: List nodes
- **WHEN** agent needs to see cluster nodes
- **THEN** agent runs `kubectl get nodes` and receives node names, status, roles, version

#### Scenario: Get node details
- **WHEN** agent needs node conditions and capacity
- **THEN** agent runs `kubectl describe node <node>` and receives conditions, allocatable resources, pods

#### Scenario: Get node resource usage
- **WHEN** agent needs current resource utilization
- **THEN** agent runs `kubectl top nodes` and receives CPU/memory usage percentages

---

### Requirement: PVC Investigation

The agent MUST be able to inspect persistent volume claims and their bindings.

#### Scenario: List PVCs
- **WHEN** agent needs to see storage claims
- **THEN** agent runs `kubectl get pvc -n <namespace>` and receives PVC names, status, capacity, storage class

#### Scenario: Get PVC details
- **WHEN** agent needs PVC binding information
- **THEN** agent runs `kubectl describe pvc <name> -n <namespace>` and receives bound volume, access modes, events

---

### Requirement: Events Investigation

The agent MUST be able to inspect cluster events to understand recent activity.

#### Scenario: Get recent events
- **WHEN** agent needs to see what happened recently
- **THEN** agent runs `kubectl get events -n <namespace> --sort-by='.lastTimestamp'` and receives chronological event list

#### Scenario: Get events for specific resource
- **WHEN** agent needs events for a specific resource
- **THEN** agent runs `kubectl get events -n <namespace> --field-selector involvedObject.name=<name>` and receives filtered events

---

### Requirement: HPA and Scaling Investigation

The agent MUST be able to inspect autoscaling configuration and status.

#### Scenario: List HPAs
- **WHEN** agent needs to see autoscalers
- **THEN** agent runs `kubectl get hpa -n <namespace>` and receives HPA names, targets, min/max/current replicas

#### Scenario: Get HPA details
- **WHEN** agent needs autoscaler configuration
- **THEN** agent runs `kubectl describe hpa <name> -n <namespace>` and receives metrics, conditions, events

#### Scenario: List KEDA ScaledObjects
- **WHEN** agent needs to see KEDA scalers
- **THEN** agent runs `kubectl get scaledobjects -n <namespace>` and receives scaler names, triggers, status

---

### Requirement: Service and Endpoint Investigation

The agent MUST be able to inspect services and their endpoints.

#### Scenario: List services
- **WHEN** agent needs to see services
- **THEN** agent runs `kubectl get services -n <namespace>` and receives service names, types, cluster IPs, ports

#### Scenario: Get endpoints
- **WHEN** agent needs to see service backends
- **THEN** agent runs `kubectl get endpoints -n <namespace>` and receives endpoint addresses and ports
