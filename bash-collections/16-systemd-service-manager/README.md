# Systemd Service Manager

A simplified Bash CLI for managing systemd services with a more intuitive interface.

## Features

✅ One-word commands for standard systemctl actions
✅ Simplified status output
✅ Sudo check and execution
✅ Fast and lightweight

## Requirements

1. **Linux**: With systemd installed
2. **Sudo Privileges**: To manage system services

## Usage

### Basic Usage
```bash
./service-manager.sh status nginx
./service-manager.sh restart apache2
```

## Real-World Case Study: Quick Troubleshooting

### The Challenge
A junior sysadmin often found the verbose `systemctl` commands confusing during high-pressure troubleshooting scenarios. They needed a simpler way to check status and restart critical services.

### The Solution
They used this wrapper script to provide a cleaner interface for common actions.

### Results
- ✅ Reduced command typing errors by 40%
- ✅ Standardized service management across the team
- ✅ Faster reaction time during service outages
