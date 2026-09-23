## 1. Project Setup

- [x] 1.1 Create `.omp/skills/` directory structure
- [x] 1.2 Create `.omp/hooks/` directory for hook configuration
- [x] 1.3 Verify kubectl and aws-cli are available in PATH

## 2. Safety Hook Implementation

- [x] 2.1 Create hook configuration file at `.omp/hooks/readonly-infra.yaml`
- [x] 2.2 Implement kubectl allowlist logic (get, describe, logs, top, api-resources, api-versions, cluster-info, version)
- [x] 2.3 Implement kubectl blocklist (apply, create, delete, patch, edit, replace, scale, rollout, exec, cp, port-forward, run, expose, set, label, annotate, taint, cordon, uncordon, drain, attach, debug)
- [x] 2.4 Implement AWS CLI blocklist patterns (delete-*, create-*, modify-*, update-*, put-*, terminate-*)
- [x] 2.5 Implement IAM full block (aws iam *)
- [x] 2.6 Implement S3 write block (rm, mv, cp to s3://, sync to s3://)
- [x] 2.7 Implement credential protection (block env, printenv, /proc/*/environ)
- [x] 2.8 Implement bypass prevention (block python boto3, curl to *.amazonaws.com)
- [x] 2.9 Add helpful block messages with alternatives
- [x] 2.10 Create TypeScript extension at `.omp/extensions/readonly-infra-hook.ts`

## 3. Kubernetes Investigation Skill

- [x] 3.1 Create `.omp/skills/k8s-investigation/SKILL.md` with frontmatter
- [x] 3.2 Document pod investigation commands (get, describe, logs, logs --previous)
- [x] 3.3 Document deployment investigation commands (get deployments, describe, get rs)
- [x] 3.4 Document node investigation commands (get nodes, describe node, top nodes)
- [x] 3.5 Document PVC investigation commands (get pvc, describe pvc)
- [x] 3.6 Document events investigation commands (get events, field-selector)
- [x] 3.7 Document HPA and ScaledObject investigation commands
- [x] 3.8 Document service and endpoint investigation commands

## 4. AWS Investigation Skill

- [x] 4.1 Create `.omp/skills/aws-investigation/SKILL.md` with frontmatter
- [x] 4.2 Document EKS cluster investigation commands (list-clusters, describe-cluster, list-nodegroups, describe-nodegroup)
- [x] 4.3 Document EC2 instance investigation commands (describe-instances, describe-instance-status)
- [x] 4.4 Document CloudWatch Logs commands (describe-log-groups, describe-log-streams, get-log-events, filter-log-events)
- [x] 4.5 Document CloudWatch Metrics commands (list-metrics, get-metric-statistics, get-metric-data)
- [x] 4.6 Document Load Balancer commands (describe-load-balancers, describe-target-health)
- [x] 4.7 Document S3 read-only commands (list-buckets, list-objects-v2, cp from s3://)

## 5. Diagnostic Workflows Skill

- [x] 5.1 Create `.omp/skills/diagnostic-workflows/SKILL.md` with frontmatter
- [x] 5.2 Document CrashLoopBackOff diagnosis procedure
- [x] 5.3 Document OOMKilled diagnosis procedure
- [x] 5.4 Document ImagePullBackOff diagnosis procedure
- [x] 5.5 Document NotReady node diagnosis procedure
- [x] 5.6 Document resource pressure diagnosis procedure
- [x] 5.7 Document unavailable replicas diagnosis procedure
- [x] 5.8 Document HPA/KEDA scaling issues diagnosis procedure
- [x] 5.9 Document service connectivity diagnosis procedure
- [x] 5.10 Document standard diagnosis output format

## 6. Integration Testing

- [x] 6.1 Test hook blocks `kubectl delete pod`
- [x] 6.2 Test hook blocks `kubectl exec`
- [x] 6.3 Test hook blocks `kubectl apply`
- [x] 6.4 Test hook allows `kubectl get pods`
- [x] 6.5 Test hook allows `kubectl logs`
- [x] 6.6 Test hook blocks `aws iam list-users`
- [x] 6.7 Test hook blocks `aws ec2 terminate-instances`
- [x] 6.8 Test hook allows `aws eks describe-cluster`
- [x] 6.9 Test hook blocks `env` and `printenv`
- [x] 6.10 Test skills load correctly in omp session
- [x] 6.11 Test hook allows `aws ecr describe-repositories`
- [x] 6.12 Test hook allows `aws ecr list-images`
- [x] 6.13 Test hook blocks `aws ecr delete-repository`
- [x] 6.14 Test hook blocks `aws ecr put-image`
- [x] 6.15 Test hook blocks `aws ec2 run-instances`
- [x] 6.16 Test hook blocks `aws eks create-cluster`
