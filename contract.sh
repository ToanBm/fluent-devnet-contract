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

## Install Fluent scaffold CLI tool
print_command "Installing Cargo..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

print_command "Installing gblend tool..."
cargo install gblend

print_command "Choose your setup: Hardhat JavaScript (Solidity & Vyper)"
gblend init

print_command "Installing dependencies (may take 2-3 mins)..."
npm install
npm install dotenv

## Hardhat Configs
print_command "Updating hardhat.config.js..."
rm hardhat.config.js

cat <<'EOF' > hardhat.config.js
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-vyper");
require("dotenv").config();

module.exports = {
  defaultNetwork: "fluent_devnet1", // Set fluent_devnet1 as the default network
  networks: {
    fluent_devnet1: {
      url: 'https://rpc.dev.gblend.xyz/',
      chainId: 20993,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
  },
  solidity: {
    version: '0.8.19',
  },
  vyper: {
    version: "0.3.0",
  },
};
EOF

## Crear .env file
read -p "Enter your EVM wallet private key (without 0x): " PRIVATE_KEY

print_command "Generating .env file..."
cat <<EOF > .env
PRIVATE_KEY=$PRIVATE_KEY
EOF

## Compiling the Smart Contract
rm contracts/hello.sol
cat <<EOF > contracts/hello.sol
// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.0;
    contract Hello {
        function main() public pure returns (string memory) {
            return "Hello, Solidity!";
        }
    }
EOF

print_command "Compiling contract..."
npm run compile

## Deploying the Solidity contract
rm scripts/deploy-solidity.js
cat <<EOF > scripts/deploy-solidity.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();

  console.log("Deploying contract...");
  console.log("Chain ID:", network.chainId);
  console.log("Deployer address:", deployer.address);
  console.log(
    "Deployer balance:",
    ethers.utils.formatEther(await deployer.getBalance()),
    "ETH"
  );

  const ContractFactory = await ethers.getContractFactory("Hello");
  const contract = await ContractFactory.deploy();

  // Access the address property directly
  console.log("Contract address:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOF

# "Waiting before deploying..."
sleep 3

# Yêu cầu nhập số lượng contract cần deploy
read -p "Enter the number of contracts to deploy: " NUMBER_OF_CONTRACTS

# Kiểm tra số lượng có phải là số hợp lệ không
if ! [[ "$NUMBER_OF_CONTRACTS" =~ ^[0-9]+$ ]]; then
  echo "Invalid input. Please enter a valid number."
  exit 1
fi

# Lặp lệnh deploy
for ((i=1; i<=NUMBER_OF_CONTRACTS; i++)); do
  print_command "Deploying contract #$i..."
  npx hardhat run scripts/deploy-solidity.js --network fluent_devnet1

  # Thời gian chờ ngẫu nhiên từ 3 đến 7 giây
  RANDOM_DELAY=$(shuf -i 3-7 -n 1)  # Chọn số ngẫu nhiên từ 3 đến 7
  echo "Waiting for $RANDOM_DELAY seconds before next deploy..."
  sleep $RANDOM_DELAY
done

print_command "Successfully deployed $NUMBER_OF_CONTRACTS smart contracts!"

