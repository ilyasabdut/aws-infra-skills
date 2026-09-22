---
name: Diagnostic Workflows
description: Step-by-step diagnostic procedures for Kubernetes (pods, nodes, deployments, services) and AWS (EKS, EC2, RDS, Lambda, SQS, ALB, API Gateway, CloudFront, DynamoDB, ElastiCache, Step Functions, Kinesis, CodeBuild, CodePipeline, EventBridge, Cognito, OpenSearch, ECS, Auto Scaling, SNS, WAF, Route53, ACM, Secrets Manager, S3, SSM, VPC, CloudTrail, EFS, Service Quotas) infrastructure issues.
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
- CodeBuild build failures
- CodePipeline execution failures
- EventBridge rules not triggering
- Cognito authentication issues
- OpenSearch cluster health issues
- ECS service and task issues
- Auto Scaling group issues
- SNS delivery issues
- WAF blocked requests
- Route53 health check failures
- ACM certificate issues
- Secrets Manager rotation issues
- S3 access/permission issues
- SSM parameter/command issues
- VPC connectivity issues
- CloudTrail event investigation
- EFS mount/performance issues
- Service quotas/limits issues

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

### CodeBuild Build Failures

```bash
# 1. List recent failed builds
aws codebuild list-builds-for-project --project-name <project-name> \
  --sort-order DESCENDING --max-items 10 | \
  xargs -I {} aws codebuild batch-get-builds --ids {} \
  --query 'builds[?buildStatus==`FAILED`].{Id:id,Phase:currentPhase,Status:buildStatus}'

# 2. Get build details
aws codebuild batch-get-builds --ids <build-id> \
  --query 'builds[].{Status:buildStatus,Phase:currentPhase,StartTime:startTime,EndTime:endTime}'

# 3. Get build phases (find which phase failed)
aws codebuild batch-get-builds --ids <build-id> \
  --query 'builds[].phases[?phaseStatus==`FAILED`]'

# 4. Check build logs
aws logs filter-log-events \
  --log-group-name /aws/codebuild/<project-name> \
  --filter-pattern "?error ?Error ?ERROR ?failed ?Failed ?FAILED" \
  --limit 50

# 5. Check project configuration
aws codebuild batch-get-projects --names <project-name> \
  --query 'projects[].{Source:source.type,Compute:environment.computeType,Image:environment.image}'
```

**Likely causes:**
- Build command failed (check buildspec.yml)
- Missing environment variables or secrets
- Dependency download failed (network/permissions)
- Insufficient compute resources (timeout)
- Docker build issues (if using custom image)

### CodePipeline Execution Failures

```bash
# 1. Get pipeline state
aws codepipeline get-pipeline-state --name <pipeline-name>

# 2. List recent executions
aws codepipeline list-pipeline-executions --pipeline-name <pipeline-name> --max-results 10

# 3. Get failed execution details
aws codepipeline get-pipeline-execution \
  --pipeline-name <pipeline-name> \
  --pipeline-execution-id <execution-id>

# 4. List action executions (find failed action)
aws codepipeline list-action-executions \
  --pipeline-name <pipeline-name> \
  --filter pipelineExecutionId=<execution-id>

# 5. Check pipeline definition
aws codepipeline get-pipeline --name <pipeline-name> \
  --query 'pipeline.stages[].{Name:name,Actions:actions[].name}'
```

**Likely causes:**
- Source stage: webhook/polling not triggered, branch not found
- Build stage: CodeBuild project failed (see above)
- Deploy stage: IAM permissions, deployment target unhealthy
- Approval stage: manual approval pending/rejected
- Action timeout exceeded

### EventBridge Rule Not Triggering

```bash
# 1. Check rule state
aws events describe-rule --name <rule-name> \
  --query '{State:State,Schedule:ScheduleExpression,EventPattern:EventPattern}'

# 2. Check rule targets
aws events list-targets-by-rule --rule <rule-name>

# 3. Check invocations metric
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name Invocations \
  --dimensions Name=RuleName,Value=<rule-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 4. Check failed invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name FailedInvocations \
  --dimensions Name=RuleName,Value=<rule-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 5. Check dead-letter queue (if configured)
aws events describe-rule --name <rule-name> --query 'DeadLetterConfig'

# 6. Check if event bus is correct
aws events list-rules --event-bus-name <event-bus-name> --name-prefix <rule-prefix>
```

**Likely causes:**
- Rule is DISABLED
- Event pattern doesn't match incoming events
- Schedule expression syntax error
- Target IAM role missing permissions
- Target (Lambda/SQS/etc) returning errors
- Using wrong event bus (default vs custom)

### Cognito Authentication Issues

```bash
# 1. Check user pool status
aws cognito-idp describe-user-pool --user-pool-id <user-pool-id> \
  --query 'UserPool.{Status:Status,Name:Name,MfaConfiguration:MfaConfiguration}'

# 2. Check user status
aws cognito-idp admin-get-user --user-pool-id <user-pool-id> --username <username> \
  --query '{Status:UserStatus,Enabled:Enabled,MFA:MFAOptions}'

# 3. Check app client configuration
aws cognito-idp describe-user-pool-client \
  --user-pool-id <user-pool-id> \
  --client-id <client-id> \
  --query 'UserPoolClient.{Name:ClientName,TokenValidity:AccessTokenValidity,AuthFlows:ExplicitAuthFlows}'

# 4. Check sign-in failures (CloudWatch)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Cognito \
  --metric-name SignInSuccesses \
  --dimensions Name=UserPool,Value=<user-pool-id> Name=UserPoolClient,Value=<client-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# 5. Check token generation failures
aws cloudwatch get-metric-statistics \
  --namespace AWS/Cognito \
  --metric-name TokenRefreshSuccesses \
  --dimensions Name=UserPool,Value=<user-pool-id> Name=UserPoolClient,Value=<client-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# 6. Check identity pool (if using federated identities)
aws cognito-identity describe-identity-pool --identity-pool-id <identity-pool-id>
```

**Likely causes:**
- User not confirmed or disabled
- Incorrect client ID or secret
- Auth flow not enabled for app client
- Token expired (check validity settings)
- MFA required but not provided
- Lambda trigger failing (pre-auth, post-auth)

### OpenSearch Cluster Health Issues

```bash
# 1. Check domain status
aws opensearch describe-domain --domain-name <domain-name> \
  --query 'DomainStatus.{Processing:Processing,Created:Created,Deleted:Deleted,Endpoint:Endpoint}'

# 2. Check cluster health (via CloudWatch)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name ClusterStatus.green \
  --dimensions Name=DomainName,Value=<domain-name> Name=ClientId,Value=<account-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Minimum

# 3. Check free storage space
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name FreeStorageSpace \
  --dimensions Name=DomainName,Value=<domain-name> Name=ClientId,Value=<account-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Minimum

# 4. Check JVM memory pressure
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name JVMMemoryPressure \
  --dimensions Name=DomainName,Value=<domain-name> Name=ClientId,Value=<account-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Maximum

# 5. Check CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name CPUUtilization \
  --dimensions Name=DomainName,Value=<domain-name> Name=ClientId,Value=<account-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average Maximum

# 6. Check indexing rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name IndexingRate \
  --dimensions Name=DomainName,Value=<domain-name> Name=ClientId,Value=<account-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum
```

**Likely causes:**
- Cluster status yellow/red (replica issues, node failure)
- Storage full (< 20% free triggers issues)
- JVM memory pressure > 80% (GC overhead, OOM risk)
- CPU saturation from heavy queries
- Too many shards for cluster size
- Network connectivity (VPC, security group)

### ECS Service/Task Issues

```bash
# 1. Check service status
aws ecs describe-services --cluster <cluster-name> --services <service-name> \
  --query 'services[].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}'

# 2. Check recent service events
aws ecs describe-services --cluster <cluster-name> --services <service-name> \
  --query 'services[].events[:10]'

# 3. List stopped tasks (find failures)
aws ecs list-tasks --cluster <cluster-name> --service-name <service-name> --desired-status STOPPED --max-items 10

# 4. Describe stopped task (get stop reason)
aws ecs describe-tasks --cluster <cluster-name> --tasks <task-arn> \
  --query 'tasks[].{StopCode:stopCode,StoppedReason:stoppedReason,Containers:containers[].{Name:name,ExitCode:exitCode,Reason:reason}}'

# 5. Check task definition
aws ecs describe-task-definition --task-definition <task-def> \
  --query 'taskDefinition.{CPU:cpu,Memory:memory,Containers:containerDefinitions[].{Name:name,Image:image,Memory:memory}}'

# 6. Check cluster capacity (for EC2 launch type)
aws ecs describe-clusters --clusters <cluster-name> \
  --query 'clusters[].{RegisteredInstances:registeredContainerInstancesCount,RunningTasks:runningTasksCount,PendingTasks:pendingTasksCount}'
```

**Likely causes:**
- Container exited with error (check exitCode and logs)
- Image pull failure (ECR permissions, image not found)
- Insufficient cluster capacity (EC2 launch type)
- Health check failures (ALB target group)
- Resource constraints (CPU/memory limits)
- Task role missing permissions

### Auto Scaling Issues

```bash
# 1. Check Auto Scaling group status
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[].{Desired:DesiredCapacity,Min:MinSize,Max:MaxSize,Instances:Instances[].{Id:InstanceId,Health:HealthStatus,State:LifecycleState}}'

# 2. Check scaling activities
aws autoscaling describe-scaling-activities --auto-scaling-group-name <asg-name> --max-items 10 \
  --query 'Activities[].{Status:StatusCode,Cause:Cause,Description:Description}'

# 3. Check scaling policies
aws autoscaling describe-policies --auto-scaling-group-name <asg-name> \
  --query 'ScalingPolicies[].{Name:PolicyName,Type:PolicyType,TargetValue:TargetTrackingConfiguration.TargetValue}'

# 4. Check instance refresh status (if in progress)
aws autoscaling describe-instance-refreshes --auto-scaling-group-name <asg-name> --max-records 5

# 5. Check CloudWatch alarms linked to ASG
aws cloudwatch describe-alarms --alarm-name-prefix <asg-name> \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue,Metric:MetricName}'

# 6. Check launch template/config
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name> \
  --query 'AutoScalingGroups[].{LaunchTemplate:LaunchTemplate,MixedPolicy:MixedInstancesPolicy}'
```

**Likely causes:**
- Max capacity reached (can't scale up)
- Launch template/config issues (AMI, instance type unavailable)
- Health check failures terminating instances
- Scaling policy not triggering (alarm threshold not met)
- Cooldown period preventing scaling
- Subnet has no available IPs

### SNS Delivery Issues

```bash
# 1. Check topic attributes
aws sns get-topic-attributes --topic-arn <topic-arn>

# 2. List subscriptions
aws sns list-subscriptions-by-topic --topic-arn <topic-arn>

# 3. Check subscription attributes (for specific endpoint)
aws sns get-subscription-attributes --subscription-arn <subscription-arn>

# 4. Check delivery metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/SNS \
  --metric-name NumberOfMessagesPublished \
  --dimensions Name=TopicName,Value=<topic-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 5. Check failed deliveries
aws cloudwatch get-metric-statistics \
  --namespace AWS/SNS \
  --metric-name NumberOfNotificationsFailed \
  --dimensions Name=TopicName,Value=<topic-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 6. Check delivery logs (if enabled)
aws logs filter-log-events \
  --log-group-name sns/<region>/<account-id>/<topic-name> \
  --filter-pattern "?FAILURE ?delivery" \
  --limit 20
```

**Likely causes:**
- Subscription not confirmed (PendingConfirmation status)
- Endpoint not reachable (Lambda error, HTTP endpoint down)
- Filter policy rejecting messages
- Dead-letter queue receiving failures
- IAM permissions for cross-account delivery
- Encryption key access issues (KMS)

### WAF Blocked Requests

```bash
# 1. Check Web ACL overview
aws wafv2 get-web-acl --name <web-acl-name> --scope REGIONAL --id <web-acl-id> \
  --query 'WebACL.{Name:Name,DefaultAction:DefaultAction,Rules:Rules[].Name}'

# 2. Check blocked requests metric
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=<web-acl-name> Name=Region,Value=<region> Name=Rule,Value=ALL \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 3. Check allowed vs blocked ratio
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name AllowedRequests \
  --dimensions Name=WebACL,Value=<web-acl-name> Name=Region,Value=<region> Name=Rule,Value=ALL \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# 4. Check sampled requests (if logging enabled)
aws wafv2 get-sampled-requests \
  --web-acl-arn <web-acl-arn> \
  --rule-metric-name <rule-name> \
  --scope REGIONAL \
  --time-window StartTime=$(date -u -v-3H +%Y-%m-%dT%H:%M:%SZ),EndTime=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --max-items 100

# 5. Check logging configuration
aws wafv2 get-logging-configuration --resource-arn <web-acl-arn>

# 6. Check WAF logs (if sent to CloudWatch)
aws logs filter-log-events \
  --log-group-name aws-waf-logs-<web-acl-name> \
  --filter-pattern '{ $.action = "BLOCK" }' \
  --limit 20
```

**Likely causes:**
- Rate-based rule triggered (too many requests from IP)
- SQL injection / XSS rule matched legitimate content
- Geo-restriction blocking valid region
- IP reputation list blocking CDN/proxy IPs
- Custom rule regex too aggressive
- Bot control blocking legitimate automation

### Route53 Health Check Failures

```bash
# 1. List health checks
aws route53 list-health-checks \
  --query 'HealthChecks[].{Id:Id,Name:HealthCheckConfig.FullyQualifiedDomainName,Type:HealthCheckConfig.Type}'

# 2. Get health check status
aws route53 get-health-check-status --health-check-id <health-check-id>

# 3. Get health check details
aws route53 get-health-check --health-check-id <health-check-id> \
  --query 'HealthCheck.HealthCheckConfig'

# 4. Check health check metric
aws cloudwatch get-metric-statistics \
  --namespace AWS/Route53 \
  --metric-name HealthCheckStatus \
  --dimensions Name=HealthCheckId,Value=<health-check-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Minimum

# 5. Check connection time
aws cloudwatch get-metric-statistics \
  --namespace AWS/Route53 \
  --metric-name ConnectionTime \
  --dimensions Name=HealthCheckId,Value=<health-check-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Average Maximum

# 6. List associated records
aws route53 list-resource-record-sets --hosted-zone-id <zone-id> \
  --query 'ResourceRecordSets[?HealthCheckId==`<health-check-id>`]'
```

**Likely causes:**
- Endpoint returning non-2xx status code
- Endpoint timeout (> configured threshold)
- SSL certificate issues (for HTTPS checks)
- Security group blocking Route53 health checker IPs
- String match failing (response body changed)
- Endpoint IP changed but health check not updated

### ACM Certificate Issues

```bash
# 1. List certificates
aws acm list-certificates \
  --query 'CertificateSummaryList[].{Domain:DomainName,Status:Status,Type:Type}'

# 2. Get certificate details
aws acm describe-certificate --certificate-arn <certificate-arn> \
  --query 'Certificate.{Domain:DomainName,Status:Status,Type:Type,NotAfter:NotAfter,InUse:InUseBy}'

# 3. Check validation status (for pending certificates)
aws acm describe-certificate --certificate-arn <certificate-arn> \
  --query 'Certificate.DomainValidationOptions[].{Domain:DomainName,Status:ValidationStatus,Method:ValidationMethod}'

# 4. Check certificate expiration
aws acm describe-certificate --certificate-arn <certificate-arn> \
  --query 'Certificate.{NotBefore:NotBefore,NotAfter:NotAfter,RenewalSummary:RenewalSummary}'

# 5. Check days until expiration metric
aws cloudwatch get-metric-statistics \
  --namespace AWS/CertificateManager \
  --metric-name DaysToExpiry \
  --dimensions Name=CertificateArn,Value=<certificate-arn> \
  --start-time $(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 86400 \
  --statistics Minimum

# 6. List certificates about to expire (< 30 days)
aws acm list-certificates --query 'CertificateSummaryList[?NotAfter<=`'$(date -u -v+30d +%Y-%m-%dT%H:%M:%SZ)'`]'
```

**Likely causes:**
- DNS validation record not created/propagated
- Email validation not completed
- Certificate expired (renewal failed)
- Domain ownership verification failed
- CAA record blocking certificate issuance
- Certificate not attached to load balancer/CloudFront

### Secrets Manager Rotation Issues

```bash
# 1. Check secret metadata
aws secretsmanager describe-secret --secret-id <secret-name> \
  --query '{Name:Name,RotationEnabled:RotationEnabled,LastRotated:LastRotatedDate,NextRotation:NextRotationDate}'

# 2. Check rotation configuration
aws secretsmanager describe-secret --secret-id <secret-name> \
  --query '{RotationLambda:RotationLambdaARN,RotationRules:RotationRules}'

# 3. Check secret versions
aws secretsmanager list-secret-version-ids --secret-id <secret-name> \
  --query 'Versions[].{VersionId:VersionId,Stages:VersionStages,Created:CreatedDate}'

# 4. Check rotation Lambda logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/<rotation-lambda-name> \
  --filter-pattern "?ERROR ?error ?failed ?Failed" \
  --limit 50

# 5. Check rotation Lambda errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=<rotation-lambda-name> \
  --start-time $(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 3600 \
  --statistics Sum

# 6. Manually trigger test rotation (read current state first)
aws secretsmanager get-secret-value --secret-id <secret-name> --version-stage AWSCURRENT \
  --query '{VersionId:VersionId}'
```

**Likely causes:**
- Rotation Lambda missing permissions
- Rotation Lambda can't reach database (VPC/security group)
- Database credentials in secret don't have ALTER USER permission
- AWSPENDING version stuck (previous rotation failed mid-way)
- Rotation schedule misconfigured
- KMS key permissions for Lambda

### S3 Access/Permission Issues

```bash
# 1. Check bucket exists and location
aws s3api head-bucket --bucket <bucket-name> 2>&1 || echo "Bucket not accessible"
aws s3api get-bucket-location --bucket <bucket-name>

# 2. Check bucket policy
aws s3api get-bucket-policy --bucket <bucket-name> --query 'Policy' --output text | jq .

# 3. Check bucket ACL
aws s3api get-bucket-acl --bucket <bucket-name>

# 4. Check public access block
aws s3api get-public-access-block --bucket <bucket-name>

# 5. Check object ownership
aws s3api get-bucket-ownership-controls --bucket <bucket-name>

# 6. Check if object exists and metadata
aws s3api head-object --bucket <bucket-name> --key <object-key>

# 7. Check bucket encryption
aws s3api get-bucket-encryption --bucket <bucket-name>

# 8. Check CORS configuration (for browser access issues)
aws s3api get-bucket-cors --bucket <bucket-name>
```

**Likely causes:**
- Bucket policy denying access
- Public access block preventing intended access
- Missing s3:GetObject or s3:PutObject permissions
- Object ownership set to BucketOwnerEnforced (ACLs disabled)
- KMS key permissions for encrypted objects
- CORS not configured for browser access
- VPC endpoint policy restricting access

### SSM Parameter/Command Issues

```bash
# 1. Check parameter exists
aws ssm get-parameter --name <parameter-name> --query 'Parameter.{Name:Name,Type:Type,Version:Version}'

# 2. Check parameter history
aws ssm get-parameter-history --name <parameter-name> --max-results 5

# 3. Check SSM agent status on instance
aws ssm describe-instance-information --filters Key=InstanceIds,Values=<instance-id> \
  --query 'InstanceInformationList[].{Id:InstanceId,Status:PingStatus,Agent:AgentVersion,Platform:PlatformType}'

# 4. Check command invocation status
aws ssm list-command-invocations --command-id <command-id> \
  --query 'CommandInvocations[].{Instance:InstanceId,Status:Status,StatusDetails:StatusDetails}'

# 5. Get command output
aws ssm get-command-invocation --command-id <command-id> --instance-id <instance-id> \
  --query '{Status:Status,Output:StandardOutputContent,Error:StandardErrorContent}'

# 6. Check SSM agent logs (via Run Command if agent responsive)
aws ssm list-commands --instance-id <instance-id> --max-results 10 \
  --query 'Commands[].{Id:CommandId,Status:Status,Doc:DocumentName}'

# 7. Check Systems Manager inventory
aws ssm get-inventory --instance-ids <instance-id>
```

**Likely causes:**
- SSM agent not installed or not running
- Instance not registered with SSM (missing IAM role)
- Network connectivity to SSM endpoints (VPC endpoint or NAT)
- Parameter not found or wrong path
- KMS permissions for SecureString parameters
- Command timeout (long-running script)
- Instance in terminated/stopped state

### VPC Connectivity Issues

```bash
# 1. Check VPC configuration
aws ec2 describe-vpcs --vpc-ids <vpc-id> \
  --query 'Vpcs[].{Id:VpcId,Cidr:CidrBlock,State:State}'

# 2. Check subnets
aws ec2 describe-subnets --filters Name=vpc-id,Values=<vpc-id> \
  --query 'Subnets[].{Id:SubnetId,Cidr:CidrBlock,AZ:AvailabilityZone,Public:MapPublicIpOnLaunch,AvailableIPs:AvailableIpAddressCount}'

# 3. Check route tables
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-id> \
  --query 'RouteTables[].{Id:RouteTableId,Routes:Routes[].{Dest:DestinationCidrBlock,Target:GatewayId||NatGatewayId||TransitGatewayId}}'

# 4. Check NAT gateways
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=<vpc-id> \
  --query 'NatGateways[].{Id:NatGatewayId,State:State,Subnet:SubnetId}'

# 5. Check Internet Gateway
aws ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values=<vpc-id> \
  --query 'InternetGateways[].{Id:InternetGatewayId,State:Attachments[0].State}'

# 6. Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=<vpc-id> \
  --query 'VpcEndpoints[].{Id:VpcEndpointId,Service:ServiceName,Type:VpcEndpointType,State:State}'

# 7. Check NACLs
aws ec2 describe-network-acls --filters Name=vpc-id,Values=<vpc-id> \
  --query 'NetworkAcls[].{Id:NetworkAclId,Inbound:Entries[?Egress==`false`],Outbound:Entries[?Egress==`true`]}'

# 8. Check VPC Flow Logs (if enabled)
aws ec2 describe-flow-logs --filter Name=resource-id,Values=<vpc-id> \
  --query 'FlowLogs[].{Id:FlowLogId,Status:FlowLogStatus,LogGroup:LogGroupName}'
```

**Likely causes:**
- No route to destination (missing route in route table)
- NAT gateway in wrong subnet or failed state
- Internet gateway not attached
- NACL blocking traffic (stateless, check both inbound/outbound)
- Security group rules (checked at instance level)
- VPC endpoint policy too restrictive
- Subnet has no available IPs
- VPC peering/Transit Gateway route missing

### CloudTrail Event Investigation

```bash
# 1. Check trail status
aws cloudtrail get-trail-status --name <trail-name> \
  --query '{IsLogging:IsLogging,LatestDeliveryTime:LatestDeliveryTime,LatestDeliveryError:LatestDeliveryError}'

# 2. List trails
aws cloudtrail describe-trails \
  --query 'trailList[].{Name:Name,Bucket:S3BucketName,IsMultiRegion:IsMultiRegionTrail,IsOrg:IsOrganizationTrail}'

# 3. Look up recent events by user
aws cloudtrail lookup-events --lookup-attributes AttributeKey=Username,AttributeValue=<username> \
  --max-results 10 --query 'Events[].{Time:EventTime,Name:EventName,Source:EventSource}'

# 4. Look up events by resource
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=<resource-name> \
  --max-results 10

# 5. Look up events by event name (e.g., DeleteBucket)
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=<event-name> \
  --max-results 20

# 6. Check for errors in recent API calls
aws cloudtrail lookup-events --max-results 50 \
  --query 'Events[?contains(CloudTrailEvent, `errorCode`)].{Time:EventTime,Name:EventName,User:Username}'

# 7. Check event selectors (what's being logged)
aws cloudtrail get-event-selectors --trail-name <trail-name>
```

**Likely causes:**
- Trail logging stopped (IsLogging: false)
- S3 bucket policy changed, blocking delivery
- KMS key permissions for encrypted trails
- Event selectors filtering out needed events
- Multi-region trail needed but not configured
- Management events vs data events not selected

### EFS Mount/Performance Issues

```bash
# 1. Check file system status
aws efs describe-file-systems --file-system-id <fs-id> \
  --query 'FileSystems[].{Id:FileSystemId,State:LifeCycleState,Size:SizeInBytes.Value,Mode:PerformanceMode,Throughput:ThroughputMode}'

# 2. Check mount targets
aws efs describe-mount-targets --file-system-id <fs-id> \
  --query 'MountTargets[].{Id:MountTargetId,State:LifeCycleState,Subnet:SubnetId,IP:IpAddress,AZ:AvailabilityZoneName}'

# 3. Check mount target security groups
aws efs describe-mount-target-security-groups --mount-target-id <mount-target-id>

# 4. Check access points
aws efs describe-access-points --file-system-id <fs-id> \
  --query 'AccessPoints[].{Id:AccessPointId,State:LifeCycleState,Path:RootDirectory.Path,PosixUser:PosixUser}'

# 5. Check file system policy
aws efs describe-file-system-policy --file-system-id <fs-id>

# 6. Check CloudWatch metrics for throughput/IOPS
aws cloudwatch get-metric-statistics --namespace AWS/EFS --metric-name TotalIOBytes \
  --dimensions Name=FileSystemId,Value=<fs-id> --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) --period 300 --statistics Sum

# 7. Check burst credits (for bursting throughput mode)
aws cloudwatch get-metric-statistics --namespace AWS/EFS --metric-name BurstCreditBalance \
  --dimensions Name=FileSystemId,Value=<fs-id> --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) --period 300 --statistics Average
```

**Likely causes:**
- Mount target not in same AZ as EC2 instance
- Security group blocking NFS port 2049
- File system policy denying access
- Burst credits exhausted (bursting mode)
- VPC DNS resolution not enabled
- Subnet route table missing
- Access point POSIX permissions mismatch

### Service Quotas/Limits Issues

```bash
# 1. Check specific quota value
aws service-quotas get-service-quota --service-code <service-code> --quota-code <quota-code> \
  --query '{Name:QuotaName,Value:Value,Adjustable:Adjustable}'

# 2. List quotas for a service
aws service-quotas list-service-quotas --service-code <service-code> \
  --query 'Quotas[].{Name:QuotaName,Value:Value,Code:QuotaCode}' | head -30

# 3. Get default quota value
aws service-quotas get-aws-default-service-quota --service-code <service-code> --quota-code <quota-code>

# 4. Check quota request history
aws service-quotas list-requested-service-quota-change-history-by-quota \
  --service-code <service-code> --quota-code <quota-code> \
  --query 'RequestedQuotas[].{Status:Status,Requested:DesiredValue,Created:Created}'

# 5. List all services
aws service-quotas list-services --query 'Services[].{Code:ServiceCode,Name:ServiceName}'

# 6. Common quotas to check
# EC2 On-Demand instances
aws service-quotas get-service-quota --service-code ec2 --quota-code L-1216C47A
# Lambda concurrent executions
aws service-quotas get-service-quota --service-code lambda --quota-code L-B99A9384
# EBS gp3 volume storage
aws service-quotas get-service-quota --service-code ebs --quota-code L-7A658B76
# VPCs per region
aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE

# 7. Check CloudWatch for quota usage alarms
aws cloudwatch describe-alarms --alarm-name-prefix "ServiceQuota" \
  --query 'MetricAlarms[].{Name:AlarmName,State:StateValue}'
```

**Likely causes:**
- Quota reached (request increase via console or API)
- Regional quota vs global quota confusion
- Applied quota lower than default (check history)
- Service not supported in region
- Account-level limits (new accounts have lower limits)
- Resource-specific limits (e.g., rules per security group)

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
