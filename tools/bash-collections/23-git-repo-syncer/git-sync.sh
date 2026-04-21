#!/bin/bash
# Git Repository Syncer: Batch update multiple git repositories
#
# Requirements:
#   - git installed
#   - SSH keys configured for remote access (if using SSH URLs)
#
# Usage:
#   ./git-sync.sh <root-directory> [options]
#   ./git-sync.sh ~/projects --pull
#   ./git-sync.sh ~/projects --status

set -e

# Configuration
ROOT_DIR="${1:-.}"
ACTION="${2:-status}" # status, pull, fetch

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ ! -d "$ROOT_DIR" ]; then
    echo -e "${RED}Error: Directory $ROOT_DIR does not exist.${NC}"
    exit 1
fi

echo -e "${BLUE}Scanning for git repositories in: $ROOT_DIR${NC}"
echo "================================================"

find "$ROOT_DIR" -type d -name ".git" | sort | while read gitdir; do
    repo_dir=$(dirname "$gitdir")
    repo_name=$(basename "$repo_dir")
    
    echo -e "\n${YELLOW}Repository: $repo_name${NC} ($repo_dir)"
    
    cd "$repo_dir"
    
    # Get current branch
    branch=$(git rev-parse --abbrev-ref HEAD)
    echo -e "  Branch: ${GREEN}$branch${NC}"
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        echo -e "  Status: ${RED}Uncommitted changes${NC}"
    else
        echo -e "  Status: ${GREEN}Clean${NC}"
    fi
    
    case "$ACTION" in
        --pull)
            echo "  Action: Pulling updates..."
            if git pull --rebase; then
                echo -e "  Result: ${GREEN}Success${NC}"
            else
                echo -e "  Result: ${RED}Failed${NC}"
            fi
            ;;
        --fetch)
            echo "  Action: Fetching..."
            git fetch
            echo -e "  Result: ${GREEN}Fetched${NC}"
            ;;
        --status|*)
            # Check for incoming/outgoing commits
            git fetch -q
            local_hash=$(git rev-parse @)
            remote_hash=$(git rev-parse @{u} 2>/dev/null || echo "none")
            base_hash=$(git merge-base @ @{u} 2>/dev/null || echo "none")
            
            if [ "$remote_hash" == "none" ]; then
                echo -e "  Remote: ${YELLOW}No upstream configured${NC}"
            elif [ "$local_hash" = "$remote_hash" ]; then
                echo -e "  Remote: ${GREEN}Up to date${NC}"
            elif [ "$local_hash" = "$base_hash" ]; then
                echo -e "  Remote: ${YELLOW}Need to pull${NC}"
            elif [ "$remote_hash" = "$base_hash" ]; then
                echo -e "  Remote: ${BLUE}Need to push${NC}"
            else
                echo -e "  Remote: ${RED}Diverged${NC}"
            fi
            ;;
    esac
done

echo -e "\n================================================"
echo -e "${GREEN}Done!${NC}"
