# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.3.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.2.2...v1.3.0
[1.2.2]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.2.1...v1.2.2
[1.2.1]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/ilyasabdut/aws-infra-skills/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ilyasabdut/aws-infra-skills/releases/tag/v1.0.0
