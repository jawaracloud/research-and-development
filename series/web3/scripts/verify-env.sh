#!/usr/bin/env bash
# verify-env.sh — checks all tools required for the Web3 series

set -euo pipefail
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
PASS=0; FAIL=0

export PATH=$PATH:/usr/local/go/bin:/go/bin:~/.cargo/bin:~/.foundry/bin:~/.local/share/solana/install/active_release/bin

check() {
  local name="$1"; local cmd="$2"; local flag="${3:---version}"
  printf "  %-24s" "$name"
  if command -v "$cmd" &>/dev/null; then
    local ver; ver=$("$cmd" "$flag" 2>&1 | head -n1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9a-zA-Z+-]+' | head -1 || echo "installed")
    printf "${GREEN}✅${NC}  ${CYAN}%s${NC}\n" "$ver"
    ((PASS++)) || true
  else
    printf "${RED}❌  not found${NC}\n"; ((FAIL++)) || true
  fi
}

echo ""
echo -e "${BOLD}  🌐 Web3 Series (Go + Rust) — Environment Check${NC}"
echo "  ══════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}  Core Languages${NC}"
check "Go"                go
check "Rust"              rustc
check "Cargo"             cargo
check "Node.js"           node
echo ""
echo -e "${YELLOW}  Ethereum (EVM) Tooling${NC}"
check "Forge (Foundry)"     forge
check "Cast (Foundry)"      cast
check "Anvil (Foundry)"     anvil
echo ""
echo -e "${YELLOW}  Solana Tooling${NC}"
check "Solana CLI"        solana
check "Anchor CLI"        anchor
echo ""
echo -e "${YELLOW}  Storage Tooling${NC}"
check "IPFS (Kubo)"       ipfs
echo ""
echo "  ══════════════════════════════════════════════"
if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}All tools present! ($PASS/$((PASS+FAIL)))${NC}"
  echo -e "  ${CYAN}You're ready for Lesson 01. Let's build Web3! 🚀${NC}"
else
  echo -e "  ${RED}${BOLD}$FAIL check(s) failed.${NC}"
  echo -e "  ${YELLOW}Verify paths in standard shell. If inside dev container, rebuild.${NC}"
  exit 1
fi
echo ""
