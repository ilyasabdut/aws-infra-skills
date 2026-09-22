/**
 * Read-Only Infrastructure Hook
 *
 * Blocks dangerous kubectl and AWS CLI operations for AI agents.
 * Ensures agents can only perform read-only infrastructure investigation.
 *
 * Hooks `bash` tool calls and blocks:
 * - kubectl write operations (apply, delete, exec, scale, etc.)
 * - AWS mutation operations (delete-*, create-*, modify-*, etc.)
 * - IAM operations entirely
 * - Credential extraction attempts (env, printenv, proc environ)
 * - SDK bypass attempts (python boto3, curl to AWS APIs)
 *
 * Hooks `eval` tool calls (Python) and blocks:
 * - boto3 imports and client creation (AWS SDK bypass)
 * - kubernetes client imports and API instantiation
 * - AWS credential access via os.environ
 * - subprocess calls to aws/kubectl
 *
 * Hooks `eval` tool calls (JavaScript) and blocks:
 * - @aws-sdk/* imports and client creation
 * - @kubernetes/client-node imports and API instantiation
 * - AWS credential access via process.env
 * - child_process/Bun.spawn calls to aws/kubectl
 */

import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

// kubectl subcommands that are allowed (read-only)
const KUBECTL_ALLOWED: Record<string, true> = {
	get: true,
	describe: true,
	logs: true,
	top: true,
	"api-resources": true,
	"api-versions": true,
	"cluster-info": true,
	version: true,
	config: true,
	rollout: true, // handled specially - only "status" allowed
};

// kubectl config subcommands that are allowed
const KUBECTL_CONFIG_ALLOWED: Record<string, true> = {
	view: true,
	"get-contexts": true,
	"current-context": true,
	"get-clusters": true,
};

// AWS services that are completely blocked
const AWS_BLOCKED_SERVICES: Record<string, true> = {
	iam: true,
	organizations: true,
};

// AWS mutation verb patterns
const AWS_MUTATION_VERBS = [
	// CRUD
	"delete-",
	"create-",
	"put-",
	"remove-",
	"update-",
	"modify-",
	// Lifecycle
	"terminate-",
	"start-",
	"stop-",
	"reboot-",
	"enable-",
	"disable-",
	// Attachment
	"attach-",
	"detach-",
	"register-",
	"deregister-",
	"associate-",
	"disassociate-",
	// Security
	"authorize-",
	"revoke-",
	// Resource
	"import-",
	"copy-",
	"allocate-",
	"release-",
	"cancel-",
	// Approval
	"accept-",
	"reject-",
	// Tagging
	"tag-resource",
	"untag-resource",
	// Messaging
	"send-",
	"invoke",
	"publish",
	"send-command",
	// Compute
	"run-instances",
	"run-task",
	// Execution
	"execute-",
	// Configuration
	"set-",
	"reset-",
	// Recovery
	"restore-",
	"failover-",
	"promote-",
	"revert-",
	"switchover-",
	// Movement
	"move-",
	// Batch mutations
	"batch-write-",
	"batch-delete-",
	"batch-put-",
	// Replacement
	"replace-",
	// Provisioning
	"request-",
	"purchase-",
	// Assignment
	"assign-",
	"unassign-",
	// Submission
	"submit-",
	"apply-",
	// Packaging
	"bundle-",
	// Confirmation
	"confirm-",
	// Other
	"add-",
	"write-",
];

// kubectl write subcommands (for specific error messages)
const KUBECTL_WRITE_OPS: Record<string, true> = {
	apply: true,
	create: true,
	delete: true,
	patch: true,
	edit: true,
	replace: true,
};

const KUBECTL_NODE_OPS: Record<string, true> = {
	drain: true,
	cordon: true,
	uncordon: true,
	taint: true,
};

interface BlockResult {
	block: true;
	reason: string;
}

export default function readonlyInfraHook(pi: ExtensionAPI): void {
	pi.on("tool_call", async (event) => {
		// ========== EVAL KERNEL BYPASS PROTECTION ==========
		if (event.toolName === "eval") {
			const input = event.input as { language?: string; code?: string };
			if (input.language === "py" && input.code) {
				const code = input.code;

				// Block boto3 usage (AWS SDK bypass)
				if (/import\s+boto3/.test(code) || /from\s+boto3\s+import/.test(code)) {
					return {
						block: true,
						reason: `Blocked: boto3 import in eval kernel is not permitted.\nUse aws CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block direct boto3 client/resource calls (in case already imported)
				if (/boto3\.(client|resource|Session)\s*\(/.test(code)) {
					return {
						block: true,
						reason: `Blocked: boto3 client/resource creation is not permitted.\nUse aws CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block kubernetes client usage
				if (/import\s+kubernetes/.test(code) || /from\s+kubernetes\s+import/.test(code)) {
					return {
						block: true,
						reason: `Blocked: kubernetes client import in eval kernel is not permitted.\nUse kubectl CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block kubernetes client API instantiation
				if (/client\.(CoreV1Api|AppsV1Api|BatchV1Api|NetworkingV1Api|RbacAuthorizationV1Api)\s*\(/.test(code)) {
					return {
						block: true,
						reason: `Blocked: kubernetes API client creation is not permitted.\nUse kubectl CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block config.load for kubernetes
				if (/config\.load_(kube_config|incluster_config)\s*\(/.test(code)) {
					return {
						block: true,
						reason: `Blocked: kubernetes config loading is not permitted.\nUse kubectl CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block AWS credential access via os.environ
				if (/os\.environ\s*\[\s*['"]AWS_(SECRET_ACCESS_KEY|SESSION_TOKEN|ACCESS_KEY_ID)['"]\s*\]/.test(code)) {
					return {
						block: true,
						reason: `Blocked: AWS credential access via os.environ is not permitted.`,
					} satisfies BlockResult;
				}

				// Block subprocess calls to aws/kubectl (bypass via subprocess)
				if (/subprocess\.(run|call|Popen|check_output)\s*\(\s*\[?\s*['"]?(aws|kubectl)/.test(code)) {
					return {
						block: true,
						reason: `Blocked: subprocess calls to aws/kubectl bypass the safety hook.\nUse the bash tool instead.`,
					} satisfies BlockResult;
				}
			}

			// JavaScript eval protection
			if (input.language === "js" && input.code) {
				const code = input.code;

				// Block AWS SDK imports
				if (/@aws-sdk\/client-/.test(code) || /require\s*\(\s*['"]@aws-sdk/.test(code)) {
					return {
						block: true,
						reason: `Blocked: AWS SDK import in eval kernel is not permitted.\nUse aws CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block AWS SDK client instantiation
				if (/new\s+(EKSClient|EC2Client|S3Client|IAMClient|STSClient|CloudWatchClient)\s*\(/.test(code)) {
					return {
						block: true,
						reason: `Blocked: AWS SDK client creation is not permitted.\nUse aws CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block kubernetes client imports
				if (/@kubernetes\/client-node/.test(code) || /require\s*\(\s*['"]@kubernetes\/client-node/.test(code)) {
					return {
						block: true,
						reason: `Blocked: kubernetes client import in eval kernel is not permitted.\nUse kubectl CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block kubernetes API instantiation
				if (/new\s+k8s\.(CoreV1Api|AppsV1Api|BatchV1Api|NetworkingV1Api)\s*\(/.test(code)) {
					return {
						block: true,
						reason: `Blocked: kubernetes API client creation is not permitted.\nUse kubectl CLI for allowed read operations.`,
					} satisfies BlockResult;
				}

				// Block AWS credential access via process.env
				if (/process\.env\.(AWS_SECRET_ACCESS_KEY|AWS_SESSION_TOKEN|AWS_ACCESS_KEY_ID)/.test(code)) {
					return {
						block: true,
						reason: `Blocked: AWS credential access via process.env is not permitted.`,
					} satisfies BlockResult;
				}

				// Block child_process/exec calls to aws/kubectl
				if (/exec(Sync)?\s*\(\s*['"`](aws|kubectl)/.test(code) || /spawn(Sync)?\s*\(\s*['"`](aws|kubectl)/.test(code)) {
					return {
						block: true,
						reason: `Blocked: child_process calls to aws/kubectl bypass the safety hook.\nUse the bash tool instead.`,
					} satisfies BlockResult;
				}

				// Block Bun shell with aws/kubectl
				if (/\$`(aws|kubectl)\s/.test(code) || /Bun\.spawn\s*\(\s*\[?\s*['"`](aws|kubectl)/.test(code)) {
					return {
						block: true,
						reason: `Blocked: Bun shell/spawn calls to aws/kubectl bypass the safety hook.\nUse the bash tool instead.`,
					} satisfies BlockResult;
				}
			}
			return; // Allow other eval calls
		}

		// Only intercept bash tool calls
		if (event.toolName !== "bash") return;

		const command = String((event.input as { command?: unknown }).command ?? "");
		if (!command.trim()) return;

		// ========== CHAINED COMMAND DETECTION ==========
		// Detect dangerous commands after ; && || before allowlist short-circuits
		if (/[\n;&|]\s*(kubectl\s+(delete|apply|exec|scale|edit|patch|drain|cordon|create|run))/.test(command)) {
			return {
				block: true,
				reason: `Blocked: Chained kubectl mutation command detected.\nRun commands separately.`,
			} satisfies BlockResult;
		}
		if (/[\n;&|]\s*(aws\s+iam)/.test(command) ||
			/[\n;&|]\s*(aws\s+[a-z0-9-]+\s+(delete-|terminate-|create-|modify-))/.test(command)) {
			return {
				block: true,
				reason: `Blocked: Chained AWS mutation command detected.\nRun commands separately.`,
			} satisfies BlockResult;
		}

		// ========== KUBECTL CHECKS ==========
		if (/kubectl\s/.test(command) || /^kubectl/.test(command)) {
			const match = command.match(/kubectl\s+([a-z-]+)/);
			if (match) {
				const subcommand = match[1];

				// Special handling for config
				if (subcommand === "config") {
					const configMatch = command.match(/kubectl\s+config\s+([a-z-]+)/);
					if (configMatch && !KUBECTL_CONFIG_ALLOWED[configMatch[1]]) {
						return {
							block: true,
							reason: `Blocked: kubectl config ${configMatch[1]} is not allowed.\nUse: kubectl config view, get-contexts, current-context`,
						} satisfies BlockResult;
					}
				}
				// Special handling for rollout - only status allowed
				else if (subcommand === "rollout") {
					if (!/rollout\s+status/.test(command)) {
						return {
							block: true,
							reason: `Blocked: kubectl rollout (except status) modifies workloads.\nUse: kubectl rollout status deployment/<name>`,
						} satisfies BlockResult;
					}
				}
				// Check allowlist
				else if (!KUBECTL_ALLOWED[subcommand]) {
					const alternatives = "kubectl get, kubectl describe, kubectl logs";

					if (subcommand === "exec") {
						return {
							block: true,
							reason: `Blocked: kubectl exec allows arbitrary code execution in containers.\nTo see container output, use: kubectl logs <pod> -n <namespace>`,
						} satisfies BlockResult;
					}

					if (KUBECTL_WRITE_OPS[subcommand]) {
						return {
							block: true,
							reason: `Blocked: kubectl ${subcommand} is a write operation.\nFor investigation, use: ${alternatives}`,
						} satisfies BlockResult;
					}

					if (subcommand === "scale") {
						return {
							block: true,
							reason: `Blocked: kubectl scale modifies replica count.\nTo check current state: kubectl describe deployment <name>`,
						} satisfies BlockResult;
					}

					if (KUBECTL_NODE_OPS[subcommand]) {
						return {
							block: true,
							reason: `Blocked: kubectl ${subcommand} modifies node state.\nTo investigate: kubectl describe node <name>`,
						} satisfies BlockResult;
					}

					return {
						block: true,
						reason: `Blocked: kubectl ${subcommand} is not in the allowed list.\nAllowed: get, describe, logs, top, version, cluster-info, api-resources`,
					} satisfies BlockResult;
				}
			}
		}

		// ========== AWS CLI CHECKS ==========
		if (/aws\s/.test(command) || /^aws/.test(command)) {
			const serviceMatch = command.match(/aws\s+([a-z0-9-]+)/);
			if (serviceMatch) {
				const service = serviceMatch[1];

				// Check blocked services
				if (AWS_BLOCKED_SERVICES[service]) {
					return {
						block: true,
						reason: `Blocked: aws ${service} operations are not permitted.\nThis agent has read-only infrastructure access.`,
					} satisfies BlockResult;
				}
			}

			// Check STS assume-role (privilege escalation)
			if (/aws\s+sts\s+assume-role/.test(command)) {
				return {
					block: true,
					reason: `Blocked: aws sts assume-role is not permitted (prevents privilege escalation).`,
				} satisfies BlockResult;
			}

			// S3 write operations
			if (/aws\s+s3\s+rm\s/.test(command)) {
				return {
					block: true,
					reason: `Blocked: aws s3 rm is not permitted.\nRead-only allowed: aws s3 ls, aws s3 cp s3://... -`,
				} satisfies BlockResult;
			}

			if (/aws\s+s3\s+mv\s/.test(command)) {
				return {
					block: true,
					reason: `Blocked: aws s3 mv is not permitted.`,
				} satisfies BlockResult;
			}

			// Block upload to S3 (cp TO s3://)
			if (/aws\s+s3\s+cp\s/.test(command)) {
				const argsMatch = command.match(/aws\s+s3\s+cp\s+(.+)/);
				if (argsMatch) {
					const args = argsMatch[1];
					// If first arg is NOT s3:// and s3:// appears later, it's an upload
					if (!/^s3:\/\//.test(args.trim()) && /\s+s3:\/\//.test(args)) {
						return {
							block: true,
							reason: `Blocked: aws s3 cp upload is not permitted.\nDownload allowed: aws s3 cp s3://bucket/key -`,
						} satisfies BlockResult;
					}
				}
			}

			if (/aws\s+s3\s+sync\s/.test(command) && !/aws\s+s3\s+sync\s+s3:\/\//.test(command)) {
				return {
					block: true,
					reason: `Blocked: aws s3 sync upload is not permitted.`,
				} satisfies BlockResult;
			}

			// s3api write operations
			if (/aws\s+s3api\s+(delete-|put-)/.test(command)) {
				return {
					block: true,
					reason: `Blocked: aws s3api write operations are not permitted.`,
				} satisfies BlockResult;
			}

			// Allow CloudWatch Logs Insights query operations (read-only despite start- prefix)
			if (/aws\s+logs\s+(start-query|stop-query|get-query-results)/.test(command)) {
				return; // Allow
			}

			// Check mutation verbs
			for (const verb of AWS_MUTATION_VERBS) {
				const pattern = new RegExp(`aws\\s+[a-z0-9-]+\\s+${verb.replace("-", "\\-")}`);
				if (pattern.test(command)) {
					const opMatch = command.match(/aws\s+([a-z0-9-]+)\s+([a-z0-9-]+)/);
					if (opMatch) {
						return {
							block: true,
							reason: `Blocked: aws ${opMatch[1]} ${opMatch[2]} is a mutating operation.\nRead-only operations like describe-*, list-*, get-* are allowed.`,
						} satisfies BlockResult;
					}
				}
			}
		}

		// ========== CREDENTIAL PROTECTION ==========
		const trimmed = command.trim();
		if (/^env$/.test(trimmed) || /^printenv/.test(trimmed) || /^export$/.test(trimmed)) {
			return {
				block: true,
				reason: `Blocked: Environment inspection is not permitted (protects credentials).`,
			} satisfies BlockResult;
		}

		if (/\/proc\/\d+\/environ/.test(command) || /\/proc\/self\/environ/.test(command)) {
			return {
				block: true,
				reason: `Blocked: Process environment inspection is not permitted.`,
			} satisfies BlockResult;
		}

		if (/echo.*\$AWS_SECRET/.test(command) || /echo.*\$\{AWS_SECRET/.test(command)) {
			return {
				block: true,
				reason: `Blocked: Credential inspection is not permitted.`,
			} satisfies BlockResult;
		}

		if (/echo.*\$AWS_SESSION_TOKEN/.test(command) || /echo.*\$\{AWS_SESSION_TOKEN/.test(command)) {
			return {
				block: true,
				reason: `Blocked: Credential inspection is not permitted.`,
			} satisfies BlockResult;
		}

		// ========== BYPASS PREVENTION ==========
		if (/python[3]?\s+.*boto3/i.test(command) || /python[3]?\s+-c.*import\s+boto/i.test(command)) {
			return {
				block: true,
				reason: `Blocked: Direct SDK access is not permitted.\nUse aws CLI for allowed read operations.`,
			} satisfies BlockResult;
		}

		if (/curl.*\.amazonaws\.com/.test(command) || /wget.*\.amazonaws\.com/.test(command)) {
			return {
				block: true,
				reason: `Blocked: Direct AWS API access is not permitted.\nUse aws CLI for allowed read operations.`,
			} satisfies BlockResult;
		}

		// ========== IAC TOOLS BLOCKING ==========
		if (/\b(terraform|pulumi|eksctl|helm)\s/.test(command)) {
			const match = command.match(/\b(terraform|pulumi|eksctl|helm)\s/);
			const tool = match ? match[1] : "IaC tool";
			return {
				block: true,
				reason: `Blocked: ${tool} is not permitted.\nThis agent has read-only infrastructure access.`,
			} satisfies BlockResult;
		}

		// ========== SHELL INDIRECTION BLOCKING ==========
		if (/\b(sh|bash)\s+-c\s/.test(command)) {
			// Check if the shell command contains dangerous operations
			if (/kubectl\s+(delete|apply|exec|scale|edit|patch)/.test(command) ||
				/aws\s+iam/.test(command) ||
				/aws\s+[a-z0-9-]+\s+(delete-|create-|terminate-)/.test(command)) {
				return {
					block: true,
					reason: `Blocked: Shell indirection with dangerous commands is not permitted.\nUse allowed commands directly.`,
				} satisfies BlockResult;
			}
		}

		// ========== EVAL BYPASS BLOCKING ==========
		if (/\beval\s/.test(command)) {
			if (/kubectl\s+(delete|apply|exec|scale|edit|patch)/.test(command) ||
				/aws\s+iam/.test(command) ||
				/aws\s+[a-z0-9-]+\s+(delete-|create-|terminate-)/.test(command)) {
				return {
					block: true,
					reason: `Blocked: eval with dangerous commands is not permitted.\nUse allowed commands directly.`,
				} satisfies BlockResult;
			}
		}

		// ========== XARGS/PIPE BYPASS BLOCKING ==========
		if (/xargs\s+(aws|kubectl)/.test(command) || /\|\s*(aws|kubectl)/.test(command)) {
			if (/(delete|terminate|create|modify|apply|exec|scale|iam)/.test(command)) {
				return {
					block: true,
					reason: `Blocked: Piping to dangerous aws/kubectl commands is not permitted.\nUse allowed commands directly.`,
				} satisfies BlockResult;
			}
		}

		// ========== COMMAND SUBSTITUTION BLOCKING ==========
		if (/\$\(/.test(command) || /`/.test(command) || /<\(/.test(command) || /<<</.test(command)) {
			if (/kubectl\s+(delete|apply|exec|scale)/.test(command) ||
				/aws\s+iam/.test(command) ||
				/(terminate-|delete-cluster|create-|modify-)/.test(command)) {
				return {
					block: true,
					reason: `Blocked: Command/process substitution with dangerous commands is not permitted.\nUse allowed commands directly.`,
				} satisfies BlockResult;
			}
		}

		// ========== ENVIRONMENT INSPECTION BLOCKING ==========
		if (/\bdeclare\s+-[^\s]*x/.test(command) || /\bexport\s+-p/.test(command)) {
			return {
				block: true,
				reason: `Blocked: Environment inspection is not permitted (protects credentials).`,
			} satisfies BlockResult;
		}

		// Command allowed
		return;
	});
}
