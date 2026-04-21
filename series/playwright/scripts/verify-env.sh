#!/usr/bin/env bash
# verify-env.sh — check all tools required for the Playwright series

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

echo ""
echo -e "${BOLD}  🎭 Playwright Series — Environment Check${NC}"
echo "  ══════════════════════════════════════════"
echo ""
echo -e "${YELLOW}  Runtime${NC}"
check "node"             node
check "npm"             npm
check "npx"             npx
echo ""
echo -e "${YELLOW}  Playwright${NC}"
check "playwright"      playwright
printf "  %-26s" "chromium browser"
if npx playwright --version &>/dev/null 2>&1; then
  printf "${GREEN}✅${NC}  via Playwright\n"; ((PASS++)) || true
else
  printf "${RED}❌${NC}\n"; ((FAIL++)) || true
fi
echo ""
echo -e "${YELLOW}  Test app server${NC}"
check "serve"           serve
echo ""
echo -e "${YELLOW}  Reporting${NC}"
check "allure"          allure
echo ""
echo "  ══════════════════════════════════════════"
if [ "$FAIL" -eq 0 ]; then
  echo -e "  ${GREEN}${BOLD}All tools present! ($PASS/$((PASS+FAIL)))${NC}"
  echo -e "  ${CYAN}Run 'npm test' to start. Happy testing! 🎭${NC}"
else
  echo -e "  ${RED}${BOLD}$FAIL tool(s) missing.${NC}"
  exit 1
fi
echo ""
