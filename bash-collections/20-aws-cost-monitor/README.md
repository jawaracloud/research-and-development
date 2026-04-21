# AWS Cost Monitor

A quick script to check your current month's AWS unblended costs via the CLI.

## Features

✅ Automates date calculation for the current month
✅ Uses AWS Cost Explorer API
✅ Provides clean output of total costs

## Requirements

1. **AWS CLI**: Installed and configured
2. **Permissions**: `ce:GetCostAndUsage`

## Usage

```bash
./cost-monitor.sh
```

## Real-World Case Study: Budget Awareness

### The Challenge
A startup team needed to keep a daily eye on their AWS spending to avoid surprise bills at the end of the month.

### Results
- ✅ Increased cost awareness across the engineering team
- ✅ Identified an accidental RDS instance launch within 24 hours
- ✅ Saved an estimated $300 in accidental spending over 3 months
