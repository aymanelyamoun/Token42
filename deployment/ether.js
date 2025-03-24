const { ethers } = require("ethers");
const axios = require("axios");
require("dotenv").config();
const readline = require("readline");

// Token Interaction Class
class TokenInteraction {
    constructor(tokenAddress, providerUrl, privateKey, apiKey, explorerApiUrl) {
        this.tokenAddress = tokenAddress;
        this.provider = new ethers.JsonRpcProvider(providerUrl);
        this.wallet = new ethers.Wallet(privateKey, this.provider);
        this.apiKey = apiKey;
        this.explorerApiUrl = explorerApiUrl; // Example: "https://api-moonbeam.moonscan.io/api"
        this.token = null;
        this.eventListeners = new Map();
    }

    async fetchTokenABI() {
        try {
            console.log(`Fetching ABI for contract: ${this.tokenAddress}`);
            const response = await axios.get(this.explorerApiUrl, {
                params: {
                    module: "contract",
                    action: "getabi",
                    address: this.tokenAddress,
                    apikey: this.apiKey
                }
            });

            if (response.data.status !== "1") {
                throw new Error(`Failed to fetch ABI: ${response.data.message}`);
            }

            const abi = JSON.parse(response.data.result);
            console.log("ABI fetched successfully!");
            return abi;
        } catch (error) {
            console.error("Error fetching ABI:", error.message);
            throw error;
        }
    }

    async initializeContract() {
        try {
            const abi = await this.fetchTokenABI();
            this.token = new ethers.Contract(this.tokenAddress, abi, this.wallet);
            console.log(`Contract initialized at ${this.tokenAddress}`);
        } catch (error) {
            console.error("Failed to initialize contract:", error.message);
        }
    }

    async getTokenInfo() {
        if (!this.token) {
            console.error("Contract not initialized. Call initializeContract() first.");
            return;
        }

        try {
            const name = await this.token.name();
            const symbol = await this.token.symbol();
            const decimals = await this.token.decimals();
            const totalSupply = await this.token.totalSupply();
            
            return { 
                name, 
                symbol, 
                decimals, 
                totalSupply: ethers.formatUnits(totalSupply, decimals) 
            };
        } catch (error) {
            console.error("Error fetching token info:", error.message);
        }
    }

    async getBalance(address) {
        try {
            const balance = await this.token.balanceOf(address);
            const decimals = await this.token.decimals();
            return ethers.formatUnits(balance, decimals);
        } catch (error) {
            console.error("Error getting balance:", error.message);
        }
    }

    async transfer(toAddress, amount) {
        try {
            const decimals = await this.token.decimals();
            const parsedAmount = ethers.parseUnits(amount.toString(), decimals);
            const tx = await this.token.transfer(toAddress, parsedAmount);
            await tx.wait();
            console.log(`Successfully transferred ${amount} tokens to ${toAddress}`);
        } catch (error) {
            console.error("Error transferring tokens:", error.message);
        }
    }

    async approve(spenderAddress, amount) {
        try {
            const decimals = await this.token.decimals();
            const parsedAmount = ethers.parseUnits(amount.toString(), decimals);
            const tx = await this.token.approve(spenderAddress, parsedAmount);
            await tx.wait();
            console.log(`Successfully approved ${amount} tokens for ${spenderAddress}`);
        } catch (error) {
            console.error("Error approving tokens:", error.message);
        }
    }

    async getTransactions() {
        try {
            const transactions = await this.token.getTransactions();
            return transactions;
        } catch (error) {
            console.error("Error fetching transactions:", error.message);
        }
    }

    async submitMintTransaction(to, amount) {
        try {
            const tx = await this.token.submitMintTransaction(to, amount);
            await tx.wait();
            console.log(`Mint transaction submitted for ${amount} tokens to ${to}`);
        } catch (error) {
            console.error("Error submitting mint transaction:", error.message);
        }
    }

    async burn(amount) {
        try {
            const tx = await this.token.burn(amount);
            await tx.wait();
            console.log(`Burned ${amount} tokens`);
        } catch (error) {
            console.error("Error burning tokens:", error.message);
        }
    }

    async confirmTransaction(id) {
        try {
            const tx = await this.token.confirmTransaction(id);
            await tx.wait();
            console.log(`Transaction ${id} confirmed`);
        } catch (error) {
            console.error("Error confirming transaction:", error.message);
        }
    }

    async executeTransaction(id) {
        try {
            const tx = await this.token.executeTransaction(id);
            await tx.wait();
            console.log(`Transaction ${id} executed`);
        } catch (error) {
            console.error("Error executing transaction:", error.message);
        }
    }
}

// CLI Interface
class InteractiveTokenCLI {
    constructor(tokenInteraction) {
        this.tokenInteraction = tokenInteraction;
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
    }

    async prompt(question) {
        return new Promise((resolve) => this.rl.question(question, resolve));
    }

    async handleCommand(command) {
        try {
            switch (command) {
                case "1":
                    console.log("Fetching token info...");
                    console.log(await this.tokenInteraction.getTokenInfo());
                    break;

                case "2":
                    const address = await this.prompt("Enter address: ");
                    console.log(`Balance: ${await this.tokenInteraction.getBalance(address)}`);
                    break;

                case "3":
                    const to = await this.prompt("Enter recipient address: ");
                    const amount = await this.prompt("Enter amount: ");
                    await this.tokenInteraction.transfer(to, amount);
                    break;

                case "4":
                    const spender = await this.prompt("Enter spender address: ");
                    const approveAmount = await this.prompt("Enter amount to approve: ");
                    await this.tokenInteraction.approve(spender, approveAmount);
                    break;

                case "5":
                    console.log("Transactions:", await this.tokenInteraction.getTransactions());
                    break;

                case "6":
                    const mintTo = await this.prompt("Enter recipient address: ");
                    const mintAmount = await this.prompt("Enter amount to mint: ");
                    await this.tokenInteraction.submitMintTransaction(mintTo, mintAmount);
                    break;

                case "7":
                    const burnAmount = await this.prompt("Enter amount to burn: ");
                    await this.tokenInteraction.burn(burnAmount);
                    break;

                case "8":
                    const confirmId = await this.prompt("Enter transaction ID to confirm: ");
                    await this.tokenInteraction.confirmTransaction(confirmId);
                    break;

                case "9":
                    const executeId = await this.prompt("Enter transaction ID to execute: ");
                    await this.tokenInteraction.executeTransaction(executeId);
                    break;

                case "0":
                    console.log("Goodbye!");
                    this.rl.close();
                    process.exit(0);

                default:
                    console.log("Invalid command.");
            }
        } catch (error) {
            console.error("Error:", error.message);
        }
    }

    async start() {
        while (true) {
            console.log("\n1. Get token info\n2. Get balance\n3. Transfer tokens\n4. Approve tokens\n5. Get transactions\n6. Mint tokens\n7. Burn tokens\n8. Confirm transaction\n9. Execute transaction\n0. Exit");
            const command = await this.prompt("Enter command: ");
            await this.handleCommand(command);
        }
    }
}

// Main function
(async function main() {
    const token = new TokenInteraction(
        process.env.TOKEN_ADDRESS,
        process.env.PROVIDER_URL,
        process.env.PRIVATE_KEY,
        process.env.MOONBASE_API_KEY,
        process.env.EXPLORER_API_URL
    );

    await token.initializeContract();
    new InteractiveTokenCLI(token).start();
})();

