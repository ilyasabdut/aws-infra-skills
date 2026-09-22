---
name: AWS Investigation
description: Read-only AWS CLI patterns for investigating EKS, EC2, CloudWatch, S3, RDS, Lambda, SQS, SNS, VPC, Route53, Secrets Manager, SSM, ECS, DynamoDB, API Gateway, ElastiCache, Step Functions, EventBridge, CloudFront, WAF, Kinesis, CodeBuild, CodePipeline, Auto Scaling, ACM, Cognito, OpenSearch, Redshift, and Athena.
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
- RDS database health, events, and logs
- Lambda function errors, cold starts, and invocations
- SQS queue depth and dead letter queues
- SNS topics and subscriptions
- VPC networking and security groups
- Route53 hosted zones and health checks
- Secrets Manager secret metadata and rotation status
- SSM Parameter Store parameters
- ECS clusters, services, and tasks
- DynamoDB tables and capacity metrics
- API Gateway REST/HTTP APIs and errors
- ElastiCache (Redis/Memcached) clusters and metrics
- Step Functions executions and state machines
- EventBridge rules and failed invocations
- CloudFront distributions and cache invalidations
- WAF web ACLs and blocked requests
- Kinesis streams and throughput metrics
- CodeBuild projects and build logs
- CodePipeline executions and stage status
- Auto Scaling groups and scaling activities
- ACM certificates and validation status
- Cognito user pools and identity pools
- OpenSearch domains and cluster health
- Redshift clusters and query logs
- Athena workgroups and query executions

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

## Route53 Investigation

### List hosted zones
```bash
aws route53 list-hosted-zones
```

### List records in zone
```bash
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>
```

### Health checks
```bash
aws route53 list-health-checks
aws route53 get-health-check-status --health-check-id <health-check-id>
```

### Query DNS resolution (test)
```bash
aws route53 test-dns-answer \
  --hosted-zone-id <zone-id> \
  --record-name <domain> \
  --record-type A
```

## Secrets Manager Investigation

### List secrets
```bash
aws secretsmanager list-secrets
```

### Secret metadata (not the value)
```bash
aws secretsmanager describe-secret --secret-id <secret-name>
```

### Rotation status
```bash
aws secretsmanager describe-secret --secret-id <secret-name> \
  --query '{Name:Name,RotationEnabled:RotationEnabled,LastRotated:LastRotatedDate}'
```

## SSM Parameter Store Investigation

### List parameters
```bash
aws ssm describe-parameters
aws ssm describe-parameters --parameter-filters "Key=Name,Values=<prefix>"
```

### Parameter metadata
```bash
aws ssm describe-parameters --parameter-filters "Key=Name,Values=<param-name>"
```

## ECS Investigation

### List clusters
```bash
aws ecs list-clusters
aws ecs describe-clusters --clusters <cluster-name>
```

### List services
```bash
aws ecs list-services --cluster <cluster-name>
aws ecs describe-services --cluster <cluster-name> --services <service-name>
```

### List tasks
```bash
aws ecs list-tasks --cluster <cluster-name>
aws ecs list-tasks --cluster <cluster-name> --service-name <service-name>
aws ecs describe-tasks --cluster <cluster-name> --tasks <task-id>
```

### Task definition
```bash
aws ecs describe-task-definition --task-definition <task-def>
```

### Container insights (if enabled)
```bash
aws logs filter-log-events \
  --log-group-name /aws/ecs/containerinsights/<cluster>/performance \
  --limit 50
```

## DynamoDB Investigation

### List tables
```bash
aws dynamodb list-tables
aws dynamodb describe-table --table-name <table-name>
```

### Table metrics (capacity, throttling)
```bash
# Read/write capacity consumed
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=<table-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum

# Throttled requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ThrottledRequests \
  --dimensions Name=TableName,Value=<table-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum
```

### Global secondary indexes
```bash
aws dynamodb describe-table --table-name <table-name> \
  --query 'Table.GlobalSecondaryIndexes'
```

## API Gateway Investigation

### List REST APIs
```bash
aws apigateway get-rest-apis
aws apigateway get-rest-api --rest-api-id <api-id>
```

### List HTTP APIs (API Gateway v2)
```bash
aws apigatewayv2 get-apis
aws apigatewayv2 get-api --api-id <api-id>
```

### Stages and deployments
```bash
aws apigateway get-stages --rest-api-id <api-id>
aws apigateway get-deployments --rest-api-id <api-id>
```

### API Gateway metrics
```bash
# 4XX/5XX errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name 5XXError \
  --dimensions Name=ApiName,Value=<api-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum

# Latency
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name Latency \
  --dimensions Name=ApiName,Value=<api-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Average
```

## ElastiCache Investigation

### List clusters
```bash
# Redis
aws elasticache describe-replication-groups
aws elasticache describe-replication-groups --replication-group-id <group-id>

# Memcached
aws elasticache describe-cache-clusters
aws elasticache describe-cache-clusters --cache-cluster-id <cluster-id>
```

### Node status
```bash
aws elasticache describe-cache-clusters --cache-cluster-id <cluster-id> --show-cache-node-info
```

### ElastiCache metrics
```bash
# CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name CPUUtilization \
  --dimensions Name=CacheClusterId,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Average

# Memory usage (Redis)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name DatabaseMemoryUsagePercentage \
  --dimensions Name=CacheClusterId,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Average

# Evictions
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name Evictions \
  --dimensions Name=CacheClusterId,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum
```

## Step Functions Investigation

### List state machines
```bash
aws stepfunctions list-state-machines
aws stepfunctions describe-state-machine --state-machine-arn <arn>
```

### List executions
```bash
# Recent executions
aws stepfunctions list-executions --state-machine-arn <arn> --max-results 20

# Failed executions
aws stepfunctions list-executions --state-machine-arn <arn> --status-filter FAILED

# Running executions
aws stepfunctions list-executions --state-machine-arn <arn> --status-filter RUNNING
```

### Execution details
```bash
aws stepfunctions describe-execution --execution-arn <execution-arn>
aws stepfunctions get-execution-history --execution-arn <execution-arn>
```

## EventBridge Investigation

### List event buses
```bash
aws events list-event-buses
aws events describe-event-bus --name <bus-name>
```

### List rules
```bash
aws events list-rules
aws events list-rules --event-bus-name <bus-name>
aws events describe-rule --name <rule-name>
```

### Rule targets
```bash
aws events list-targets-by-rule --rule <rule-name>
```

### Failed invocations (via CloudWatch)
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/Events \
  --metric-name FailedInvocations \
  --dimensions Name=RuleName,Value=<rule-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum
```

## CloudFront Investigation

### List distributions
```bash
aws cloudfront list-distributions
aws cloudfront get-distribution --id <distribution-id>
```

### Distribution config
```bash
aws cloudfront get-distribution-config --id <distribution-id>
```

### Cache invalidations
```bash
aws cloudfront list-invalidations --distribution-id <distribution-id>
aws cloudfront get-invalidation --distribution-id <distribution-id> --id <invalidation-id>
```

### CloudFront metrics
```bash
# Request count
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=<distribution-id> Name=Region,Value=Global \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum

# Error rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name 5xxErrorRate \
  --dimensions Name=DistributionId,Value=<distribution-id> Name=Region,Value=Global \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Average
```

## WAF Investigation

### List web ACLs
```bash
# Regional (ALB, API Gateway)
aws wafv2 list-web-acls --scope REGIONAL --region <region>

# CloudFront (global)
aws wafv2 list-web-acls --scope CLOUDFRONT --region us-east-1
```

### Web ACL details
```bash
aws wafv2 get-web-acl --name <name> --scope REGIONAL --id <id> --region <region>
```

### Sampled requests (blocked/allowed)
```bash
aws wafv2 get-sampled-requests \
  --web-acl-arn <web-acl-arn> \
  --rule-metric-name <rule-metric> \
  --scope REGIONAL \
  --time-window StartTime=$(date -u -v-3H +%Y-%m-%dT%H:%M:%SZ),EndTime=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --max-items 100
```

### WAF metrics
```bash
# Blocked requests
aws cloudwatch get-metric-statistics \
  --namespace AWS/WAFV2 \
  --metric-name BlockedRequests \
  --dimensions Name=WebACL,Value=<web-acl-name> Name=Region,Value=<region> Name=Rule,Value=ALL \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum
```

## Kinesis Investigation

### List streams
```bash
# Kinesis Data Streams
aws kinesis list-streams
aws kinesis describe-stream --stream-name <stream-name>
aws kinesis describe-stream-summary --stream-name <stream-name>

# Kinesis Firehose
aws firehose list-delivery-streams
aws firehose describe-delivery-stream --delivery-stream-name <stream-name>
```

### Shard iterator and records (read sample)
```bash
# Get shard iterator
aws kinesis get-shard-iterator \
  --stream-name <stream-name> \
  --shard-id <shard-id> \
  --shard-iterator-type LATEST

# Note: get-records requires the iterator from above
```

### Kinesis metrics
```bash
# Incoming records
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name IncomingRecords \
  --dimensions Name=StreamName,Value=<stream-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum

# Read/write throughput exceeded
aws cloudwatch get-metric-statistics \
  --namespace AWS/Kinesis \
  --metric-name ReadProvisionedThroughputExceeded \
  --dimensions Name=StreamName,Value=<stream-name> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Sum
```

## CodeBuild Investigation

### List projects
```bash
aws codebuild list-projects
aws codebuild batch-get-projects --names <project-name>
```

### List builds
```bash
# Recent builds for a project
aws codebuild list-builds-for-project --project-name <project-name> --sort-order DESCENDING

# Build details
aws codebuild batch-get-builds --ids <build-id>
```

### Build logs
```bash
# Get log group from build details, then:
aws logs filter-log-events \
  --log-group-name /aws/codebuild/<project-name> \
  --limit 100
```

## CodePipeline Investigation

### List pipelines
```bash
aws codepipeline list-pipelines
aws codepipeline get-pipeline --name <pipeline-name>
```

### Pipeline state
```bash
aws codepipeline get-pipeline-state --name <pipeline-name>
```

### Pipeline executions
```bash
aws codepipeline list-pipeline-executions --pipeline-name <pipeline-name> --max-results 10
aws codepipeline get-pipeline-execution \
  --pipeline-name <pipeline-name> \
  --pipeline-execution-id <execution-id>
```

### Action execution details
```bash
aws codepipeline list-action-executions \
  --pipeline-name <pipeline-name> \
  --filter pipelineExecutionId=<execution-id>
```

## Auto Scaling Investigation

### Auto Scaling Groups
```bash
aws autoscaling describe-auto-scaling-groups
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg-name>
```

### Scaling activities
```bash
aws autoscaling describe-scaling-activities --auto-scaling-group-name <asg-name> --max-records 20
```

### Scaling policies
```bash
aws autoscaling describe-policies --auto-scaling-group-name <asg-name>
```

### Scheduled actions
```bash
aws autoscaling describe-scheduled-actions --auto-scaling-group-name <asg-name>
```

### Instance health
```bash
aws autoscaling describe-auto-scaling-instances
```

## ACM (Certificate Manager) Investigation

### List certificates
```bash
aws acm list-certificates
aws acm list-certificates --certificate-statuses ISSUED PENDING_VALIDATION EXPIRED
```

### Certificate details
```bash
aws acm describe-certificate --certificate-arn <cert-arn>
```

### Certificate validation status
```bash
aws acm describe-certificate --certificate-arn <cert-arn> \
  --query 'Certificate.{Status:Status,DomainValidationOptions:DomainValidationOptions}'
```

### Expiring certificates
```bash
aws acm list-certificates --certificate-statuses ISSUED \
  --query 'CertificateSummaryList[?NotAfter<=`2026-10-22`]'
```

## Cognito Investigation

### User pools
```bash
aws cognito-idp list-user-pools --max-results 20
aws cognito-idp describe-user-pool --user-pool-id <pool-id>
```

### User pool clients
```bash
aws cognito-idp list-user-pool-clients --user-pool-id <pool-id>
aws cognito-idp describe-user-pool-client --user-pool-id <pool-id> --client-id <client-id>
```

### Identity pools
```bash
aws cognito-identity list-identity-pools --max-results 20
aws cognito-identity describe-identity-pool --identity-pool-id <pool-id>
```

### User lookup (by username or email)
```bash
aws cognito-idp admin-get-user --user-pool-id <pool-id> --username <username>
aws cognito-idp list-users --user-pool-id <pool-id> --filter "email = \"user@example.com\""
```

## OpenSearch Investigation

### List domains
```bash
aws opensearch list-domain-names
aws opensearch describe-domain --domain-name <domain-name>
```

### Domain health
```bash
aws opensearch describe-domain --domain-name <domain-name> \
  --query 'DomainStatus.{Processing:Processing,ClusterHealth:ClusterConfig}'
```

### OpenSearch metrics
```bash
# Cluster health (red/yellow/green via node count)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name ClusterStatus.red \
  --dimensions Name=DomainName,Value=<domain-name> Name=ClientId,Value=<account-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Maximum

# JVM memory pressure
aws cloudwatch get-metric-statistics \
  --namespace AWS/ES \
  --metric-name JVMMemoryPressure \
  --dimensions Name=DomainName,Value=<domain-name> Name=ClientId,Value=<account-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Maximum
```

## Redshift Investigation

### List clusters
```bash
aws redshift describe-clusters
aws redshift describe-clusters --cluster-identifier <cluster-id>
```

### Cluster snapshots
```bash
aws redshift describe-cluster-snapshots --cluster-identifier <cluster-id>
```

### Recent queries (via CloudWatch Logs if enabled)
```bash
aws logs filter-log-events \
  --log-group-name /aws/redshift/<cluster-id>/useractivitylog \
  --limit 50
```

### Redshift metrics
```bash
# CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/Redshift \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterIdentifier,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Average

# Disk space used
aws cloudwatch get-metric-statistics \
  --namespace AWS/Redshift \
  --metric-name PercentageDiskSpaceUsed \
  --dimensions Name=ClusterIdentifier,Value=<cluster-id> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 --statistics Average
```

## Athena Investigation

### List workgroups
```bash
aws athena list-work-groups
aws athena get-work-group --work-group <workgroup-name>
```

### Query executions
```bash
# List recent queries
aws athena list-query-executions --work-group <workgroup-name> --max-results 20

# Query details
aws athena get-query-execution --query-execution-id <query-id>

# Failed queries
aws athena batch-get-query-execution --query-execution-ids <id1> <id2> \
  --query 'QueryExecutions[?Status.State==`FAILED`]'
```

### Query results location
```bash
aws athena get-work-group --work-group <workgroup-name> \
  --query 'WorkGroup.Configuration.ResultConfiguration.OutputLocation'
```

---

**Important**: This skill only covers read operations. Mutating operations (create, delete, modify, update) should be blocked by a safety hook in production agent environments.
