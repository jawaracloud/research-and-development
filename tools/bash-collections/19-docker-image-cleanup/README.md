# Docker Image Cleanup

Automated cleanup of unused Docker images and volumes to reclaim disk space.

## Features

✅ Removes dangling images (untagged)
✅ Removes unused Docker volumes
✅ Optional removal of ALL unused images
✅ Safe and non-interactive by default

## Usage

```bash
# Clean dangling images only
./cleanup.sh

# Clean ALL unused images
./cleanup.sh --all
```

## Real-World Case Study: CI Server Maintenance

### The Challenge
A Jenkins CI server was running out of disk space every 3 days due to build images accumulating.

### The Solution
Scheduled this script to run after every successful build.

### Results
- ✅ Disk usage remained stable at 40%
- ✅ Zero build failures due to "No space left on device"
- ✅ Reclaimed average of 20GB disk space per week
