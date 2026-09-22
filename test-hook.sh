#!/bin/bash
#
# Smoke test for read-only infrastructure hook
#

HOOK=".omp/hooks/readonly-infra.sh"
PASS=0
FAIL=0

test_block() {
    local desc="$1"
    shift
    if "$HOOK" "$@" 2>&1 | grep -q "BLOCKED\|Blocked"; then
        echo "✓ BLOCKED: $desc"
        ((PASS++))
    else
        echo "✗ SHOULD BLOCK: $desc"
        ((FAIL++))
    fi
}

test_allow() {
    local desc="$1"
    shift
    if "$HOOK" "$@" 2>&1; then
        echo "✓ ALLOWED: $desc"
        ((PASS++))
    else
        echo "✗ SHOULD ALLOW: $desc"
        ((FAIL++))
    fi
}

echo "=== Read-Only Infrastructure Hook Smoke Test ==="
echo ""

echo "--- kubectl tests ---"
test_allow "kubectl get pods" kubectl get pods -n default
test_allow "kubectl describe pod" kubectl describe pod test -n default
test_allow "kubectl logs" kubectl logs test -n default
test_allow "kubectl top nodes" kubectl top nodes
test_allow "kubectl version" kubectl version
test_allow "kubectl rollout status" kubectl rollout status deployment/test
test_block "kubectl delete" kubectl delete pod test -n default
test_block "kubectl apply" kubectl apply -f deployment.yaml
test_block "kubectl exec" kubectl exec -it test -- bash
test_block "kubectl scale" kubectl scale deployment test --replicas=3
test_block "kubectl edit" kubectl edit deployment test
test_block "kubectl drain" kubectl drain node1

echo ""
echo "--- AWS CLI tests ---"
test_allow "aws eks describe-cluster" aws eks describe-cluster --name test
test_allow "aws eks list-clusters" aws eks list-clusters
test_allow "aws ec2 describe-instances" aws ec2 describe-instances
test_allow "aws logs describe-log-groups" aws logs describe-log-groups
test_allow "aws s3 ls" aws s3 ls
test_block "aws iam list-users" aws iam list-users
test_block "aws ec2 terminate-instances" aws ec2 terminate-instances --instance-ids i-123
test_block "aws eks delete-cluster" aws eks delete-cluster --name test
test_block "aws s3 rm" aws s3 rm s3://bucket/key
test_block "aws ec2 create-instance" aws ec2 create-instance --image-id ami-123

echo ""
echo "--- Credential protection tests ---"
test_block "env" env
test_block "printenv" printenv

echo ""
echo "--- Bypass prevention tests ---"
test_block "python boto3" python -c "import boto3"
test_block "curl amazonaws" curl https://eks.amazonaws.com

echo ""
echo "--- IaC tools tests ---"
test_block "terraform apply" terraform apply
test_block "helm install" helm install nginx
test_block "eksctl create" eksctl create cluster
test_block "pulumi up" pulumi up

echo ""
echo "--- Shell indirection tests ---"
test_block "bash -c kubectl delete" 'bash -c "kubectl delete pod test"'
test_block "sh -c aws iam" 'sh -c "aws iam list-users"'
test_block "eval kubectl delete" 'eval "kubectl delete pod test"'
test_block "eval aws iam" 'eval "aws iam list-users"'

echo ""
echo "--- Pipe/xargs bypass tests ---"
test_block "xargs aws delete" 'echo x | xargs aws eks delete-cluster'
test_block "pipe kubectl delete" 'cat pods.txt | kubectl delete -f -'
test_block "node aws-sdk" 'node -e "require(\"@aws-sdk/client-ec2\")"'

echo ""
echo "--- Command substitution tests ---"
test_block "subshell kubectl delete" 'echo $(kubectl delete pod test)'
test_block "backtick aws iam" 'echo `aws iam list-users`'
test_block "subshell aws terminate" 'VAR=$(aws ec2 terminate-instances --instance-ids i-123)'
test_block "process substitution kubectl delete" 'diff <(kubectl delete pod test) <(echo x)'

echo ""
echo "--- Heredoc and here-string tests ---"
test_block "heredoc kubectl delete" 'cat <<EOF
kubectl delete pod test
EOF'
test_block "here-string kubectl delete" 'cat <<< "kubectl delete pod test"'
test_block "heredoc aws iam" 'bash <<EOF
aws iam list-users
EOF'

echo ""
echo "--- Environment inspection tests ---"
test_block "declare -x" "declare -x"
test_block "export -p" "export -p"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ $FAIL -eq 0 ]
