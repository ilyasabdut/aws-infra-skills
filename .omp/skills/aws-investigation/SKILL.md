---
name: aws-investigation
description: Read-only AWS investigation patterns for EKS, EC2, CloudWatch, and infrastructure diagnosis
triggers:
  - aws
  - eks
  - ec2
  - cloudwatch
  - logs
  - metrics
  - load balancer
  - alb
  - nlb
  - s3
  - nodegroup
---

# AWS Investigation Skill

Read-only AWS CLI patterns for infrastructure investigation. All commands are non-destructive.

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

## RDS (if applicable)

### List instances
```bash
aws rds describe-db-instances
aws rds describe-db-clusters  # Aurora
```

### Instance details
```bash
aws rds describe-db-instances --db-instance-identifier <id>
```

## VPC and Networking

### Describe VPCs
```bash
aws ec2 describe-vpcs
```

### Subnets
```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
```

### Security groups
```bash
aws ec2 describe-security-groups --group-ids <sg-id>
```

### Network interfaces
```bash
aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=<vpc-id>"
```

---

**Note**: This skill only covers read operations. Mutating operations (create, delete, modify, update) are blocked by the safety hook.
