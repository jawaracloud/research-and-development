# Git Clean Branches

A bash script designed to: **Delete completely merged git branches to clear space.**

## Usage

```bash
./git-clean-branches.sh
```

## Command Implementation

```bash
git branch --merged | grep -v '\*' | xargs -n 1 git branch -d
```
