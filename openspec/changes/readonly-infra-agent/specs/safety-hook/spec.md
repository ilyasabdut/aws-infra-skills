## ADDED Requirements

### Requirement: kubectl Command Filtering

The hook MUST allow only read-only kubectl subcommands.

#### Scenario: Allow read operations
- **WHEN** agent runs `kubectl get|describe|logs|top|api-resources|api-versions|cluster-info|version`
- **THEN** command executes normally

#### Scenario: Block write operations
- **WHEN** agent runs `kubectl apply|create|delete|patch|edit|replace|scale|rollout|run|expose|set`
- **THEN** command is blocked with message: "Blocked: kubectl <subcommand> is a write operation"

#### Scenario: Block exec
- **WHEN** agent runs `kubectl exec`
- **THEN** command is blocked with message: "Blocked: kubectl exec allows arbitrary code execution"

#### Scenario: Block dangerous operations
- **WHEN** agent runs `kubectl cp|port-forward|attach|debug|drain|cordon|uncordon|taint|label|annotate`
- **THEN** command is blocked with message explaining why

---

### Requirement: AWS CLI Command Filtering

The hook MUST block mutating AWS CLI operations.

#### Scenario: Allow read operations
- **WHEN** agent runs `aws <service> describe-*|list-*|get-*`
- **THEN** command executes normally

#### Scenario: Block delete operations
- **WHEN** agent runs `aws <service> delete-*`
- **THEN** command is blocked with message: "Blocked: delete operations are not allowed"

#### Scenario: Block create operations
- **WHEN** agent runs `aws <service> create-*`
- **THEN** command is blocked with message: "Blocked: create operations are not allowed"

#### Scenario: Block modify/update operations
- **WHEN** agent runs `aws <service> modify-*|update-*|put-*`
- **THEN** command is blocked with message: "Blocked: modify operations are not allowed"

#### Scenario: Block IAM entirely
- **WHEN** agent runs `aws iam *`
- **THEN** command is blocked with message: "Blocked: IAM operations are not allowed"

#### Scenario: Block S3 write operations
- **WHEN** agent runs `aws s3 rm|mv` or `aws s3 cp <local> s3://` or `aws s3 sync <local> s3://`
- **THEN** command is blocked with message: "Blocked: S3 write operations are not allowed"

#### Scenario: Allow S3 read operations
- **WHEN** agent runs `aws s3 cp s3://<bucket>/<key> -` or `aws s3 ls`
- **THEN** command executes normally

---

### Requirement: Credential Protection

The hook MUST prevent credential extraction.

#### Scenario: Block env inspection
- **WHEN** agent runs `env|printenv|export` without arguments
- **THEN** command is blocked with message: "Blocked: environment inspection not allowed"

#### Scenario: Block proc environ
- **WHEN** agent runs any command accessing `/proc/*/environ`
- **THEN** command is blocked with message: "Blocked: credential inspection not allowed"

#### Scenario: Allow specific env var check
- **WHEN** agent runs `echo $AWS_DEFAULT_REGION` or similar non-secret vars
- **THEN** command executes normally

---

### Requirement: Bypass Prevention

The hook MUST prevent common bypass attempts.

#### Scenario: Block Python with boto3
- **WHEN** agent runs `python -c "import boto3"` or similar
- **THEN** command is blocked with message: "Blocked: direct SDK access not allowed, use aws cli"

#### Scenario: Block direct API calls
- **WHEN** agent runs `curl` to AWS API endpoints (*.amazonaws.com)
- **THEN** command is blocked with message: "Blocked: direct API access not allowed, use aws cli"

---

### Requirement: Block Message Quality

The hook MUST provide helpful block messages.

#### Scenario: Suggest alternative
- **WHEN** a command is blocked
- **THEN** the message includes what the agent should do instead when applicable

#### Scenario: Example alternative
- **WHEN** agent runs `kubectl delete pod x`
- **THEN** message is: "Blocked: kubectl delete is a write operation. To investigate the pod, use: kubectl describe pod x -n <namespace>"
