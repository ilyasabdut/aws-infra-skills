#!/bin/bash
#
# Autoresearch benchmark harness for read-only infrastructure hook
#
# Measures: hook evaluation latency (time to check command allowlists/blocklists)
# Primary metric: avg_latency_ms (average time per command check)
# Secondary metrics: total_time_ms, commands_checked, pass_rate
#

set -euo pipefail

HOOK=".omp/hooks/readonly-infra.sh"
ITERATIONS=100

# Test commands (mix of allowed and blocked)
COMMANDS=(
    "kubectl get pods -n default"
    "kubectl describe pod test -n default"
    "kubectl logs test -n default"
    "kubectl delete pod test"
    "kubectl apply -f test.yaml"
    "kubectl exec -it test -- bash"
    "aws eks describe-cluster --name test"
    "aws eks list-clusters"
    "aws ec2 describe-instances"
    "aws iam list-users"
    "aws ec2 terminate-instances --instance-ids i-123"
    "aws s3 ls"
    "aws s3 rm s3://bucket/key"
    "env"
    "printenv"
    "python -c import boto3"
)

NUM_COMMANDS=${#COMMANDS[@]}
TOTAL_CHECKS=$((ITERATIONS * NUM_COMMANDS))

echo "Running $ITERATIONS iterations of $NUM_COMMANDS commands ($TOTAL_CHECKS total checks)..."

# Measure total time
START_NS=$(python3 -c 'import time; print(int(time.time_ns()))')

PASSED=0
FAILED=0

for ((i=0; i<ITERATIONS; i++)); do
    for cmd in "${COMMANDS[@]}"; do
        # Run hook, capture exit code
        if $HOOK $cmd >/dev/null 2>&1; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    done
done

END_NS=$(python3 -c 'import time; print(int(time.time_ns()))')

# Calculate metrics
ELAPSED_NS=$((END_NS - START_NS))
ELAPSED_MS=$((ELAPSED_NS / 1000000))
AVG_LATENCY_US=$((ELAPSED_NS / TOTAL_CHECKS / 1000))
AVG_LATENCY_MS=$(python3 -c "print(f'{$ELAPSED_NS / $TOTAL_CHECKS / 1000000:.3f}')")
PASS_RATE=$(python3 -c "print(f'{$PASSED / $TOTAL_CHECKS * 100:.1f}')")

echo ""
echo "Results:"
echo "  Total time: ${ELAPSED_MS}ms"
echo "  Commands checked: $TOTAL_CHECKS"
echo "  Passed: $PASSED, Failed: $FAILED"
echo "  Pass rate: ${PASS_RATE}%"
echo "  Avg latency: ${AVG_LATENCY_MS}ms per check"
echo ""

# Output metrics for autoresearch
echo "METRIC avg_latency_ms=$AVG_LATENCY_MS"
echo "METRIC total_time_ms=$ELAPSED_MS"
echo "METRIC commands_checked=$TOTAL_CHECKS"
echo "METRIC pass_rate=$PASS_RATE"
