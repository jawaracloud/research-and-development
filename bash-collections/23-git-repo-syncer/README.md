# Git Repository Syncer

A productivity tool for developers managing multiple Git repositories. It scans a directory tree for git repos and performs batch operations.

## Features

✅ Recursive scanning of subdirectories
✅ Batch status check (uncommitted changes, ahead/behind)
✅ Batch pull/rebase
✅ Batch fetch
✅ Color-coded output for quick readability

## Requirements

1. **git**: Installed and configured
2. **Bash**: Modern Bash shell

## Installation

```bash
# Make script executable
chmod +x git-sync.sh
```

## Usage

### Check Status of All Repos
```bash
./git-sync.sh ~/projects
```

### Pull All Repos
```bash
./git-sync.sh ~/projects --pull
```

### Fetch All Repos
```bash
./git-sync.sh ~/projects --fetch
```

## Real-World Case Study: Microservices Development

### The Challenge
A developer working on a platform with 15 microservices needed to ensure all local repositories were up to date before starting a cross-cutting feature implementation. Manually checking each directory took ~10 minutes every morning.

### The Solution
They used `git-sync.sh` to update all 15 repos in one command:

```bash
./git-sync.sh ~/work/microservices --pull
```

### Results
- ✅ Daily synchronization time reduced from 10 minutes to 30 seconds
- ✅ Eliminated merge conflicts caused by working on stale branches
- ✅ Immediate visibility into forgotten uncommitted changes across projects
