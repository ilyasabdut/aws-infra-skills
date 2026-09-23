# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.23.16] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (94 patterns total):
  - `invalidate-` (CodeBuild project cache invalidation)
  - `override-` (CodeCommit approval rule override)
  - `post-` (CodeCommit comment posting)
  - `resend-` (ACM validation email resend)
  - `split-` (Kinesis shard split)

## [1.23.15] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (89 patterns total):
  - `merge-` (CodeCommit branch/PR merges)
  - `swap-` (Elastic Beanstalk CNAME swap)
  - `compose-` (Elastic Beanstalk compose-environments)
  - `retry-` (CodePipeline retry-stage-execution)
  - `trigger-` (Glue crawler triggers)
  - `continue-` (CodeDeploy continue-deployment)

## [1.23.14] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (83 patterns total):
  - `batch-update-` (batch updates)
  - `batch-import-` (batch imports)
  - `rebuild-` (Elastic Beanstalk environment rebuild)

## [1.23.13] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (80 patterns total):
  - `batch-disassociate-` (batch resource unlinking)

## [1.23.12] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (79 patterns total):
  - `purge-` (SQS queue purging, cache purging)

## [1.23.11] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (78 patterns total):
  - `batch-associate-` (resource batch associations)

## [1.23.10] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (77 patterns total):
  - `monitor-`, `unmonitor-` (EC2 detailed monitoring)

## [1.23.9] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (75 patterns total):
  - `rotate-`, `renew-` (secret/certificate rotation)
  - `scale-` (autoscaling operations)
  - `suspend-`, `resume-` (process lifecycle)
  - `complete-`, `abort-` (lifecycle actions, multipart uploads)
  - `change-` (Route53, configuration changes)

## [1.23.8] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (67 patterns total):
  - `provision-`, `deprovision-` (IPAM/BYOIP provisioning)
  - `advertise-`, `withdraw-` (BYOIP advertisement)

## [1.23.7] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (63 patterns total):
  - `migrate-` (host migration)
  - `export-` (image/snapshot export)
  - `clone-` (RDS cluster cloning)
  - `lock-`, `unlock-` (snapshot locking)

## [1.23.6] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (58 patterns total):
  - `replace-` (route/ACL replacement)
  - `request-`, `purchase-` (spot instances, reserved instances, savings plans)
  - `assign-`, `unassign-` (IP address assignment)
  - `submit-`, `apply-` (state changes, maintenance actions)
  - `bundle-` (instance bundling)
  - `confirm-` (product confirmation)
  - `switchover-` (RDS switchover)

## [1.23.5] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs (48 patterns total):
  - `execute-` (code/SQL execution: `execute-statement`, `execute-command`)
  - `set-`, `reset-` (configuration changes: `set-bucket-policy`, `reset-db-parameter-group`)
  - `restore-`, `failover-`, `promote-`, `revert-` (recovery/DR operations)
  - `move-` (resource movement: `move-address-to-vpc`)
  - `batch-write-`, `batch-delete-`, `batch-put-` (DynamoDB batch mutations)

## [1.23.4] - 2026-09-23

### Fixed
- **safety-hook**: Comprehensive mutation verb blocking (37 patterns total):
  - `tag-resource`, `untag-resource` (tagging operations)
  - `allocate-`, `release-` (resource allocation)
  - `accept-`, `reject-` (approval workflows)
  - `cancel-` (cancellation operations)
  - `write-` (write operations)

## [1.23.3] - 2026-09-23

### Fixed
- **safety-hook**: Block additional mutation verbs that were incorrectly allowed:
  - `register-`, `associate-`, `disassociate-` (network/load balancer operations)
  - `authorize-`, `revoke-` (security group rules)
  - `import-`, `copy-` (resource operations)
  - `send-`, `invoke`, `publish` (messaging/Lambda)
  - `send-command` (SSM remote execution)

## [1.23.2] - 2026-09-23

### Fixed
- **safety-hook**: Block `add-*` mutation verbs (e.g., `aws emr add-steps`, `aws emr add-tags`) - was incorrectly allowed

## [1.23.1] - 2026-09-23

### Fixed
- **safety-hook**: Allow `aws logs start-query` (CloudWatch Logs Insights is read-only, was incorrectly blocked by `start-*` mutation verb pattern)

## [1.23.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: Config compliance investigation (rule evaluation, resource history, remediation status, recorder/delivery channel)
- **diagnostic-workflows skill**: X-Ray trace investigation (error/slow traces, service graph, sampling rules, trace filtering)

## [1.22.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: Security Hub finding triage (finding details, compliance status, related findings, workflow history)
- **diagnostic-workflows skill**: GuardDuty threat investigation (resource/actor details, IP reputation, finding types reference)
- **diagnostic-workflows skill**: Inspector vulnerability investigation (package/network findings, fix availability, remediation)

## [1.21.0] - 2026-09-23

### Added
- **aws-investigation skill**: Security Hub investigation (findings, standards, controls, insights)
- **aws-investigation skill**: GuardDuty investigation (detectors, findings, threat intel)
- **aws-investigation skill**: Inspector investigation (findings, coverage, vulnerability types)
- **aws-investigation skill**: Config investigation (configuration history, compliance by rule/resource)
- **aws-investigation skill**: X-Ray investigation (traces, error/slow filters, service graph)

## [1.20.0] - 2026-09-23

### Added
- **aws-investigation skill**: CloudWatch Logs Insights query patterns (start-query workflow, error aggregation, latency percentiles, Lambda cold starts, EKS audit logs, API Gateway latency)

## [1.19.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: Redshift cluster diagnosis (status, snapshots, parameters, disk/query metrics)
- **diagnostic-workflows skill**: Athena query failure diagnosis (execution details, workgroup config, table metadata)
- **diagnostic-workflows skill**: Glue job failure diagnosis (job runs, bookmarks, triggers, crawlers, error logs)
- **diagnostic-workflows skill**: EMR cluster/step failure diagnosis (cluster status, steps, instances, events)
- **diagnostic-workflows skill**: AWS Backup job failure diagnosis (job details, vault, plan, restore jobs)
- **diagnostic-workflows skill**: Cost Explorer anomaly investigation (cost by service/account, anomalies, savings plans)

## [1.18.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: CloudTrail event investigation (trail status, event lookup by user/resource/name, event selectors)
- **diagnostic-workflows skill**: EFS mount/performance diagnosis (file system status, mount targets, access points, throughput metrics)
- **diagnostic-workflows skill**: Service Quotas/limits diagnosis (quota lookup, request history, common quota codes)

## [1.17.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: S3 access/permission diagnosis (bucket policy, ACL, public access block, encryption, CORS)
- **diagnostic-workflows skill**: SSM parameter/command diagnosis (agent status, command invocations, parameter history)
- **diagnostic-workflows skill**: VPC connectivity diagnosis (subnets, routes, NAT, IGW, endpoints, NACLs, flow logs)

## [1.16.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: WAF blocked requests diagnosis (Web ACL, blocked/allowed metrics, sampled requests, logs)
- **diagnostic-workflows skill**: Route53 health check diagnosis (status, connection time, associated records)
- **diagnostic-workflows skill**: ACM certificate diagnosis (validation status, expiration, renewal)
- **diagnostic-workflows skill**: Secrets Manager rotation diagnosis (config, versions, Lambda logs)

## [1.15.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: ECS service/task diagnosis (service status, events, stopped tasks, task definitions)
- **diagnostic-workflows skill**: Auto Scaling group diagnosis (ASG status, scaling activities, policies, instance refresh)
- **diagnostic-workflows skill**: SNS delivery diagnosis (topic attributes, subscriptions, delivery metrics, failures)

## [1.14.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: Cognito authentication diagnosis (user pool, user status, app client, sign-in metrics)
- **diagnostic-workflows skill**: OpenSearch cluster health diagnosis (cluster status, storage, JVM memory, CPU)

## [1.13.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: CodeBuild build failure diagnosis (phases, logs, project config)
- **diagnostic-workflows skill**: CodePipeline execution failure diagnosis (action executions, stage status)
- **diagnostic-workflows skill**: EventBridge rule diagnosis (state, targets, invocation metrics, dead-letter)

## [1.12.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: DynamoDB throttling/latency diagnosis (capacity, throttled requests, GSI issues)
- **diagnostic-workflows skill**: ElastiCache connection/performance diagnosis (CPU, memory, evictions, connections)
- **diagnostic-workflows skill**: Step Functions execution failures (history, failed steps, throttling)
- **diagnostic-workflows skill**: Kinesis stream throughput diagnosis (throughput exceeded, iterator age, shards)

## [1.11.0] - 2026-09-23

### Added
- **diagnostic-workflows skill**: EC2 instance connectivity diagnosis (state, status checks, security groups, NACLs, routes)
- **diagnostic-workflows skill**: API Gateway 5xx/latency diagnosis (errors, latency, throttling, logs)
- **diagnostic-workflows skill**: CloudFront cache/origin diagnosis (error rate, cache hit ratio, origin latency)

## [1.10.0] - 2026-09-22

### Added
- **aws-investigation skill**: Glue investigation (databases, tables, crawlers, job runs, failed jobs)
- **aws-investigation skill**: EMR investigation (clusters, steps, failed steps, instance groups)
- **aws-investigation skill**: AWS Backup investigation (vaults, plans, recovery points, backup jobs)

## [1.9.0] - 2026-09-22

### Added
- **aws-investigation skill**: EFS investigation (file systems, mount targets, access points, burst credits)
- **aws-investigation skill**: Service Quotas investigation (quota listing, usage checks, increase requests)
- **aws-investigation skill**: Cost Explorer investigation (cost by service, daily trends, anomalies, forecasts)

## [1.8.1] - 2026-09-22

### Added
- **aws-investigation skill**: CloudTrail investigation (trails, event lookup, audit logs)

## [1.8.0] - 2026-09-22

### Added
- **aws-investigation skill**: Cognito investigation (user pools, identity pools, user lookup)
- **aws-investigation skill**: OpenSearch investigation (domains, cluster health, JVM memory metrics)
- **aws-investigation skill**: Redshift investigation (clusters, snapshots, query logs, disk usage metrics)
- **aws-investigation skill**: Athena investigation (workgroups, query executions, failed queries)

## [1.7.0] - 2026-09-22

### Added
- **aws-investigation skill**: Kinesis investigation (streams, Firehose, shard iterators, throughput metrics)
- **aws-investigation skill**: CodeBuild investigation (projects, builds, build logs)
- **aws-investigation skill**: CodePipeline investigation (pipelines, state, executions, action details)
- **aws-investigation skill**: Auto Scaling investigation (ASGs, scaling activities, policies, scheduled actions)
- **aws-investigation skill**: ACM investigation (certificates, validation status, expiration checks)

## [1.6.1] - 2026-09-22

### Fixed
- Documentation: restored Secrets Manager, SSM in README service lists
- Documentation: added Route53, Secrets Manager, SSM to skill "When to Use" section

## [1.6.0] - 2026-09-22

### Added
- **aws-investigation skill**: Step Functions investigation (state machines, executions, execution history)
- **aws-investigation skill**: EventBridge investigation (event buses, rules, targets, failed invocations)
- **aws-investigation skill**: CloudFront investigation (distributions, config, invalidations, error rate metrics)
- **aws-investigation skill**: WAF investigation (web ACLs, sampled requests, blocked request metrics)

## [1.5.0] - 2026-09-22

### Added
- **aws-investigation skill**: ECS investigation (clusters, services, tasks, task definitions, container insights)
- **aws-investigation skill**: DynamoDB investigation (tables, capacity metrics, throttling, GSI status)
- **aws-investigation skill**: API Gateway investigation (REST/HTTP APIs, stages, deployments, error/latency metrics)
- **aws-investigation skill**: ElastiCache investigation (Redis/Memcached clusters, node status, memory/eviction metrics)

### Tests
- Control flow edge case tests (function definitions, while/for loops with dangerous commands)
- Extended test suite from 52 to 55 tests

## [1.4.1] - 2026-09-22

### Added
- **diagnostic-workflows skill**: RDS connection issues workflow
- **diagnostic-workflows skill**: Lambda timeout/cold start diagnosis
- **diagnostic-workflows skill**: SQS dead letter queue investigation
- **diagnostic-workflows skill**: Load balancer health check failures

## [1.4.0] - 2026-09-22

### Added
- **aws-investigation skill**: RDS investigation (instances, clusters, events, logs, Performance Insights)
- **aws-investigation skill**: Lambda investigation (functions, metrics, logs)
- **aws-investigation skill**: SQS investigation (queues, depth, dead letter queues)
- **aws-investigation skill**: SNS investigation (topics, subscriptions)
- **aws-investigation skill**: Route53 investigation (zones, records, health checks)
- **aws-investigation skill**: Secrets Manager investigation (metadata, rotation status)
- **aws-investigation skill**: SSM Parameter Store investigation

### Documentation
- Updated chained command blocking docs across README, skills README, and safety-hook skill

## [1.3.8] - 2026-09-22

### Added
- Newline detection in chained command blocking
- Prevents bypass via multiline scripts with dangerous commands

### Tests
- Extended test suite from 51 to 52 tests

## [1.3.7] - 2026-09-22

### Added
- Chained command detection (`;`, `&&`, `||` operators)
- Prevents bypass via `kubectl get pods; kubectl delete pod`

### Tests
- Extended test suite from 46 to 51 tests

## [1.3.6] - 2026-09-22

### Added
- Here-string (`<<<`) blocking pattern for dangerous commands
- Heredoc blocking for kubectl delete, aws iam patterns

### Documentation
- Documented shell metaprogramming limitations in safety-hook skill
- Added known limitations to README security model

### Tests
- Extended test suite from 43 to 46 tests (heredoc, here-string)

## [1.3.5] - 2026-09-22

### Documentation
- Updated README with command/process substitution in blocked section
- Updated skills/README.md with comprehensive hook coverage
- Updated safety-hook skill with process substitution docs

### Tests
- Added process substitution test (43 total tests)

## [1.3.4] - 2026-09-22

### Added
- Process substitution blocking (`<(dangerous command)`)

### Documentation
- Updated safety-hook skill with command substitution and env inspection docs

## [1.3.3] - 2026-09-22

### Added
- Command substitution blocking (`$(dangerous)` and `` `dangerous` ``)
- Environment inspection blocking (`declare -x`, `export -p`)
- Extended fast-path to detect command substitution patterns

### Tests
- Extended test suite from 37 to 42 tests

## [1.3.2] - 2026-09-22

### Documentation
- Updated README with IaC and shell bypass protection sections
- Updated safety-hook skill documentation with all bypass protections

### Tests
- Extended test suite from 26 to 37 tests
- Added IaC tools tests (terraform, helm, eksctl, pulumi)
- Added shell indirection tests (bash -c, sh -c, eval)
- Added pipe/xargs bypass tests

## [1.3.1] - 2026-09-22

### Added
- Node.js/Bun AWS SDK blocking (`node -e` with `@aws-sdk`)
- Eval bypass protection (blocks `eval` with dangerous kubectl/aws commands)
- Xargs/pipe bypass protection (blocks piping to dangerous aws/kubectl)
- Extended fast-path to catch all new bypass vectors

## [1.3.0] - 2026-09-22

### Added
- IaC tools blocking: terraform, pulumi, eksctl, helm (all operations blocked)
- Shell indirection protection: blocks `bash -c` / `sh -c` with dangerous kubectl/aws commands
- Updated fast-path to include new tools for consistent behavior

## [1.2.2] - 2026-09-22

### Infrastructure
- Added GitHub Actions CI workflow for automated testing
- Added status badges to README (CI, License, Release)
- Added CHANGELOG.md

## [1.2.1] - 2026-09-22

### Documentation
- Updated safety-hook skill with eval kernel protection documentation
- Updated README security section to mention eval protection

## [1.2.0] - 2026-09-22

### Added
- PVC/storage diagnostic workflows (CSI driver, StorageClass, zones)
- Volume mount failure diagnosis
- Network policy debugging (selector matching, ingress/egress)
- DNS resolution failure diagnosis (CoreDNS, egress policies)

## [1.1.0] - 2026-09-22

### Security
- Python eval kernel bypass protection
  - Blocks boto3 imports and client creation
  - Blocks kubernetes client imports and API instantiation
  - Blocks AWS credential access via os.environ
  - Blocks subprocess calls to aws/kubectl
- JavaScript eval kernel bypass protection
  - Blocks @aws-sdk/* imports and client creation
  - Blocks @kubernetes/client-node imports
  - Blocks AWS credential access via process.env
  - Blocks child_process/Bun.spawn calls to aws/kubectl

### Documentation
- Added hook performance section to README
- Documented all eval kernel protections

## [1.0.0] - 2026-09-22

### Added
- Initial release
- **Skills**:
  - k8s-investigation: kubectl patterns for pods, deployments, nodes, logs, events
  - aws-investigation: AWS CLI patterns for EKS, EC2, CloudWatch, S3, load balancers
  - diagnostic-workflows: Step-by-step diagnosis for CrashLoopBackOff, OOMKilled, NotReady, etc.
  - safety-hook: Documentation + script that blocks dangerous operations
- **Safety Hook**:
  - Bash command filtering (kubectl allowlist, AWS blocklist)
  - Credential protection (env, printenv, /proc/*/environ)
  - Bypass prevention (python boto3, curl amazonaws)
- **TypeScript Extension**: omp-compatible hook at `.omp/extensions/readonly-infra-hook.ts`
- **Bash Script**: Standalone hook at `.omp/hooks/readonly-infra.sh`

[1.23.16]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.15...v1.23.16
[1.23.15]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.14...v1.23.15
[1.23.14]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.13...v1.23.14
[1.23.13]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.12...v1.23.13
[1.23.12]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.11...v1.23.12
[1.23.11]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.10...v1.23.11
[1.23.10]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.9...v1.23.10
[1.23.9]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.8...v1.23.9
[1.23.8]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.7...v1.23.8
[1.23.7]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.6...v1.23.7
[1.23.6]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.5...v1.23.6
[1.23.5]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.4...v1.23.5
[1.23.4]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.3...v1.23.4
[1.23.3]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.2...v1.23.3
[1.23.2]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.1...v1.23.2
[1.23.1]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.23.0...v1.23.1
[1.23.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.22.0...v1.23.0
[1.22.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.21.0...v1.22.0
[1.21.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.20.0...v1.21.0
[1.20.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.19.0...v1.20.0
[1.19.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.18.0...v1.19.0
[1.18.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.17.0...v1.18.0
[1.17.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.16.0...v1.17.0
[1.16.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.15.0...v1.16.0
[1.15.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.14.0...v1.15.0
[1.14.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.13.0...v1.14.0
[1.13.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.12.0...v1.13.0
[1.12.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.11.0...v1.12.0
[1.11.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.10.0...v1.11.0
[1.10.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.9.0...v1.10.0
[1.9.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.8.1...v1.9.0
[1.8.1]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.8.0...v1.8.1
[1.8.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.7.0...v1.8.0
[1.7.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.6.1...v1.7.0
[1.6.1]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.6.0...v1.6.1
[1.6.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.5.0...v1.6.0
[1.5.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.4.1...v1.5.0
[1.4.1]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.4.0...v1.4.1
[1.4.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.8...v1.4.0
[1.3.8]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.7...v1.3.8
[1.3.7]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.6...v1.3.7
[1.3.6]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.5...v1.3.6
[1.3.5]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.4...v1.3.5
[1.3.4]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.3...v1.3.4
[1.3.3]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.2...v1.3.3
[1.3.2]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.1...v1.3.2
[1.3.1]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.3.0...v1.3.1
[1.3.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.2.2...v1.3.0
[1.2.2]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ilyasabdut/aws-infra-skills/releases/tag/v1.0.0
