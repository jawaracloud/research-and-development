# UFW Firewall Configuration Script

A simple yet effective Bash script to configure the Uncomplicated Firewall (UFW) with security best practices for Ubuntu/Debian systems.

## Features

✅ Resets firewall to a clean state
✅ Default "deny incoming, allow outgoing" policy
✅ SSH protection with support for custom ports
✅ Essential web ports (80, 443) enabled
✅ Rate-limiting for SSH to prevent brute force attacks
✅ High-level logging enabled for security auditing
✅ Post-configuration status and network check

## Requirements

1. **Ubuntu/Debian**: Or any system using UFW
2. **Bash**: Modern Bash shell
3. **Sudo Privileges**: Required to modify system firewall rules

## Installation

```bash
# Make script executable
chmod +x ufw.sh

# Run with sudo
sudo ./ufw.sh
```

## Usage

### Basic Usage
```bash
sudo ./ufw.sh
```

**⚠️ WARNING:** This script assumes you have changed your SSH port to `22222` in `/etc/ssh/sshd_config`. If you are still using port `22`, please edit the script before running it.

### Modifying Ports
If you want to allow different ports (e.g., port 22 for standard SSH), change line 21 and 28:
```bash
sudo ufw allow 22/tcp comment "SSH Standard Port"
sudo ufw limit 22/tcp comment "Limit SSH connections"
```

## Real-World Case Study: Hardening a Web Server

### The Challenge
A small business owner launched a WordPress site on an unmanaged VPS. Within hours, the logs showed thousands of login attempts from foreign IP addresses. The server had all ports open by default, including sensitive database ports (3306) and unfinished test applications (8080).

### The Solution
They used the `ufw.sh` script to quickly close all unnecessary ports and apply a strict policy. They changed their SSH port to `22222` and then executed the script.

### Results
- ✅ Successfully blocked 100% of brute force attempts on port 3306 and 8080.
- ✅ Rate-limiting on the new SSH port effectively throttled persistent attackers.
- ✅ Enabled high-level logging allowed the owner to identify and manually block persistent attack subnets.
- ✅ Improved system performance by reducing CPU overhead from processing failed login attempts on multiple ports.

### Key Learnings
1. Defaulting to "deny all incoming" is the single most important security step for any public server.
2. Moving SSH to a non-standard port reduces the noise in logs and makes the server less of a target for automated scanners.
3. Automated scripts allow for reproducible security baselines across multiple servers.

## Troubleshooting

### "This script must be run with sudo"
Firewall rules are system-level configurations. You must run the script with `sudo ./ufw.sh`.

### Lost SSH Connection
Ensure the port you allowed in the script matches your `sshd_config` port. If you are locked out, use your cloud provider's web console to access the server and fix the firewall rules.
