#!/bin/bash

BOLD=$(tput bold)
RESET=$(tput sgr0)
YELLOW=$(tput setaf 3)
# Logo

echo     "*********************************************"
echo     "Githuh: https://github.com/ToanBm"
echo     "X: https://x.com/buiminhtoan1985"
echo -e "\e[0m"

print_command() {
  echo -e "${BOLD}${YELLOW}$1${RESET}"
}

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

export PATH="$HOME/.foundry/bin:$PATH"
echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

foundryup

# Install dot env
npm install dotenv

# Start Foundry Project
forge init 

# Start Solidity Contract
cat <<'EOF' > src/Contract.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

contract SimpleStorage {

    uint256 public storedData; //Do not set 0 manually it wastes gas!

    event setEvent();
    
    function set(uint256 x) public {
        storedData = x;
        emit setEvent();
    }

}
EOF

## Crear .env file
read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY

print_command "Generating .env file..."
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

# Load environment variables from the .env file
source .env

# Configuration variables
RPC_URL="https://rpc.dev.gblend.xyz/"
CHAIN_ID=20993
CONTRACT_PATH="src/Contract.sol:SimpleStorage"
VERIFIER_URL="https://blockscout.dev.gblend.xyz/api/"

# Deploy the smart contract
echo "Deploying contract..."
DEPLOY_OUTPUT=$(forge create $CONTRACT_PATH --private-key $PRIVATE_KEY --rpc-url $RPC_URL --broadcast)

# Extract the deployed contract address from the output
CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K0x[a-fA-F0-9]+')

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Error: Failed to retrieve the contract address from the output."
    exit 1
fi

echo "Contract deployed at: $CONTRACT_ADDRESS"

# Verify the deployed contract
echo "Verifying contract..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --compiler-version 0.8.28 \
    $CONTRACT_ADDRESS \
    $CONTRACT_PATH \
    --verifier blockscout \
    --verifier-url $VERIFIER_URL

echo "✅ Contract verification completed!"













