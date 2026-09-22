#!/bin/bash
#
# Read-Only Infrastructure Hook
# 
# PreToolUse hook for omp that blocks dangerous kubectl/AWS operations.
# Returns 0 to allow, 1 to block (with message on stderr).
#
# Usage: This hook is invoked by omp before bash tool execution.
# The command to check is passed as arguments.

set -euo pipefail

COMMAND="$*"

# Helper: print block message and exit 1
block() {
    echo "BLOCKED: $1" >&2
    exit 1
}

# Skip empty commands
[[ -z "$COMMAND" ]] && exit 0

# ============================================================================
# KUBECTL FILTERING (allowlist approach)
# ============================================================================

if [[ "$COMMAND" =~ ^kubectl[[:space:]] ]] || [[ "$COMMAND" =~ [[:space:]]kubectl[[:space:]] ]]; then
    # Extract subcommand
    KUBECTL_SUBCMD=$(echo "$COMMAND" | grep -oE 'kubectl[[:space:]]+[a-z-]+' | awk '{print $2}' || true)
    
    # Allowed kubectl subcommands
    ALLOWED_KUBECTL="get describe logs top api-resources api-versions cluster-info version config rollout"
    
    # Check if subcommand is allowed
    if [[ -n "$KUBECTL_SUBCMD" ]]; then
        # Special handling for config (only certain subcommands)
        if [[ "$KUBECTL_SUBCMD" == "config" ]]; then
            if [[ "$COMMAND" =~ config[[:space:]]+(view|get-contexts|current-context|get-clusters) ]]; then
                exit 0  # allowed
            else
                block "kubectl config modification is not allowed. Use: kubectl config view"
            fi
        fi
        
        # Special handling for rollout (only status allowed)
        if [[ "$KUBECTL_SUBCMD" == "rollout" ]]; then
            if [[ "$COMMAND" =~ rollout[[:space:]]+status ]]; then
                exit 0  # allowed
            else
                block "kubectl rollout (except status) modifies workloads. Use: kubectl rollout status"
            fi
        fi
        
        # Check allowlist
        if ! echo "$ALLOWED_KUBECTL" | grep -qw "$KUBECTL_SUBCMD"; then
            case "$KUBECTL_SUBCMD" in
                exec)
                    block "kubectl exec allows arbitrary code execution. To see logs: kubectl logs <pod> -n <ns>"
                    ;;
                apply|create|delete|patch|edit|replace)
                    block "kubectl $KUBECTL_SUBCMD is a write operation. For investigation use: kubectl get, describe, logs"
                    ;;
                scale)
                    block "kubectl scale modifies replica count. To check: kubectl describe deployment <name>"
                    ;;
                drain|cordon|uncordon|taint)
                    block "kubectl $KUBECTL_SUBCMD modifies node state. To investigate: kubectl describe node <name>"
                    ;;
                cp|port-forward|attach|debug|run|expose|set|label|annotate)
                    block "kubectl $KUBECTL_SUBCMD is not permitted in read-only mode"
                    ;;
                *)
                    block "kubectl $KUBECTL_SUBCMD is not in the allowed list (get, describe, logs, top, version, cluster-info)"
                    ;;
            esac
        fi
    fi
fi

# ============================================================================
# AWS CLI FILTERING (blocklist approach)
# ============================================================================

if [[ "$COMMAND" =~ ^aws[[:space:]] ]] || [[ "$COMMAND" =~ [[:space:]]aws[[:space:]] ]]; then
    
    # Block IAM entirely
    if [[ "$COMMAND" =~ aws[[:space:]]+iam[[:space:]] ]]; then
        block "aws iam operations are not permitted. This agent has read-only access."
    fi
    
    # Block organizations
    if [[ "$COMMAND" =~ aws[[:space:]]+organizations[[:space:]] ]]; then
        block "aws organizations operations are not permitted."
    fi
    
    # Block STS assume-role (privilege escalation)
    if [[ "$COMMAND" =~ aws[[:space:]]+sts[[:space:]]+assume-role ]]; then
        block "aws sts assume-role is not permitted (prevents privilege escalation)."
    fi
    
    # Block S3 write operations
    if [[ "$COMMAND" =~ aws[[:space:]]+s3[[:space:]]+rm[[:space:]] ]]; then
        block "aws s3 rm is not permitted. Read-only: aws s3 ls, aws s3 cp s3://... -"
    fi
    if [[ "$COMMAND" =~ aws[[:space:]]+s3[[:space:]]+mv[[:space:]] ]]; then
        block "aws s3 mv is not permitted."
    fi
    # Block upload (cp TO s3, but allow download FROM s3)
    if [[ "$COMMAND" =~ aws[[:space:]]+s3[[:space:]]+cp[[:space:]] ]] && [[ ! "$COMMAND" =~ s3://[^[:space:]]+[[:space:]]+-$ ]] && [[ "$COMMAND" =~ [[:space:]]s3:// ]]; then
        # If there's an s3:// that's not followed by " -" (stdout), and it's not the source, block
        if [[ "$COMMAND" =~ [[:space:]][^s][^3][^:][^/][^/][^[:space:]]*[[:space:]]+s3:// ]]; then
            block "aws s3 cp upload is not permitted. Download allowed: aws s3 cp s3://bucket/key -"
        fi
    fi
    if [[ "$COMMAND" =~ aws[[:space:]]+s3[[:space:]]+sync[[:space:]] ]] && [[ "$COMMAND" =~ [[:space:]]s3:// ]] && [[ ! "$COMMAND" =~ ^aws[[:space:]]+s3[[:space:]]+sync[[:space:]]+s3:// ]]; then
        block "aws s3 sync upload is not permitted."
    fi
    
    # Block s3api write operations
    if [[ "$COMMAND" =~ aws[[:space:]]+s3api[[:space:]]+(delete-|put-) ]]; then
        block "aws s3api write operations are not permitted."
    fi
    
    # Block mutation verbs across all services
    MUTATION_PATTERNS=(
        "delete-"
        "terminate-"
        "modify-"
        "update-"
        "create-"
        "put-"
        "remove-"
        "deregister-"
        "attach-"
        "detach-"
        "enable-"
        "disable-"
        "start-"
        "stop-"
        "reboot-"
        "run-instances"
        "run-task"
    )
    
    for pattern in "${MUTATION_PATTERNS[@]}"; do
        if [[ "$COMMAND" =~ aws[[:space:]]+[a-z0-9-]+[[:space:]]+$pattern ]]; then
            SERVICE=$(echo "$COMMAND" | grep -oE 'aws[[:space:]]+[a-z0-9-]+' | awk '{print $2}' || true)
            block "aws $SERVICE $pattern* is a mutating operation. Read-only: describe-*, list-*, get-*"
        fi
    done
fi

# ============================================================================
# CREDENTIAL PROTECTION
# ============================================================================

# Block environment inspection
if [[ "$COMMAND" =~ ^env$ ]] || [[ "$COMMAND" =~ ^printenv ]] || [[ "$COMMAND" =~ ^export$ ]] || [[ "$COMMAND" =~ ^set$ ]]; then
    block "Environment inspection is not permitted (protects credentials)."
fi

# Block /proc environ access
if [[ "$COMMAND" =~ /proc/[0-9]+/environ ]] || [[ "$COMMAND" =~ /proc/self/environ ]]; then
    block "Process environment inspection is not permitted."
fi

# Block credential echoing
if [[ "$COMMAND" =~ echo.*\$AWS_SECRET ]] || [[ "$COMMAND" =~ echo.*\$\{AWS_SECRET ]]; then
    block "Credential inspection is not permitted."
fi
if [[ "$COMMAND" =~ echo.*\$AWS_SESSION_TOKEN ]] || [[ "$COMMAND" =~ echo.*\$\{AWS_SESSION_TOKEN ]]; then
    block "Credential inspection is not permitted."
fi

# ============================================================================
# BYPASS PREVENTION
# ============================================================================

# Block Python boto3
if [[ "$COMMAND" =~ python[3]?[[:space:]].*boto3 ]] || [[ "$COMMAND" =~ python[3]?[[:space:]]+-c.*import[[:space:]]+boto ]]; then
    block "Direct SDK access not permitted. Use aws CLI for allowed operations."
fi

# Block curl/wget to AWS APIs
if [[ "$COMMAND" =~ curl.*\.amazonaws\.com ]] || [[ "$COMMAND" =~ wget.*\.amazonaws\.com ]]; then
    block "Direct AWS API access not permitted. Use aws CLI."
fi

# ============================================================================
# ALLOWED - Command passed all checks
# ============================================================================

exit 0
