# Note

A bash script designed to: **Rapid log timestamp notes without editor GUI.**

## Usage

```bash
./note.sh
```

## Command Implementation

```bash
echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >> ~/NOTES.txt
```
