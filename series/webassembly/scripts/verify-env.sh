#!/usr/bin/env bash
# verify-env.sh — checks that all tools required for the WebAssembly series are installed.
# Run automatically on container/shell start, or manually at any time.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

check() {
  local name="$1"
  local cmd="$2"
  local version_flag="${3:---version}"

  printf "  %-22s" "$name"

  if command -v "$cmd" &>/dev/null; then
    local ver
    ver=$("$cmd" "$version_flag" 2>&1 | head -n1 | sed 's/^[[:space:]]*//')
    printf "${GREEN}✅${NC}  ${CYAN}%s${NC}\n" "$ver"
    ((PASS++)) || true
  else
    printf "${RED}❌  not found${NC}\n"
    ((FAIL++)) || true
  fi
}

check_cargo() {
  local name="$1"
  local subcmd="$2"

  printf "  %-22s" "$name"

  if cargo "$subcmd" --version &>/dev/null 2>&1; then
    local ver
    ver=$(cargo "$subcmd" --version 2>&1 | head -n1)
    printf "${GREEN}✅${NC}  ${CYAN}%s${NC}\n" "$ver"
    ((PASS++)) || true
  else
    printf "${RED}❌  not found${NC}  (run: cargo install %s --locked)\n" "$subcmd"
    ((FAIL++)) || true
  fi
}

echo ""
echo -e "${BOLD}  🦀 WebAssembly Series — Environment Check${NC}"
echo "  ════════════════════════════════════════════"
echo ""
echo -e "${YELLOW}  Core Rust toolchain${NC}"
check       "rustc"              rustc
check       "cargo"              cargo
check       "rustup"             rustup
echo ""
echo -e "${YELLOW}  Wasm targets${NC}"
printf "  %-22s" "wasm32-unknown-unknown"
if rustup target list --installed 2>/dev/null | grep -q "wasm32-unknown-unknown"; then
  printf "${GREEN}✅${NC}  installed\n"
  ((PASS++)) || true
else
  printf "${RED}❌${NC}  missing — run: rustup target add wasm32-unknown-unknown\n"
  ((FAIL++)) || true
fi
echo ""
echo -e "${YELLOW}  Build tools${NC}"
check       "wasm-pack"          wasm-pack
check       "wasm-bindgen"       wasm-bindgen
check       "trunk"              trunk
check_cargo "cargo-leptos"       leptos
check_cargo "cargo-generate"     generate
check_cargo "cargo-watch"        watch
check_cargo "cargo-expand"       expand
check_cargo "cargo-nextest"      nextest
echo ""
echo -e "${YELLOW}  Optimization / inspection${NC}"
check       "wasm-opt"           wasm-opt
check       "wasm2wat"           wasm2wat
check_cargo "twiggy"             twiggy -- help &>/dev/null 2>&1
echo ""
echo -e "${YELLOW}  Database (lessons 75+)${NC}"
check_cargo "sqlx-cli"           sqlx
echo ""
echo -e "${YELLOW}  Node.js ecosystem (lessons 83, 96)${NC}"
check       "node"               node
check       "npm"                npm
printf "  %-22s" "playwright"
if npx --yes playwright --version &>/dev/null 2>&1; then
  ver=$(npx playwright --version 2>&1 | head -n1)
  printf "${GREEN}✅${NC}  ${CYAN}%s${NC}\n" "$ver"
  ((PASS++)) || true
else
  printf "${YELLOW}⚠️   not installed${NC}  (run: npx playwright install)\n"
fi
echo ""
echo "  ════════════════════════════════════════════"

if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}All tools present! ($PASS/$((PASS+FAIL)))${NC}"
  echo -e "  ${CYAN}You're ready to start Lesson 01. Happy learning! 🚀${NC}"
else
  echo -e "  ${RED}${BOLD}$FAIL tool(s) missing ($PASS/$((PASS+FAIL)) passed).${NC}"
  echo -e "  ${YELLOW}Re-open the Dev Container or run the setup commands shown above.${NC}"
  exit 1
fi
echo ""
