# Integration Status

Last updated: 2026-09-23 | Version: v1.23.25

## Core Services (Fully Tested)

| Service | Read Operations | Write Operations | Status |
|---------|-----------------|------------------|--------|
| **EC2** | `describe-*`, `get-*` | `terminate-`, `run-`, `modify-`, `create-`, `start-`, `stop-`, `reboot-` | ✅ Complete |
| **EKS** | `describe-*`, `list-*` | `create-`, `delete-`, `update-` | ✅ Complete |
| **ECR** | `describe-*`, `list-*`, `get-*` | `delete-`, `put-`, `create-` | ✅ Complete |
| **Kubernetes** | `get`, `describe`, `logs`, `top`, `events` | `apply`, `delete`, `exec`, `scale`, `edit`, `patch`, `drain`, `cordon` | ✅ Complete |

## Service Blocks

| Service | Block Type | Reason |
|---------|------------|--------|
| IAM | Full service | Privilege escalation risk |
| Organizations | Full service | Account-level changes |
| STS assume-role | Specific operation | Credential escalation |

## Mutation Verb Patterns (153 total)

Blocks any `aws <service> <verb>` where verb matches:

- **CRUD**: `delete-`, `create-`, `put-`, `remove-`, `update-`, `modify-`
- **Lifecycle**: `terminate-`, `start-`, `stop-`, `reboot-`, `enable-`, `disable-`, `suspend-`, `resume-`
- **Attachment**: `attach-`, `detach-`, `register-`, `deregister-`, `associate-`, `disassociate-`
- **Security**: `authorize-`, `revoke-`
- **Resource**: `import-`, `copy-`, `allocate-`, `release-`, `cancel-`
- **Approval**: `accept-`, `reject-`
- **Tagging**: `tag-resource`, `untag-resource`
- **Messaging**: `send-`, `invoke`, `publish`, `send-command`
- **Compute**: `run-`
- **Execution**: `execute-`
- **Configuration**: `set-`, `reset-`, `change-`
- **Recovery**: `restore-`, `failover-`, `promote-`, `revert-`
- **Batch**: `batch-write-`, `batch-delete-`, `batch-put-`, `batch-associate-`, `batch-disassociate-`, `batch-update-`, `batch-import-`, `batch-stop-`
- **Data**: `write-`, `move-`, `replace-`
- **Purchase**: `request-`, `purchase-`
- **Assignment**: `assign-`, `unassign-`
- **Workflow**: `submit-`, `apply-`, `bundle-`, `confirm-`, `complete-`, `abort-`, `continue-`
- **Migration**: `switchover-`, `migrate-`, `export-`, `clone-`
- **Locking**: `lock-`, `unlock-`
- **Networking**: `provision-`, `deprovision-`, `advertise-`, `withdraw-`
- **Credentials**: `rotate-`, `renew-`
- **Scaling**: `scale-`
- **Monitoring**: `monitor-`, `unmonitor-`
- **Cache**: `purge-`, `flush-`, `invalidate-`
- **Build**: `rebuild-`, `compose-`
- **Merge**: `merge-`, `swap-`, `split-`
- **Retry**: `retry-`, `trigger-`
- **Override**: `override-`, `post-`, `resend-`
- **Memory**: `forget-`, `global-`
- **Control**: `pause-`, `signal-`
- **Cognito Admin**: `admin-delete-`, `admin-disable-`, `admin-enable-`, `admin-reset-`, `admin-set-`, `admin-update-`, `admin-create-`, `admin-confirm-`, `admin-forget-`, `admin-initiate-`, `admin-respond-`, `admin-link-`, `admin-add-`, `admin-remove-`
- **Upload**: `upload-`
- **Deprecation**: `deprecate-`, `undeprecate-`
- **Delivery**: `dispose-`, `deliver-`, `reserve-`
- **Approval**: `decline-`
- **Deploy**: `deploy-`
- **Access**: `grant-`
- **Grouping**: `group-`, `ungroup-`
- **Issue**: `issue-`
- **Peering**: `peer-`, `unpeer-`
- **Resolution**: `resolve-`, `notify-`
- **Connection**: `connect-`, `transfer-`
- **Expiration**: `expire-`
- **Indexing**: `index-`, `archive-`
- **Checkout**: `checkin-`, `checkout-`
- **Config**: `configure-`
- **Launch**: `launch-`
- **Upgrade**: `upgrade-`
- **Activate**: `activate-`, `deactivate-`
- **Record**: `record-`
- **Respond**: `respond-`
- **Sync**: `sync-`
- **Claim**: `claim-`
- **Hibernate**: `hibernate-`
- **Reopen**: `reopen-`
- **Verify**: `verify-`
- **Acknowledge**: `acknowledge-`
- **Initialize**: `initialize-`
- **Subscribe**: `subscribe`, `unsubscribe` (bare verbs)
- **Vote**: `vote-`
- **Other**: `add-`, `write-`

## Exceptions (Read-only despite prefix)

| Pattern | Service | Reason |
|---------|---------|--------|
| `aws logs start-query` | CloudWatch Logs | Logs Insights query is read-only |
| `aws logs stop-query` | CloudWatch Logs | Logs Insights query is read-only |
| `aws logs get-query-results` | CloudWatch Logs | Logs Insights query is read-only |

## Not Yet Integrated

These services have skills/documentation but no service-specific hook logic:

- CloudWatch (relies on verb patterns)
- S3 (partial - rm/upload blocked, other mutations via patterns)
- RDS, Lambda, SQS, SNS, Route53
- Secrets Manager, SSM, ECS, DynamoDB, API Gateway
- ElastiCache, Step Functions, EventBridge, CloudFront, WAF
- Kinesis, CodeBuild, CodePipeline, Auto Scaling, ACM
- Cognito, OpenSearch, Redshift, Athena, CloudTrail
- EFS, Service Quotas, Cost Explorer, Glue, EMR
- Backup, Security Hub, GuardDuty, Inspector, Config, X-Ray

These are covered by the 153 mutation verb patterns but don't have:
- Service-specific error messages
- Service-specific read operation documentation
- Dedicated test cases

## Test Coverage

- **Hook tests**: 61 tests (all pass)
- **Core services**: 28 manual tests (EC2: 6, EKS: 6, ECR: 6, K8s: 10)
