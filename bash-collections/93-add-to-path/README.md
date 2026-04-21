# Add To Path

A bash script designed to: **Add the target directory permanently to .bashrc PATH.**

## Usage

```bash
./add-to-path.sh
```

## Command Implementation

```bash
echo "export PATH=\$PATH:$(readlink -f "$1")" >> ~/.bashrc
```
