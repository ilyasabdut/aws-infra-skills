---
name: AWS Investigation
description: Read-only AWS CLI patterns for investigating EKS clusters, EC2 instances, CloudWatch logs/metrics, load balancers, and S3.
---

# AWS Investigation Skill

Read-only AWS CLI patterns for infrastructure investigation. All commands are non-destructive.

## When to Use

Use this skill when investigating:
- EKS cluster health and configuration
- EC2 instance status and performance
- CloudWatch logs for errors or patterns
- CloudWatch metrics for resource utilization
- Load balancer health and target status
- S3 bucket contents (read-only)

## Quick Reference

| What | Command |
|------|---------|
| EKS clusters | `aws eks list-clusters` |
| Cluster details | `aws eks describe-cluster --name <name>` |
| Nodegroups | `aws eks list-nodegroups --cluster-name <name>` |
| EC2 instances | `aws ec2 describe-instances` |
| CloudWatch logs | `aws logs filter-log-events --log-group-name <group>` |

## EKS Cluster Investigation

### List clusters
```bash
aws eks list-clusters --region <region>
aws eks list-clusters --output table
```

### Cluster details
```bash
aws eks describe-cluster --name <cluster-name>

# Just status
aws eks describe-cluster --name <cluster-name> --query 'cluster.status'

# Endpoint and version
aws eks describe-cluster --name <cluster-name> --query 'cluster.{endpoint:endpoint,version:version,status:status}'
```

### Nodegroups
```bash
# List nodegroups
aws eks list-nodegroups --cluster-name <cluster-name>

# Nodegroup details
aws eks describe-nodegroup \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name>

# Scaling config
aws eks describe-nodegroup \
  --cluster-name <cluster-name> \
  --nodegroup-name <nodegroup-name> \
  --query 'nodegroup.scalingConfig'
```

### Addons
```bash
aws eks list-addons --cluster-name <cluster-name>
aws eks describe-addon --cluster-name <cluster-name> --addon-name <addon>
```

### Updates
```bash
aws eks list-updates --cluster-name <cluster-name>
aws eks describe-update --cluster-name <cluster-name> --update-id <id>
```

## EC2 Instance Investigation

### List instances
```bash
# All instances
aws ec2 describe-instances

# Filter by tag (EKS nodes)
aws ec2 describe-instances \
  --filters "Name=tag:kubernetes.io/cluster/<cluster-name>,Values=owned"

# Running instances only
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running"
```

### Instance details
```bash
aws ec2 describe-instances --instance-ids <instance-id>

# Compact output
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name,AZ:Placement.AvailabilityZone,IP:PrivateIpAddress}'
```

### Instance status checks
```bash
aws ec2 describe-instance-status --instance-ids <instance-id>

# Include all instances (not just with issues)
aws ec2 describe-instance-status --instance-ids <instance-id> --include-all-instances
```

### Volumes
```bash
# List volumes
aws ec2 describe-volumes

# Volumes for instance
aws ec2 describe-volumes --filters "Name=attachment.instance-id,Values=<instance-id>"
```

## CloudWatch Logs

### List log groups
```bash
aws logs describe-log-groups
aws logs describe-log-groups --log-group-name-prefix /aws/eks
aws logs describe-log-groups --log-group-name-prefix /aws/containerinsights
```

### List log streams
```bash
aws logs describe-log-streams \
  --log-group-name <log-group> \
  --order-by LastEventTime \
  --descending \
  --limit 10
```

### Get log events
```bash
# From specific stream
aws logs get-log-events \
  --log-group-name <log-group> \
  --log-stream-name <stream-name> \
  --limit 100

# Start from end (most recent)
aws logs get-log-events \
  --log-group-name <log-group> \
  --log-stream-name <stream-name> \
  --start-from-head false
```

### Filter/search logs
```bash
# Filter by pattern
aws logs filter-log-events \
  --log-group-name <log-group> \
  --filter-pattern "ERROR"

# Time range (milliseconds since epoch)
aws logs filter-log-events \
  --log-group-name <log-group> \
  --start-time <timestamp> \
  --end-time <timestamp> \
  --filter-pattern "OOMKilled"

# Multiple streams
aws logs filter-log-events \
  --log-group-name <log-group> \
  --log-stream-name-prefix <prefix>
```

### Common log patterns
```bash
# EKS control plane logs
aws logs filter-log-events \
  --log-group-name /aws/eks/<cluster>/cluster \
  --filter-pattern "error"

# Container Insights
aws logs filter-log-events \
  --log-group-name /aws/containerinsights/<cluster>/performance \
  --filter-pattern "pod_name=<pod>"
```

## CloudWatch Metrics

### List metrics
```bash
# All metrics for a namespace
aws cloudwatch list-metrics --namespace AWS/EKS
aws cloudwatch list-metrics --namespace ContainerInsights
aws cloudwatch list-metrics --namespace AWS/EC2
```

### Get metric statistics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<instance-id> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average Maximum
```

### Get metric data (multiple metrics)
```bash
aws cloudwatch get-metric-data \
  --metric-data-queries '[
    {
      "Id": "cpu",
      "MetricStat": {
        "Metric": {
          "Namespace": "AWS/EC2",
          "MetricName": "CPUUtilization",
          "Dimensions": [{"Name": "InstanceId", "Value": "<instance-id>"}]
        },
        "Period": 300,
        "Stat": "Average"
      }
    }
  ]' \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z
```

### Common EKS/Container metrics
```bash
# Node CPU
aws cloudwatch get-metric-statistics \
  --namespace ContainerInsights \
  --metric-name node_cpu_utilization \
  --dimensions Name=ClusterName,Value=<cluster> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average

# Pod memory
aws cloudwatch get-metric-statistics \
  --namespace ContainerInsights \
  --metric-name pod_memory_utilization \
  --dimensions Name=ClusterName,Value=<cluster> Name=PodName,Value=<pod> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average Maximum
```

## Load Balancers

### List load balancers
```bash
# ALB/NLB (v2)
aws elbv2 describe-load-balancers
aws elbv2 describe-load-balancers --query 'LoadBalancers[].{Name:LoadBalancerName,DNS:DNSName,State:State.Code}'

# Classic ELB
aws elb describe-load-balancers
```

### Target groups
```bash
aws elbv2 describe-target-groups
aws elbv2 describe-target-groups --load-balancer-arn <lb-arn>
```

### Target health
```bash
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

### Listeners
```bash
aws elbv2 describe-listeners --load-balancer-arn <lb-arn>
```

## S3 (Read-Only)

### List buckets
```bash
aws s3api list-buckets
aws s3 ls
```

### List objects
```bash
aws s3api list-objects-v2 --bucket <bucket> --prefix <prefix>
aws s3 ls s3://<bucket>/<prefix>/
```

### Get object (download to stdout)
```bash
aws s3 cp s3://<bucket>/<key> -
```

### Object metadata
```bash
aws s3api head-object --bucket <bucket> --key <key>
```

## VPC and Networking

### VPCs
```bash
aws ec2 describe-vpcs
aws ec2 describe-vpcs --vpc-ids <vpc-id>
```

### Subnets
```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
```

### Security groups
```bash
aws ec2 describe-security-groups --group-ids <sg-id>
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<vpc-id>"
```

### Network interfaces
```bash
aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=<vpc-id>"
```


## RDS Investigation

### List DB instances
```bash
aws rds describe-db-instances
aws rds describe-db-instances --db-instance-identifier <instance-id>
```

### DB instance status
```bash
# Status and endpoint
aws rds describe-db-instances --db-instance-identifier <instance-id> \
  --query 'DBInstances[].{ID:DBInstanceIdentifier,Status:DBInstanceStatus,Endpoint:Endpoint.Address,Port:Endpoint.Port}'
```

### DB clusters (Aurora)
```bash
aws rds describe-db-clusters
aws rds describe-db-clusters --db-cluster-identifier <cluster-id>
```

### DB events (recent issues)
```bash
# Last 24 hours
aws rds describe-events --duration 1440

# For specific instance
aws rds describe-events --source-identifier <instance-id> --source-type db-instance
```

### DB logs
```bash
# List log files
aws rds describe-db-log-files --db-instance-identifier <instance-id>

# Download log
aws rds download-db-log-file-portion \
  --db-instance-identifier <instance-id> \
  --log-file-name <log-file-name>
```

### Performance Insights
```bash
# Get resource metrics
aws pi get-resource-metrics \
  --service-type RDS \
  --identifier db-<resource-id> \
  --metric-queries '[{"Metric":"db.load.avg"}]' \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period-in-seconds 60
```

### DB subnet groups
```bash
aws rds describe-db-subnet-groups
```

### DB parameter groups
```bash
aws rds describe-db-parameter-groups
aws rds describe-db-parameters --db-parameter-group-name <group-name>
```

## Lambda Investigation

### List functions
```bash
aws lambda list-functions
aws lambda get-function --function-name <function-name>
```

### Function configuration
```bash
aws lambda get-function-configuration --function-name <function-name>
```

### Invocation metrics
```bash
# Recent invocations via CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=<function-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# Errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=<function-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# Duration (cold starts show as high duration)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=<function-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average Maximum
```

### Function logs
```bash
# Log group is /aws/lambda/<function-name>
aws logs filter-log-events \
  --log-group-name /aws/lambda/<function-name> \
  --filter-pattern "ERROR"
```

## SQS Investigation

### List queues
```bash
aws sqs list-queues
```

### Queue attributes
```bash
aws sqs get-queue-attributes \
  --queue-url <queue-url> \
  --attribute-names All
```

### Queue depth (messages available)
```bash
aws sqs get-queue-attributes \
  --queue-url <queue-url> \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible
```

### Dead letter queue check
```bash
# Check redrive policy
aws sqs get-queue-attributes \
  --queue-url <queue-url> \
  --attribute-names RedrivePolicy
```

## SNS Investigation

### List topics
```bash
aws sns list-topics
```

### Topic attributes
```bash
aws sns get-topic-attributes --topic-arn <topic-arn>
```

### Subscriptions
```bash
aws sns list-subscriptions-by-topic --topic-arn <topic-arn>
```
---

**Important**: This skill only covers read operations. Mutating operations (create, delete, modify, update) should be blocked by a safety hook in production agent environments.
