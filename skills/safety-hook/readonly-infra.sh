#!/bin/bash
#
# Read-Only Infrastructure Hook (optimized v2)
# 
# PreToolUse hook for omp that blocks dangerous kubectl/AWS operations.
# Returns 0 to allow, 1 to block (with message on stderr).
#
# Optimized: no subprocesses (grep/awk), single-pass regex checks
#

set -euo pipefail

CMD="$*"

# Skip empty commands
[[ -z "$CMD" ]] && exit 0

# Helper: print block message and exit 1
block() {
    echo "BLOCKED: $1" >&2
    exit 1
}

# ============================================================================
# FAST PATH: Early exit for non-infrastructure commands
# ============================================================================

# Quick check - if not kubectl/aws/env/printenv/python/curl/IaC/shell/node/eval/xargs/declare/echo, allow immediately
if [[ ! "$CMD" =~ (^|[[:space:]])(kubectl|aws|env|printenv|export|set|python|curl|wget|terraform|pulumi|eksctl|helm|bash|sh|node|bun|eval|xargs|declare|echo|diff)[[:space:]] ]] && \
   [[ ! "$CMD" =~ ^(env|printenv|export|set|eval|declare)$ ]] && \
   [[ ! "$CMD" =~ \|[[:space:]]*(aws|kubectl) ]] && \
   [[ ! "$CMD" =~ \$\(|\`|\<\(|\<\<\< ]]; then
    exit 0
fi

# ============================================================================
# CHAINED COMMAND DETECTION
# Scan for dangerous commands after ; && || before allowlist short-circuits
# ============================================================================

# Block dangerous kubectl after chain operators (including newlines)
if [[ "$CMD" =~ ($'\n'|[';''|''&'])[[:space:]]*(kubectl[[:space:]]+(delete|apply|exec|scale|edit|patch|drain|cordon|create|run)) ]]; then
    block "Chained kubectl mutation command detected. Run commands separately."
fi

# Block dangerous aws after chain operators (including newlines)
if [[ "$CMD" =~ ($'\n'|[';''|''&'])[[:space:]]*(aws[[:space:]]+iam) ]] || \
   [[ "$CMD" =~ ($'\n'|[';''|''&'])[[:space:]]*(aws[[:space:]]+[a-z0-9-]+[[:space:]]+(delete-|terminate-|create-|modify-)) ]]; then
    block "Chained AWS mutation command detected. Run commands separately."
fi

# ============================================================================
# KUBECTL FILTERING (allowlist approach)
# ============================================================================

if [[ "$CMD" =~ (^|[[:space:]])kubectl[[:space:]]+([a-z-]+) ]]; then
    SUBCMD="${BASH_REMATCH[2]}"
    
    # Allowed subcommands - use case for O(1) lookup
    case "$SUBCMD" in
        get|describe|logs|top|api-resources|api-versions|cluster-info|version)
            exit 0
            ;;
        config)
            if [[ "$CMD" =~ config[[:space:]]+(view|get-contexts|current-context|get-clusters) ]]; then
                exit 0
            fi
            block "kubectl config modification is not allowed. Use: kubectl config view"
            ;;
        rollout)
            if [[ "$CMD" =~ rollout[[:space:]]+status ]]; then
                exit 0
            fi
            block "kubectl rollout (except status) modifies workloads. Use: kubectl rollout status"
            ;;
        exec)
            block "kubectl exec allows arbitrary code execution. To see logs: kubectl logs <pod> -n <ns>"
            ;;
        apply|create|delete|patch|edit|replace)
            block "kubectl $SUBCMD is a write operation. For investigation use: kubectl get, describe, logs"
            ;;
        scale)
            block "kubectl scale modifies replica count. To check: kubectl describe deployment <name>"
            ;;
        drain|cordon|uncordon|taint)
            block "kubectl $SUBCMD modifies node state. To investigate: kubectl describe node <name>"
            ;;
        cp|port-forward|attach|debug|run|expose|set|label|annotate)
            block "kubectl $SUBCMD is not permitted in read-only mode"
            ;;
        *)
            block "kubectl $SUBCMD is not in the allowed list (get, describe, logs, top, version, cluster-info)"
            ;;
    esac
fi

# ============================================================================
# AWS CLI FILTERING (blocklist approach)
# ============================================================================

if [[ "$CMD" =~ (^|[[:space:]])aws[[:space:]]+([a-z0-9-]+) ]]; then
    SERVICE="${BASH_REMATCH[2]}"
    
    # Block entire services
    case "$SERVICE" in
        iam)
            block "aws iam operations are not permitted. This agent has read-only access."
            ;;
        organizations)
            block "aws organizations operations are not permitted."
            ;;
    esac
    
    # Block STS assume-role
    if [[ "$SERVICE" == "sts" && "$CMD" =~ assume-role ]]; then
        block "aws sts assume-role is not permitted (prevents privilege escalation)."
    fi
    
    # Block S3 write operations
    if [[ "$SERVICE" == "s3" ]]; then
        if [[ "$CMD" =~ [[:space:]](rm|mv)[[:space:]] ]]; then
            block "aws s3 rm/mv is not permitted. Read-only: aws s3 ls, aws s3 cp s3://... -"
        fi
        # Block upload (cp TO s3)
        if [[ "$CMD" =~ [[:space:]]cp[[:space:]] && "$CMD" =~ [[:space:]]s3:// && ! "$CMD" =~ s3://[^[:space:]]+[[:space:]]+-$ ]]; then
            block "aws s3 cp upload is not permitted. Download allowed: aws s3 cp s3://bucket/key -"
        fi
        if [[ "$CMD" =~ [[:space:]]sync[[:space:]] && ! "$CMD" =~ sync[[:space:]]+s3:// ]]; then
            block "aws s3 sync upload is not permitted."
        fi
    fi
    
    # Block s3api write operations
    if [[ "$SERVICE" == "s3api" && "$CMD" =~ [[:space:]](delete-|put-) ]]; then
        block "aws s3api write operations are not permitted."
    fi
    
    # Allow CloudWatch Logs Insights query operations (read-only despite start- prefix)
    if [[ "$SERVICE" == "logs" && "$CMD" =~ [[:space:]](start-query|stop-query|get-query-results) ]]; then
        exit 0
    fi
    
    # Block mutation verbs across all services - single combined regex (no loop)
    # Patterns grouped by category:
    #   CRUD: delete-, create-, put-, remove-, update-, modify-
    #   Lifecycle: terminate-, start-, stop-, reboot-, enable-, disable-
    #   Attachment: attach-, detach-, register-, deregister-, associate-, disassociate-
    #   Security: authorize-, revoke-
    #   Resource: import-, copy-, allocate-, release-, cancel-
    #   Approval: accept-, reject-
    #   Tagging: tag-resource, untag-resource
    #   Messaging: send-, invoke, publish, send-command
    #   Compute: run-instances, run-task
    #   Execution: execute-
    #   Configuration: set-, reset-
    #   Recovery: restore-, failover-, promote-, revert-, switchover-
    #   Movement: move-, migrate-
    #   Batch mutations: batch-write-, batch-delete-, batch-put-
    #   Replacement: replace-
    #   Provisioning: request-, purchase-, provision-, deprovision-
    #   Assignment: assign-, unassign-
    #   Submission: submit-, apply-
    #   Packaging: bundle-
    #   Confirmation: confirm-
    #   Export/Clone: export-, clone-
    #   Locking: lock-, unlock-
    #   BYOIP: advertise-, withdraw-
    #   Other: add-, write-
    if [[ "$CMD" =~ [[:space:]](delete-|terminate-|modify-|update-|create-|put-|remove-|deregister-|attach-|detach-|enable-|disable-|start-|stop-|reboot-|add-|register-|associate-|disassociate-|authorize-|revoke-|import-|copy-|send-|invoke|publish|run-instances|run-task|send-command|tag-resource|untag-resource|allocate-|release-|accept-|reject-|cancel-|write-|execute-|set-|reset-|restore-|failover-|promote-|revert-|move-|batch-write-|batch-delete-|batch-put-|replace-|request-|purchase-|assign-|unassign-|submit-|apply-|bundle-|confirm-|switchover-|migrate-|export-|clone-|lock-|unlock-|provision-|deprovision-|advertise-|withdraw-) ]]; then
        block "aws $SERVICE mutation operation is not permitted. Read-only: describe-*, list-*, get-*"
    fi
fi

# ============================================================================
# CREDENTIAL PROTECTION
# ============================================================================

# Block environment inspection
if [[ "$CMD" =~ ^(env|printenv|export|set)$ ]] || [[ "$CMD" =~ ^printenv[[:space:]] ]]; then
    block "Environment inspection is not permitted (protects credentials)."
fi

# Block declare -x and export -p (list exported variables)
if [[ "$CMD" =~ declare[[:space:]]+-[^[:space:]]*x ]] || [[ "$CMD" =~ ^declare$ ]] || [[ "$CMD" =~ export[[:space:]]+-p ]]; then
    block "Environment inspection is not permitted (protects credentials)."
fi

# Block /proc environ access
if [[ "$CMD" =~ /proc/[0-9]+/environ ]] || [[ "$CMD" =~ /proc/self/environ ]]; then
    block "Process environment inspection is not permitted."
fi

# Block credential echoing
if [[ "$CMD" =~ echo.*\$(AWS_SECRET|AWS_SESSION_TOKEN|\{AWS_SECRET|\{AWS_SESSION_TOKEN) ]]; then
    block "Credential inspection is not permitted."
fi

# ============================================================================
# BYPASS PREVENTION
# ============================================================================

# Block Python boto3
if [[ "$CMD" =~ python[3]?[[:space:]].*boto3 ]] || [[ "$CMD" =~ python[3]?[[:space:]]+-c.*import[[:space:]]*boto ]]; then
    block "Direct SDK access not permitted. Use aws CLI for allowed operations."
fi

# Block curl/wget to AWS APIs
if [[ "$CMD" =~ (curl|wget).*\.amazonaws\.com ]]; then
    block "Direct AWS API access not permitted. Use aws CLI."
fi
# Block Node.js/Bun AWS SDK
if [[ "$CMD" =~ (node|bun)[[:space:]].*@aws-sdk ]] || [[ "$CMD" =~ (node|bun)[[:space:]]+-e.*aws-sdk ]]; then
    block "Direct SDK access not permitted. Use aws CLI for allowed operations."
fi

# Block eval with dangerous commands
if [[ "$CMD" =~ ^eval[[:space:]] ]] || [[ "$CMD" =~ [[:space:]]eval[[:space:]] ]]; then
    if [[ "$CMD" =~ (kubectl[[:space:]]+(delete|apply|exec|scale)|aws[[:space:]]+iam|aws[[:space:]]+[a-z]+[[:space:]]+(delete-|create-|terminate-)) ]]; then
        block "eval with dangerous commands is not permitted."
    fi
fi

# Block xargs/pipe bypass to dangerous aws commands
if [[ "$CMD" =~ xargs[[:space:]]+(aws|kubectl) ]] || [[ "$CMD" =~ \|[[:space:]]*(aws|kubectl) ]]; then
    if [[ "$CMD" =~ (delete|terminate|create|modify|apply|exec|scale|iam) ]]; then
        block "Piping to dangerous aws/kubectl commands is not permitted."
    fi
fi

# Block command substitution with dangerous commands (simplified pattern)
if [[ "$CMD" =~ \$\( ]] && [[ "$CMD" =~ (kubectl[[:space:]]+(delete|apply|exec|scale)|aws[[:space:]]+iam|terminate-|delete-cluster|create-|modify-) ]]; then
    block "Command substitution with dangerous commands is not permitted."
fi

# Block backtick substitution with dangerous commands
if [[ "$CMD" =~ \` ]] && [[ "$CMD" =~ (kubectl[[:space:]]+(delete|apply|exec|scale)|aws[[:space:]]+iam|terminate-|delete-cluster|create-|modify-) ]]; then
    block "Command substitution with dangerous commands is not permitted."
fi

# Block process substitution with dangerous commands
if [[ "$CMD" =~ \<\( ]] && [[ "$CMD" =~ (kubectl[[:space:]]+(delete|apply|exec|scale)|aws[[:space:]]+iam|terminate-|delete-cluster|create-|modify-) ]]; then
    block "Process substitution with dangerous commands is not permitted."
fi

# Block here-string with dangerous commands
if [[ "$CMD" =~ \<\<\< ]] && [[ "$CMD" =~ (kubectl[[:space:]]+(delete|apply|exec|scale)|aws[[:space:]]+iam|terminate-|delete-cluster|create-|modify-) ]]; then
    block "Here-string with dangerous commands is not permitted."
fi
# Block IaC tools that can modify infrastructure
if [[ "$CMD" =~ (^|[[:space:]])(terraform|pulumi|eksctl|helm)[[:space:]] ]]; then
    TOOL="${BASH_REMATCH[2]}"
    block "$TOOL is not permitted. This agent has read-only infrastructure access."
fi

# Block shell indirection (sh -c, bash -c) with dangerous commands
if [[ "$CMD" =~ (sh|bash)[[:space:]]+-c[[:space:]] ]]; then
    if [[ "$CMD" =~ (kubectl[[:space:]]+(delete|apply|exec|scale)|aws[[:space:]]+iam|aws[[:space:]]+[a-z]+[[:space:]]+(delete-|create-|terminate-)) ]]; then
        block "Shell indirection with dangerous commands is not permitted."
    fi
fi

# ============================================================================
# ALLOWED - Command passed all checks
# ============================================================================

exit 0
