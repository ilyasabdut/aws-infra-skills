## ADDED Requirements

### Requirement: EKS Cluster Investigation

The agent MUST be able to inspect EKS cluster status and configuration.

#### Scenario: List EKS clusters
- **WHEN** agent needs to see available clusters
- **THEN** agent runs `aws eks list-clusters` and receives cluster names

#### Scenario: Get cluster details
- **WHEN** agent needs cluster configuration
- **THEN** agent runs `aws eks describe-cluster --name <cluster>` and receives endpoint, version, status, VPC config

#### Scenario: List nodegroups
- **WHEN** agent needs to see nodegroups
- **THEN** agent runs `aws eks list-nodegroups --cluster-name <cluster>` and receives nodegroup names

#### Scenario: Get nodegroup details
- **WHEN** agent needs nodegroup configuration
- **THEN** agent runs `aws eks describe-nodegroup --cluster-name <cluster> --nodegroup-name <name>` and receives instance types, scaling config, status

---

### Requirement: EC2 Instance Investigation

The agent MUST be able to inspect EC2 instances backing the cluster.

#### Scenario: List instances by tag
- **WHEN** agent needs to see cluster nodes
- **THEN** agent runs `aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/<cluster>,Values=owned"` and receives instance IDs, types, states

#### Scenario: Get instance details
- **WHEN** agent needs specific instance information
- **THEN** agent runs `aws ec2 describe-instances --instance-ids <id>` and receives full instance metadata

#### Scenario: Check instance status
- **WHEN** agent needs instance health checks
- **THEN** agent runs `aws ec2 describe-instance-status --instance-ids <id>` and receives system/instance status checks

---

### Requirement: CloudWatch Logs Investigation

The agent MUST be able to read CloudWatch logs for EKS and applications.

#### Scenario: List log groups
- **WHEN** agent needs to find log groups
- **THEN** agent runs `aws logs describe-log-groups --log-group-name-prefix <prefix>` and receives log group names

#### Scenario: List log streams
- **WHEN** agent needs to find log streams
- **THEN** agent runs `aws logs describe-log-streams --log-group-name <group> --order-by LastEventTime --descending` and receives stream names

#### Scenario: Get log events
- **WHEN** agent needs to read logs
- **THEN** agent runs `aws logs get-log-events --log-group-name <group> --log-stream-name <stream>` and receives log messages

#### Scenario: Filter logs
- **WHEN** agent needs to search logs
- **THEN** agent runs `aws logs filter-log-events --log-group-name <group> --filter-pattern <pattern>` and receives matching events

---

### Requirement: CloudWatch Metrics Investigation

The agent MUST be able to query CloudWatch metrics for resource utilization.

#### Scenario: List available metrics
- **WHEN** agent needs to discover metrics
- **THEN** agent runs `aws cloudwatch list-metrics --namespace <namespace>` and receives metric names and dimensions

#### Scenario: Get metric statistics
- **WHEN** agent needs historical metric data
- **THEN** agent runs `aws cloudwatch get-metric-statistics --namespace <ns> --metric-name <metric> --start-time <t1> --end-time <t2> --period <p> --statistics Average` and receives datapoints

#### Scenario: Get metric data (multiple metrics)
- **WHEN** agent needs multiple metrics at once
- **THEN** agent runs `aws cloudwatch get-metric-data --metric-data-queries <queries>` and receives combined metric results

---

### Requirement: Load Balancer Investigation

The agent MUST be able to inspect load balancers associated with services.

#### Scenario: List load balancers
- **WHEN** agent needs to see load balancers
- **THEN** agent runs `aws elbv2 describe-load-balancers` and receives LB names, DNS names, states

#### Scenario: Get target group health
- **WHEN** agent needs to check backend health
- **THEN** agent runs `aws elbv2 describe-target-health --target-group-arn <arn>` and receives target health status

---

### Requirement: S3 Investigation (Read-Only)

The agent MUST be able to list and read S3 objects for configuration/logs stored there.

#### Scenario: List buckets
- **WHEN** agent needs to see available buckets
- **THEN** agent runs `aws s3api list-buckets` and receives bucket names

#### Scenario: List objects
- **WHEN** agent needs to see bucket contents
- **THEN** agent runs `aws s3api list-objects-v2 --bucket <bucket> --prefix <prefix>` and receives object keys

#### Scenario: Get object (read)
- **WHEN** agent needs to read an object
- **THEN** agent runs `aws s3 cp s3://<bucket>/<key> -` and receives object contents to stdout
---

## UPDATED Requirements

*Updated 2026-09-23 — v1.23.25*

---

### Requirement: ECR Investigation (Read-Only)

The agent MUST be able to inspect ECR repositories and images.

#### Scenario: List repositories
- **WHEN** agent needs to see container registries
- **THEN** agent runs `aws ecr describe-repositories` and receives repository names, URIs, and ARNs

#### Scenario: List images in a repository
- **WHEN** agent needs to see available images
- **THEN** agent runs `aws ecr list-images --repository-name <name>` and receives image tags and digests

#### Scenario: Describe images
- **WHEN** agent needs image metadata (pushed date, size, scan findings)
- **THEN** agent runs `aws ecr describe-images --repository-name <name>` and receives full image details

#### Scenario: Get authorization token (read-only pull)
- **WHEN** agent needs to pull an image for inspection
- **THEN** agent runs `aws ecr get-authorization-token` and receives a temporary read token

#### Scenario: Block ECR write operations
- **WHEN** agent runs `aws ecr delete-repository|put-image|create-repository`
- **THEN** command is blocked (covered by mutation verb patterns: delete-, put-, create-)
