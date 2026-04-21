#!/usr/bin/env bash
# verify-env.sh — checks all tools required for the eBPF series

set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0

check() {
  local name="$1"; local cmd="$2"; local flag="${3:---version}"
  printf "  %-26s" "$name"
  if command -v "$cmd" &>/dev/null; then
    local ver; ver=$("$cmd" "$flag" 2>&1 | head -n1)
    printf "${GREEN}✅${NC}  ${CYAN}%s${NC}\n" "$ver"
    ((PASS++)) || true
  else
    printf "${RED}❌  not found${NC}\n"; ((FAIL++)) || true
  fi
}

check_file() {
  local name="$1"; local path="$2"
  printf "  %-26s" "$name"
  if [ -e "$path" ]; then
    printf "${GREEN}✅${NC}  %s\n" "$path"
    ((PASS++)) || true
  else
    printf "${RED}❌  missing: %s${NC}\n" "$path"; ((FAIL++)) || true
  fi
}

check_kernel() {
  printf "  %-26s" "kernel version"
  local ver; ver=$(uname -r)
  local major; major=$(echo "$ver" | cut -d. -f1)
  local minor; minor=$(echo "$ver" | cut -d. -f2)
  if [ "$major" -gt 5 ] || ([ "$major" -eq 5 ] && [ "$minor" -ge 13 ]); then
    printf "${GREEN}✅${NC}  ${CYAN}%s${NC} (≥5.13 required for BTF+CO-RE)\n" "$ver"
    ((PASS++)) || true
  else
    printf "${YELLOW}⚠️   %s${NC} — some features need kernel ≥5.13\n" "$ver"
    ((PASS++)) || true
  fi
}

echo ""
echo -e "${BOLD}  🐝 eBPF Series — Environment Check${NC}"
echo "  ════════════════════════════════════"
echo ""
echo -e "${YELLOW}  Go toolchain${NC}"
check "go"                go
check "bpf2go"            bpf2go  --help
echo ""
echo -e "${YELLOW}  eBPF C compiler${NC}"
check "clang"             clang
check "llc"               llc
check "llvm-strip"        llvm-strip
echo ""
echo -e "${YELLOW}  eBPF introspection${NC}"
check "bpftool"           bpftool version
check "bpftrace"          bpftrace --version     # optional
check_kernel
echo ""
echo -e "${YELLOW}  Libraries & headers${NC}"
check_file "libbpf"       "/usr/lib/x86_64-linux-gnu/libbpf.so.1" 2>/dev/null || \
check_file "libbpf (arm)" "/usr/lib/aarch64-linux-gnu/libbpf.so.1"
check_file "linux headers" "/usr/include/linux/bpf.h"
check_file "vmlinux BTF"  "/sys/kernel/btf/vmlinux"
echo ""
echo -e "${YELLOW}  Privileged access${NC}"
check_file "debugfs"      "/sys/kernel/debug/tracing"
check_file "bpffs"        "/sys/fs/bpf"
echo ""
echo "  ════════════════════════════════════"
if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}All tools present! ($PASS/$((PASS+FAIL)))${NC}"
  echo -e "  ${CYAN}You're ready for Lesson 01. Let's trace the kernel! 🐝${NC}"
else
  echo -e "  ${RED}${BOLD}$FAIL check(s) failed.${NC}"
  echo -e "  ${YELLOW}Re-open the Dev Container or check required capabilities.${NC}"
  exit 1
fi
echo ""
