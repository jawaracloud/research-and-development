# Git Update All

A bash script designed to: **Update ALL internal git repositories within current directory.**

## Usage

```bash
./git-update-all.sh
```

## Command Implementation

```bash
find . -type d -name .git -execdir git pull origin HEAD \;
```
