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
---

## UPDATED Requirements

*Updated 2026-09-23 — v1.23.25 (153 mutation verb patterns)*

---

### Requirement: EC2 Service Coverage

#### Scenario: Allow EC2 read operations
- **WHEN** agent runs `aws ec2 describe-instances|describe-volumes|describe-security-groups|describe-subnets|describe-vpcs|describe-network-interfaces|describe-instance-status`
- **THEN** command executes normally

#### Scenario: Block EC2 write operations
- **WHEN** agent runs `aws ec2 terminate-instances|run-instances|modify-instance-attribute|start-instances|stop-instances|reboot-instances|create-*|delete-*`
- **THEN** command is blocked with message: "Blocked: aws ec2 mutation operation is not permitted. Read-only: describe-*, list-*, get-*"

---

### Requirement: EKS Service Coverage

#### Scenario: Allow EKS read operations
- **WHEN** agent runs `aws eks describe-cluster|list-clusters|describe-nodegroup|list-nodegroups|describe-addon|list-addons|describe-update|list-updates`
- **THEN** command executes normally

#### Scenario: Block EKS write operations
- **WHEN** agent runs `aws eks create-cluster|delete-cluster|update-cluster-config|update-nodegroup-config|create-nodegroup|delete-nodegroup`
- **THEN** command is blocked with message: "Blocked: aws eks mutation operation is not permitted. Read-only: describe-*, list-*, get-*"

---

### Requirement: ECR Service Coverage

#### Scenario: Allow ECR read operations
- **WHEN** agent runs `aws ecr describe-repositories|list-images|get-authorization-token|describe-images|get-download-url-for-layer|batch-get-image`
- **THEN** command executes normally

#### Scenario: Block ECR write operations
- **WHEN** agent runs `aws ecr delete-repository|put-image|create-repository|delete-lifecycle-policy|set-repository-policy`
- **THEN** command is blocked with message: "Blocked: aws ecr mutation operation is not permitted. Read-only: describe-*, list-*, get-*"

---

### Requirement: Extended Mutation Verb Blocking (153 patterns)

The hook MUST block any `aws <service> <verb>` where verb matches one of 153 patterns. Original patterns (delete-, create-, put-, modify-, update-, remove-, terminate-, start-, stop-, etc.) remain. The following categories were added post-initial-spec:

#### Scenario: Block admin-prefixed Cognito mutations
- **WHEN** agent runs `aws cognito-idp admin-delete-user|admin-disable-user|admin-enable-user|admin-reset-user-password|admin-set-user-password|admin-update-user-attributes|admin-create-user|admin-confirm-sign-up|admin-forget-device|admin-initiate-auth|admin-respond-to-auth-challenge|admin-link-provider-for-user|admin-add-user-to-group|admin-remove-user-from-group`
- **THEN** command is blocked

#### Scenario: Block checkout/checkin operations
- **WHEN** agent runs `aws codecommit checkout-*` or `aws workdocs checkin-*|checkout-*`
- **THEN** command is blocked

#### Scenario: Block configure operations
- **WHEN** agent runs `aws mediatailor configure-*` or similar
- **THEN** command is blocked

#### Scenario: Block launch operations
- **WHEN** agent runs `aws appstream launch-*` or similar
- **THEN** command is blocked

#### Scenario: Block upgrade operations
- **WHEN** agent runs `aws clouddirectory upgrade-*` or similar
- **THEN** command is blocked

#### Scenario: Block activate/deactivate operations
- **WHEN** agent runs `aws workdocs activate-user|deactivate-user` or similar
- **THEN** command is blocked

#### Scenario: Block batch-stop operations
- **WHEN** agent runs `aws glue batch-stop-job-run` or similar
- **THEN** command is blocked

#### Scenario: Block record/respond/sync operations
- **WHEN** agent runs `aws swf record-activity-task-heartbeat|respond-activity-task-completed` or `aws robomaker sync-deployment-job`
- **THEN** command is blocked

#### Scenario: Block claim operations
- **WHEN** agent runs `aws gamelift claim-game-server`
- **THEN** command is blocked

#### Scenario: Block hibernate operations
- **WHEN** agent runs `aws ec2 hibernate-instance`
- **THEN** command is blocked

#### Scenario: Block reopen operations
- **WHEN** agent runs `aws support reopen-case`
- **THEN** command is blocked

#### Scenario: Block verify operations
- **WHEN** agent runs `aws ses verify-email-identity` or similar
- **THEN** command is blocked

#### Scenario: Block acknowledge operations
- **WHEN** agent runs `aws ssm-contacts acknowledge-page`
- **THEN** command is blocked

#### Scenario: Block initialize operations
- **WHEN** agent runs `aws cloudhsmv2 initialize-cluster`
- **THEN** command is blocked

#### Scenario: Block subscribe/unsubscribe operations (bare verbs)
- **WHEN** agent runs `aws codestar-notifications subscribe` or `aws codestar-notifications unsubscribe`
- **THEN** command is blocked (note: these are bare verbs without trailing hyphen)

#### Scenario: Block vote operations
- **WHEN** agent runs `aws managedblockchain vote-on-proposal`
- **THEN** command is blocked

---

### Requirement: Exception — CloudWatch Logs Insights

#### Scenario: Allow Logs Insights despite start- prefix
- **WHEN** agent runs `aws logs start-query|stop-query|get-query-results`
- **THEN** command executes normally (these are read-only query operations)

---

### Requirement: STS Privilege Escalation Block

#### Scenario: Block assume-role
- **WHEN** agent runs `aws sts assume-role`
- **THEN** command is blocked with message: "Blocked: aws sts assume-role is not permitted (prevents privilege escalation)"
