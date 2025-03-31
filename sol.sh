#!/bin/bash

BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)

echo "*********************************************"
echo "GitHub: https://github.com/ToanBm"
echo "X: https://x.com/buiminhtoan1985"
echo -e "\e[0m"

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

# Cài đặt Foundry nếu chưa có
if ! command -v forge &> /dev/null; then
    echo "🔧 Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    $HOME/.foundry/bin/foundryup  # Sử dụng đường dẫn tuyệt đối
    export PATH="$HOME/.foundry/bin:$PATH"
fi

# Kiểm tra lại Foundry
if ! command -v forge &> /dev/null; then
    echo "❌ Lỗi: Không tìm thấy forge sau khi cài đặt!"
    exit 1
fi

# Tiếp tục các lệnh khác...
echo "✅ Forge đã sẵn sàng: $(forge --version)"

# Create Solidity Contract
mkdir -p src
cat <<'EOF' > src/Contract.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract SimpleStorage {
    uint256 public storedData;
    event setEvent();

    function set(uint256 x) public {
        storedData = x;
        emit setEvent();
    }
}
EOF

# Create .env file securely
while [[ -z "$PRIVATE_KEY" ]]; do
    read -s -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY
    echo
done

print_command "Generating .env file..."
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Load environment variables from .env
source .env

# Configuration variables
RPC_URL="https://rpc.dev.gblend.xyz/"
CHAIN_ID=20993
CONTRACT_PATH="src/Contract.sol:SimpleStorage"
VERIFIER_URL="https://blockscout.dev.gblend.xyz/api/"

# Deploy contract
echo "Deploying contract..."
DEPLOY_OUTPUT=$(forge create $CONTRACT_PATH --private-key $PRIVATE_KEY --rpc-url $RPC_URL --broadcast)

# Extract contract address
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K0x[a-fA-F0-9]+')

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "❌ Error: Failed to deploy contract."
    exit 1
fi

echo "✅ Contract deployed at: $CONTRACT_ADDRESS"

# Verify contract
echo "Verifying contract..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --compiler-version 0.8.28 \
    $CONTRACT_ADDRESS \
    $CONTRACT_PATH \
    --verifier blockscout \
    --verifier-url $VERIFIER_URL

echo "✅ Contract verification completed!"
