# Bash Collections

This repository contains a curated collection of specialized Bash scripts designed for DevOps, cloud infrastructure, and system administration workflows.

These tools are built to run natively on Unix-like operating systems, leveraging standard CLI utilities to automate routine tasks securely and efficiently.

---

## Tutorials (Getting Started)

If you are new to this repository, here is how you can start using these scripts immediately.

### Executing a Script
1. Navigate to the specific directory of the script you want to use.
2. Read the accompanying `README.md` in that directory to understand its specific requirements and parameters.
3. Make the script executable:
   ```bash
   chmod +x <script-name>.sh
   ```
4. Run the script:
   ```bash
   ./<script-name>.sh
   ```

Each script is heavily commented and acts autonomously, handling its own errors and output logging.

---

## How-To Guides (Task-Oriented)

The scripts are organized into specific use cases. Depending on your current task, navigate to the relevant directory:

### Securing & Monitoring Systems
*   **06-basic-ufw-rules/** - Configure and enforce basic UFW firewall rules.
*   **07-simple-ssh-monitor/** - Monitor SSH logs to detect brute-force attempts and blacklist IPs.
*   **08-certificate-expiration-monitor/** - Monitor SSL certificate expiration dates and trigger alerts.
*   **17-nginx-log-analyzer/** - Parse and analyze Nginx access logs for traffic anomalies.
*   **18-disk-space-alert/** - Setup threshold-based alerts for disk usage exhaustion.

### Managing Cloud & Infrastructure
*   **09-sync-ecr-between-account-or-profile/** - Synchronize AWS ECR repositories across different AWS accounts.
*   **11-cleanup-aws/** - Execute a destructive cleanup of unused AWS resources.
*   **12-aws-s3-backup/** - Push local backups to AWS S3 using AES-256 encryption.
*   **20-aws-cost-monitor/** - Fetch and monitor daily unblended AWS costs via the CLI.

### Orchestrating Kubernetes
*   **10-export-kube-yaml-manifest/** - Export active Kubernetes cluster resources into local YAML manifests.
*   **14-k8s-pod-restart/** - Gracefully restart pod workloads using label selectors.
*   **22-k8s-namespace-cleaner/** - Clean up stale resources (failed pods, old ReplicaSets) inside specific namespaces.

### Handling Containers & Docker
*   **05-install-docker-ubuntu/** - Fully automate the installation of Docker on an Ubuntu host.
*   **13-docker-logs-rotate/** - Rotate and truncate Docker container logs automatically to save disk space.
*   **19-docker-image-cleanup/** - Prune and automate the cleanup of dangling Docker images and volumes.
*   **25-docker-compose-healthcheck/** - Monitor Docker Compose services dynamically based on timeout configurations.

### Database Administration
*   **15-postgres-backup/** - Generate compressed and automated backups of PostgreSQL databases.
*   **24-database-connection-tester/** - Rapidly test TCP/authentication connectivity against Postgres, MySQL, Redis, and MongoDB.

### Networking Utilities
*   **02-find-subdomains/** - Discover subdomains publicly indexed via the crt.sh certificate transparency logs.
*   **03-socat/** - Manage complex network routing and port forwarding using Socat.
*   **04-network-namespace/** - Isolate and manage Linux network namespaces.
*   **21-logs-shipper/** - Ship local logs to remote servers securely via SCP.

### Working with Files & Git
*   **01-rename-file-with-same-patern/** - Apply pattern-matching logic to bulk rename specific files.
*   **23-git-repo-syncer/** - Batch synchronize tracking branches across multiple git repositories simultaneously.

### The 100 Obscure Scripts Collection
From `26-empty-trash` through `125-run-until-fail`, this repository also includes 100 highly specialized, single-file bash scripts for nuanced edge cases (e.g., fast sub-netping, native stopwatch loops, isolated random password generators).
Please refer to the specific script foldering from `26` to `125` for highly atomic utility commands.

---

## Reference

Every script within this repository adheres to a strict design pattern to ensure predictability:

*   **Self-Contained:** Scripts do not rely on complex external dependencies outside of standard POSIX tools (`jq`, `curl`, `awk`, `sed`) or the specific cloud CLI they interact with (`aws`, `kubectl`, `docker`).
*   **Configuration via Variables:** Core parameters (like thresholds, target namespaces, or AWS regions) are defined clearly as variables at the top of the script files.
*   **Error Handling:** Implementation of `set -eo pipefail` is standard to prevent cascading failures during execution.

---

## Explanation (Design Principles)

This collection was built on the philosophy that complex infrastructure automation does not always require high-overhead orchestration tools. Often, a well-written, natively executed Bash script provides the fastest resolution to an outage or a repetitive task. 

By utilizing the native UNIX capabilities (e.g., pipelines, text processing, network sockets), these scripts aim to reduce cognitive load for operators while providing maximum cross-system compatibility.

### Contribution

To contribute to this collection:
1. Ensure your script follows the single-responsibility principle.
2. Provide a dedicated directory prefixed chronologically (e.g., `126-new-script/`).
3. Include a detailed `README.md` following the Diataxis framework within the folder.
4. Submit a Pull Request.

Contributions expanding on native operations or covering new infrastructure tools are highly welcome.
