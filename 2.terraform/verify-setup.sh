#!/bin/bash
# K3s Cluster Setup Verification Script
# This script verifies all prerequisites before running Terraform

set -e

echo "🔍 K3s Cluster Setup Verification"
echo "=================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    EXIT_CODE=1
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

EXIT_CODE=0

# 1. Check Terraform installation
echo "1. Checking Terraform..."
if command -v terraform &> /dev/null; then
    TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
    check_pass "Terraform installed (version: $TERRAFORM_VERSION)"
else
    check_fail "Terraform not found. Install from: https://www.terraform.io/downloads"
fi
echo ""

# 2. Check Proxmox connectivity
echo "2. Checking Proxmox connectivity..."
PROXMOX_URL="https://10.10.10.200:8006"
if curl -k -s "$PROXMOX_URL" > /dev/null; then
    check_pass "Proxmox API accessible at $PROXMOX_URL"
else
    check_fail "Cannot reach Proxmox at $PROXMOX_URL"
fi
echo ""

# 3. Check Consul connectivity
echo "3. Checking Consul state backend..."
CONSUL_URL="http://10.10.10.15:8500"
if curl -s "$CONSUL_URL/v1/status/leader" > /dev/null; then
    LEADER=$(curl -s "$CONSUL_URL/v1/status/leader")
    check_pass "Consul accessible at $CONSUL_URL (leader: $LEADER)"
else
    check_fail "Cannot reach Consul at $CONSUL_URL"
fi
echo ""

# 4. Check SSH key
echo "4. Checking SSH key..."
if [ -f "keys/public-key.pub" ]; then
    KEY_TYPE=$(head -1 keys/public-key.pub | awk '{print $1}')
    check_pass "SSH public key found (type: $KEY_TYPE)"
else
    check_warn "SSH key not found at keys/public-key.pub"
    echo "   Run: mkdir -p keys && cp ~/.ssh/id_rsa.pub keys/public-key.pub"
fi
echo ""

# 5. Check terraform.tfvars
echo "5. Checking configuration files..."
if [ -f "terraform.tfvars" ]; then
    check_pass "terraform.tfvars exists"
    
    # Check if it contains placeholder values
    if grep -q "YOUR-TOKEN-HERE" terraform.tfvars 2>/dev/null; then
        check_warn "terraform.tfvars contains placeholder values - update with real values"
    fi
else
    check_warn "terraform.tfvars not found"
    echo "   Run: cp terraform.tfvars.example terraform.tfvars"
fi
echo ""

# 6. Check network availability
echo "6. Checking network configuration..."
if ping -c 1 -W 1 10.10.10.1 &> /dev/null; then
    check_pass "Gateway 10.10.10.1 is reachable"
else
    check_warn "Gateway 10.10.10.1 not responding"
fi
echo ""

# 7. Check if VMs already exist
echo "7. Checking for existing VMs..."
if [ -f ".terraform/terraform.tfstate" ] || [ -f "terraform.tfstate" ]; then
    check_warn "Terraform state exists - VMs may already be deployed"
    echo "   Run: terraform state list"
else
    check_pass "No local state found - ready for new deployment"
fi
echo ""

# Summary
echo "=================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. terraform init"
    echo "  2. terraform plan"
    echo "  3. terraform apply"
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo "Please fix the issues above before running terraform"
fi
echo ""

exit $EXIT_CODE
