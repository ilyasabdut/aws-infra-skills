---
name: Diagnostic Workflows
description: Step-by-step diagnostic procedures for Kubernetes (pods, nodes, deployments, services) and AWS (EKS, EC2, RDS, Lambda, SQS, ALB, API Gateway, CloudFront, DynamoDB, ElastiCache, Step Functions, Kinesis) infrastructure issues.
---

# Diagnostic Workflows

Systematic procedures for diagnosing common infrastructure issues. All commands are read-only.

## When to Use

Use this skill when you need to diagnose:
- Pod crashes (CrashLoopBackOff, OOMKilled, ImagePullBackOff)
- Pending pods that won't schedule
- Node issues (NotReady, resource pressure)
- Deployment problems (unavailable replicas, stuck rollouts)
- Scaling issues (HPA, KEDA)
- Service connectivity problems
- Storage issues (PVC pending, volume mount failures)
- Network policy blocking traffic
- DNS resolution failures
- EKS cluster health
- EC2 instance connectivity issues
- RDS connection issues
- Lambda timeout and cold start problems
- SQS dead letter queue buildup
- Load balancer health check failures
- API Gateway 5xx errors and latency
- CloudFront cache and origin issues
- DynamoDB throttling and latency
- ElastiCache connection and performance
- Step Functions execution failures
- Kinesis stream throughput issues

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

## Storage Issues

### PVC Pending (Not Bound)

```bash
# 1. Check PVC status
kubectl get pvc <name> -n <namespace>

# 2. Check PVC events
kubectl describe pvc <name> -n <namespace>

# 3. Check StorageClass
kubectl get storageclass
kubectl describe storageclass <name>

# 4. Check available PVs (for static provisioning)
kubectl get pv

# 5. Check CSI driver pods
kubectl get pods -n kube-system -l app=ebs-csi-controller
kubectl logs -n kube-system -l app=ebs-csi-controller --tail=50

# 6. Check AWS EBS volumes
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/<cluster>,Values=owned"
```

**Likely causes:**
- StorageClass doesn't exist
- No matching PV available (static provisioning)
- CSI driver not installed or unhealthy
- Zone mismatch (EBS volumes are AZ-specific)
- Insufficient AWS permissions for CSI driver

### Pod Stuck on Volume Mount

```bash
# 1. Check pod events for mount errors
kubectl describe pod <pod> -n <namespace> | grep -A10 "Events:"

# 2. Check volume attachments
kubectl get volumeattachments

# 3. Check node where pod is scheduled
kubectl get pod <pod> -n <namespace> -o jsonpath='{.spec.nodeName}'

# 4. Check EBS attachment from AWS
aws ec2 describe-volumes --volume-ids <vol-id> --query 'Volumes[*].Attachments'

# 5. Check if volume is stuck in attaching state
kubectl describe volumeattachment <name>
```

**Likely causes:**
- Volume attached to different node (multi-attach not supported)
- Node cannot reach EBS (network/IAM issue)
- Volume in wrong AZ
- Stale volume attachment from crashed node

## Network Policy Issues

### Traffic Blocked by NetworkPolicy

```bash
# 1. List all network policies in namespace
kubectl get networkpolicies -n <namespace>

# 2. Check policy details
kubectl describe networkpolicy <name> -n <namespace>

# 3. Check pod labels (policies select by label)
kubectl get pod <pod> -n <namespace> --show-labels

# 4. Check if pod matches any policy
kubectl get networkpolicies -n <namespace> -o yaml | grep -A20 "podSelector:"

# 5. Check namespace labels (for namespace selectors)
kubectl get namespace <ns> --show-labels

# 6. Check if CNI supports network policies
kubectl get pods -n kube-system | grep -E "(calico|cilium|weave)"
```

**Understanding NetworkPolicy:**
- Default: all traffic allowed (no policies = open)
- Once ANY policy selects a pod → default deny for that direction
- Ingress policy: controls incoming traffic TO the pod
- Egress policy: controls outgoing traffic FROM the pod

**Debugging approach:**
1. Does the pod match any NetworkPolicy selector?
2. If yes, does the policy allow the required traffic?
3. Check both ingress AND egress policies
4. Check namespace labels for cross-namespace rules

### DNS Resolution Failing

```bash
# 1. Check CoreDNS pods
kubectl get pods -n kube-system -l k8s-app=kube-dns

# 2. Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=50

# 3. Check DNS service
kubectl get svc -n kube-system kube-dns
kubectl get endpoints -n kube-system kube-dns

# 4. Check if NetworkPolicy blocks DNS (UDP 53)
kubectl get networkpolicies -n <namespace> -o yaml | grep -A30 "egress:"

# 5. Check CoreDNS configmap
kubectl get configmap -n kube-system coredns -o yaml
```

**Likely causes:**
- NetworkPolicy blocking egress to kube-dns (UDP 53)
- CoreDNS pods not running or unhealthy
- CoreDNS service has no endpoints
- Custom DNS config issue

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

### RDS Connection Issues

```bash
# 1. Check RDS instance status
aws rds describe-db-instances --db-instance-identifier <instance> \
  --query 'DBInstances[].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}'

# 2. Check recent events
aws rds describe-events --source-identifier <instance> --source-type db-instance --duration 60

# 3. Check security group allows ingress
aws rds describe-db-instances --db-instance-identifier <instance> \
  --query 'DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId' --output text | \
  xargs -I {} aws ec2 describe-security-groups --group-ids {}

# 4. Check subnet group connectivity
aws rds describe-db-subnet-groups --db-subnet-group-name <subnet-group>

# 5. Check CloudWatch for connection count
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=<instance> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average Maximum
```

**Likely causes:**
- Security group not allowing inbound on DB port (3306/5432)
- Instance in wrong subnet (not reachable from app)
- Max connections reached
- Instance stopped or in maintenance

### Lambda Timeout/Cold Start Issues

```bash
# 1. Check function configuration
aws lambda get-function-configuration --function-name <function> \
  --query '{Timeout:Timeout,Memory:MemorySize,Runtime:Runtime}'

# 2. Check recent invocations - duration
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=<function> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average Maximum

# 3. Check errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=<function> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 4. Check throttles
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=<function> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 5. Check logs for timeout/error
aws logs filter-log-events \
  --log-group-name /aws/lambda/<function> \
  --filter-pattern "?ERROR ?Task timed out ?REPORT"
```

**Likely causes:**
- Timeout too low for workload
- Cold start in VPC (add provisioned concurrency)
- Memory too low (increases CPU proportionally)
- External dependency slow (DB, API)

### SQS Dead Letter Queue Investigation

```bash
# 1. Check DLQ message count
aws sqs get-queue-attributes \
  --queue-url <dlq-url> \
  --attribute-names ApproximateNumberOfMessages

# 2. Check source queue's redrive policy
aws sqs get-queue-attributes \
  --queue-url <source-queue-url> \
  --attribute-names RedrivePolicy

# 3. Peek at DLQ messages (receive but don't delete)
aws sqs receive-message \
  --queue-url <dlq-url> \
  --max-number-of-messages 5 \
  --visibility-timeout 0

# 4. Check Lambda consumer errors (if Lambda processes queue)
aws logs filter-log-events \
  --log-group-name /aws/lambda/<consumer-function> \
  --filter-pattern "ERROR"

# 5. Check source queue age of oldest message
aws cloudwatch get-metric-statistics \
  --namespace AWS/SQS \
  --metric-name ApproximateAgeOfOldestMessage \
  --dimensions Name=QueueName,Value=<queue-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Maximum
```

**Likely causes:**
- Consumer function failing repeatedly
- Message format changed, consumer can't parse
- Downstream dependency failing
- maxReceiveCount too low for retry-able errors

### Load Balancer Health Check Failures

```bash
# 1. Check target health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# 2. Check health check configuration
aws elbv2 describe-target-groups --target-group-arns <tg-arn> \
  --query 'TargetGroups[].{Path:HealthCheckPath,Port:HealthCheckPort,Interval:HealthCheckIntervalSeconds,Threshold:UnhealthyThresholdCount}'

# 3. Check security group allows health check
aws elbv2 describe-load-balancers --load-balancer-arns <lb-arn> \
  --query 'LoadBalancers[].SecurityGroups' --output text | \
  xargs -I {} aws ec2 describe-security-groups --group-ids {}

# 4. Check target security group allows LB
# (targets need to allow inbound from LB security group)

# 5. Check unhealthy host count metric
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name UnHealthyHostCount \
  --dimensions Name=TargetGroup,Value=<tg-arn-suffix> Name=LoadBalancer,Value=<lb-arn-suffix> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Maximum
```

**Likely causes:**
- Health check path returns non-200 status
- Security group blocks health check port
- Application not listening on expected port
- Health check timeout too short

### EC2 Instance Connectivity Issues

```bash
# 1. Check instance state
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[].Instances[].{State:State.Name,Status:StateReason.Message}'

# 2. Check instance status checks
aws ec2 describe-instance-status --instance-ids <instance-id>

# 3. Check security groups
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text | \
  xargs -I {} aws ec2 describe-security-groups --group-ids {}

# 4. Check network ACLs for subnet
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[].Instances[].SubnetId' --output text | \
  xargs -I {} aws ec2 describe-network-acls --filters Name=association.subnet-id,Values={}

# 5. Check route table
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[].Instances[].SubnetId' --output text | \
  xargs -I {} aws ec2 describe-route-tables --filters Name=association.subnet-id,Values={}

# 6. Check if instance has public IP or NAT
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[].Instances[].{PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}'
```

**Likely causes:**
- Security group not allowing inbound/outbound traffic
- Network ACL blocking traffic
- No route to internet (missing NAT gateway or IGW)
- Instance in stopped state
- System/instance status check failed

### API Gateway 5xx/Latency Issues

```bash
# 1. Check 5xx errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name 5XXError \
  --dimensions Name=ApiName,Value=<api-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 2. Check latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Latency \
  --dimensions Name=ApiName,Value=<api-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average p99

# 3. Check integration latency (backend)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name IntegrationLatency \
  --dimensions Name=ApiName,Value=<api-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average p99

# 4. Check throttling
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Count \
  --dimensions Name=ApiName,Value=<api-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 5. Check execution logs (if enabled)
aws logs filter-log-events \
  --log-group-name API-Gateway-Execution-Logs_<api-id>/<stage> \
  --filter-pattern "?5xx ?error ?timeout" \
  --limit 50
```

**Likely causes:**
- Backend integration timeout (Lambda, HTTP endpoint)
- Backend returning 5xx errors
- Throttling due to rate limits
- VPC link connectivity issues (for private integrations)

### CloudFront Cache/Origin Issues

```bash
# 1. Check error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name 5xxErrorRate \
  --dimensions Name=DistributionId,Value=<distribution-id> Name=Region,Value=Global \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average

# 2. Check cache hit ratio
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=<distribution-id> Name=Region,Value=Global \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average

# 3. Check origin latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name OriginLatency \
  --dimensions Name=DistributionId,Value=<distribution-id> Name=Region,Value=Global \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average p99

# 4. Check distribution status and origins
aws cloudfront get-distribution --id <distribution-id> \
  --query 'Distribution.{Status:Status,Origins:DistributionConfig.Origins.Items[].DomainName}'

# 5. Check recent invalidations
aws cloudfront list-invalidations --distribution-id <distribution-id> --max-items 10
```

**Likely causes:**
- Origin server returning errors
- Origin timeout (default 30s)
- Low cache hit ratio due to cache policy
- Distribution not deployed yet
- SSL certificate issues with origin

### DynamoDB Throttling/Latency Issues

```bash
# 1. Check consumed vs provisioned capacity
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=<table-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 2. Check throttled requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=<table-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 3. Check table status and capacity mode
aws dynamodb describe-table --table-name <table-name> \
  --query 'Table.{Status:TableStatus,BillingMode:BillingModeSummary.BillingMode,RCU:ProvisionedThroughput.ReadCapacityUnits,WCU:ProvisionedThroughput.WriteCapacityUnits}'

# 4. Check latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name SuccessfulRequestLatency \
  --dimensions Name=TableName,Value=<table-name> Name=Operation,Value=GetItem \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average p99

# 5. Check GSI throttling (if applicable)
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=<table-name> Name=GlobalSecondaryIndexName,Value=<gsi-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

**Likely causes:**
- Provisioned capacity too low for traffic
- Hot partition (uneven key distribution)
- GSI capacity lagging behind table
- Burst capacity exhausted
- Large item sizes increasing RCU/WCU consumption

### ElastiCache Connection/Performance Issues

```bash
# 1. Check cluster status
aws elasticache describe-cache-clusters --cache-cluster-id <cluster-id> \
  --query 'CacheClusters[].{Status:CacheClusterStatus,Engine:Engine,Nodes:NumCacheNodes}'

# 2. Check CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name CPUUtilization \
  --dimensions Name=CacheClusterId,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average Maximum

# 3. Check memory usage (Redis)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name DatabaseMemoryUsagePercentage \
  --dimensions Name=CacheClusterId,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average Maximum

# 4. Check connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name CurrConnections \
  --dimensions Name=CacheClusterId,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Maximum

# 5. Check evictions (memory pressure indicator)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name Evictions \
  --dimensions Name=CacheClusterId,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 6. Check security group
aws elasticache describe-cache-clusters --cache-cluster-id <cluster-id> \
  --query 'CacheClusters[].SecurityGroups[].SecurityGroupId' --output text | \
  xargs -I {} aws ec2 describe-security-groups --group-ids {}
```

**Likely causes:**
- Security group not allowing Redis port (6379) / Memcached port (11211)
- Memory exhausted (high evictions)
- CPU saturation on single-threaded Redis
- Max connections reached
- Cluster in maintenance or modifying state

### Step Functions Execution Failures

```bash
# 1. List recent failed executions
aws stepfunctions list-executions \
  --state-machine-arn <state-machine-arn> \
  --status-filter FAILED \
  --max-results 10

# 2. Get execution details
aws stepfunctions describe-execution --execution-arn <execution-arn>

# 3. Get execution history (find failed step)
aws stepfunctions get-execution-history \
  --execution-arn <execution-arn> \
  --query 'events[?type==`TaskFailed` || type==`ExecutionFailed`]'

# 4. Check state machine definition
aws stepfunctions describe-state-machine --state-machine-arn <state-machine-arn> \
  --query '{Name:name,Type:type,CreationDate:creationDate}'

# 5. Check execution metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/States \
  --metric-name ExecutionsFailed \
  --dimensions Name=StateMachineArn,Value=<state-machine-arn> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 6. Check throttling
aws cloudwatch get-metric-statistics \
  --namespace AWS/States \
  --metric-name ExecutionThrottled \
  --dimensions Name=StateMachineArn,Value=<state-machine-arn> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

**Likely causes:**
- Lambda task timeout or error
- Invalid JSON in state output
- Catch/Retry not handling transient errors
- IAM role missing permissions for task
- Service integration returning error

### Kinesis Stream Throughput Issues

```bash
# 1. Check stream status
aws kinesis describe-stream-summary --stream-name <stream-name>

# 2. Check write throughput exceeded
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name WriteProvisionedThroughputExceeded \
  --dimensions Name=StreamName,Value=<stream-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 3. Check read throughput exceeded
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name ReadProvisionedThroughputExceeded \
  --dimensions Name=StreamName,Value=<stream-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 4. Check iterator age (consumer lag)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name GetRecords.IteratorAgeMilliseconds \
  --dimensions Name=StreamName,Value=<stream-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Maximum

# 5. Check incoming records
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name IncomingRecords \
  --dimensions Name=StreamName,Value=<stream-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 6. List shards
aws kinesis list-shards --stream-name <stream-name>
```

**Likely causes:**
- Not enough shards for throughput (1 MB/s write, 2 MB/s read per shard)
- Hot shard (uneven partition key distribution)
- Consumer not keeping up (high iterator age)
- Multiple consumers exceeding read throughput
- Record size exceeding 1 MB limit

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

**Important**: All commands in this workflow are read-only. Write operations should be blocked by a safety hook in production agent environments.
