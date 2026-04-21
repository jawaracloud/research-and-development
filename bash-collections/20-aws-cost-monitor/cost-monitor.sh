#!/bin/bash
# AWS Cost Monitor: Get daily unblended cost for the current month
#
# Requirements:
#   - awscli installed and configured
#
# Usage:
#   ./cost-monitor.sh

set -e

START_DATE=$(date +%Y-%m-01)
END_DATE=$(date +%Y-%m-%d)

echo "AWS Unblended Costs from $START_DATE to $END_DATE"
echo "------------------------------------------------"

aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$END_DATE \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost'
