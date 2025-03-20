# Tokenizer - Fungible Token Project Documentation

## Overview

**Project Name:** Tokenizer  
**Blockchain:** Ethereum  
**Token Standard:** ERC-20  
**Purpose:** Tokenizer is a project focused on implementing a fungible token using a blockchain platform. Fungible tokens are digital assets where each unit is interchangeable with another, making them ideal for use as cryptocurrencies, utility tokens, and digital assets within decentralized applications (dApps).  

## What is a Fungible Token?

Fungible tokens are blockchain-based digital assets that are interchangeable and divisible. Each unit of a fungible token holds the same value as another, similar to traditional currencies. These tokens are widely used for payments, governance, staking, and other financial applications within blockchain ecosystems.  

## Ethereum Blockchain

Ethereum is a leading blockchain platform that provides an extensive ecosystem for token creation and management. For Tokenizer, Ethereum offers the following advantages:  

- **ERC-20 Standard:** The ERC-20 token format ensures compatibility with a wide range of wallets, exchanges, and decentralized applications.  
- **Smart Contract Development (Solidity):** Solidity is Ethereum’s primary programming language, specifically designed for smart contract development.  
- **Mature Development Tools:** Ethereum’s development ecosystem includes powerful tools like Hardhat, which simplify the process of writing, testing, and deploying smart contracts.  

## ERC-20 Token Standard

ERC-20 is the most widely adopted standard for fungible tokens on Ethereum. It defines a set of rules that compliant tokens must follow, ensuring seamless integration within the Ethereum ecosystem. The core ERC-20 functions include:

- `totalSupply()`: Returns the total supply of tokens.  
- `balanceOf(address account)`: Returns the token balance of a specified address.  
- `transfer(address recipient, uint256 amount)`: Transfers tokens from the sender to a recipient.  
- `approve(address spender, uint256 amount)`: Allows a third party to spend tokens on behalf of the owner.  
- `transferFrom(address sender, address recipient, uint256 amount)`: Enables token transfers from one account to another through an approved spender.  
- `allowance(address owner, address spender)`: Returns the remaining number of tokens a spender is allowed to transfer on behalf of the owner.  

By implementing ERC-20, Tokenizer ensures broad compatibility and ease of integration across Ethereum’s ecosystem.  

## Testnet Deployment

To deploy and test the Tokenizer smart contract, we use a testnet, which allows for experimentation without requiring real funds.  

### Moonbase Alpha Testnet

For this project, we use the Moonbase Alpha testnet because:  

- **No Real Ether Required:** Test Ether can be obtained freely, making deployment and testing cost-free.  
- **Easy Token Faucet:** Moonbase Alpha provides an easy-to-use faucet for obtaining test tokens, allowing developers to simulate real-world interactions before deploying on the Ethereum mainnet.  

The testnet environment enables us to verify the token's functionality before its official launch.  

## Development Environment

### Hardhat

The development and deployment of the Tokenizer smart contract are done using Hardhat, a robust Ethereum development environment. Hardhat provides:  

- **Smart Contract Compilation:** Automates the compilation of Solidity code, ensuring efficient contract deployment.  
- **Deployment Tools:** Facilitates smooth deployment to Ethereum testnets and the mainnet.  
- **Local Blockchain Simulation:** Runs a local Ethereum network for debugging and testing before deploying to public testnets.  

Hardhat’s powerful tools streamline the development process, making it easier to build, test, and deploy Ethereum-based fungible tokens efficiently.

smart contract address = 0x4E563687c50743B6bF8bE247B1D51a83f128A13D



