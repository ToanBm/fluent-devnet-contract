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
gblend

print_command "Installing dependencies (may take 2-3 mins)..."
npm install
npm install dotenv

## Hardhat Configs
print_command "Updating hardhat.config.js..."
rm hardhat.config.js

cat <<EOF > hardhat.config.js
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-vyper");
require("dotenv").config();

module.exports = {
  defaultNetwork: "fluent_devnet1", // Set fluent_devnet1 as the default network
  networks: {
    fluent_devnet1: {
      url: 'https://rpc.dev.thefluent.xyz/',
      chainId: 20993,
      accounts: [`0x${process.env.PRIVATE_KEY}`], // Load private key from .env
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

sleep 5

print_command "Compiling contract..."
npm run compile

## Deploying the Solidity contract
rm scripts/deploy.js
cat <<EOF > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    const Token = await ethers.getContractFactory("Hello");
    const token = await Token.deploy();

    // Access the address property directly
    console.log("Token address:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
EOF

# "Waiting before deploying..."
sleep 5

## To deploy the compiled solidity smart contract, run:
print_command "Deploying smart contracts..."
npm run deploy





