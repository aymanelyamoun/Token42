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


// const { ethers } = require('ethers');
// require('dotenv').config();
// const yargs = require('yargs/yargs');
// const { hideBin } = require('yargs/helpers');
// const readline = require('readline');

// // Basic ERC20 ABI - add any custom functions your token has
// const tokenABI = [
//     "function name() view returns (string)",
//     "function symbol() view returns (string)",
//     "function decimals() view returns (uint8)",
//     "function totalSupply() view returns (uint256)",
//     "function balanceOf(address) view returns (uint256)",
//     "function transfer(address to, uint256 amount) returns (bool)",
//     "function allowance(address owner, address spender) view returns (uint256)",
//     "function approve(address spender, uint256 amount) returns (bool)",
//     "function transferFrom(address from, address to, uint256 amount) returns (bool)",
//     "function submitMintTransaction(address account, uint256 carbonTons)",
//     "function burn(uint256 amount)",
//     "function confirmTransaction(uint256 transactionId)",
//     "function executeTransaction(uint256 transactionId)",
//     "function getTransactions() view returns (tuple(uint8 txType, address account, uint256 amount, bool executed)[])",
//     "function executeTransaction(uint256 transactionId)",
//     "event Transfer(address indexed from, address indexed to, uint256 value)",
//     "event Approval(address indexed owner, address indexed spender, uint256 value)",
//     "event TransactionSubmitted(uint256 indexed transactionId, uint8 txType)"
// ]

// class TokenInteraction {
//     constructor(tokenAddress, providerUrl, privateKey) {
//         this.provider = new ethers.JsonRpcProvider(providerUrl);
//         this.wallet = new ethers.Wallet(privateKey, this.provider);
//         this.token = new ethers.Contract(tokenAddress, tokenABI, this.wallet);
//         this.eventListeners = new Map();
//     }

//     async getTokenInfo() {
//         try {
//             const name = await this.token.name();
//             const symbol = await this.token.symbol();
//             const decimals = await this.token.decimals();
//             const totalSupply = await this.token.totalSupply();

//             return {
//                 name,
//                 symbol,
//                 decimals,
//                 totalSupply: ethers.formatUnits(totalSupply, decimals)
//             };
//         } catch (error) {
//             console.error('Error getting token info:', error);
//             throw error;
//         }
//     }

//     async getBalance(address) {
//         try {
//             const balance = await this.token.balanceOf(address);
//             const decimals = await this.token.decimals();
//             return ethers.formatUnits(balance, decimals);
//         } catch (error) {
//             console.error('Error getting balance:', error);
//             throw error;
//         }
//     }

//     async transfer(toAddress, amount) {
//         try {
//             const decimals = await this.token.decimals();
//             const parsedAmount = ethers.parseUnits(amount.toString(), decimals);
//             const tx = await this.token.transfer(toAddress, parsedAmount);
//             const receipt = await tx.wait();
//             return receipt;
//         } catch (error) {
//             console.error('Error transferring tokens:', error);
//             throw error;
//         }
//     }

//     async approve(spenderAddress, amount) {
//         try {
//             const decimals = await this.token.decimals();
//             const parsedAmount = ethers.parseUnits(amount.toString(), decimals);
//             const tx = await this.token.approve(spenderAddress, parsedAmount);
//             const receipt = await tx.wait();
//             return receipt;
//         } catch (error) {
//             console.error('Error approving tokens:', error);
//             throw error;
//         }
//     }

//     async getTransactions(){
//         try {
//             const tarnsations = this.token.getTransactions();
//             return tarnsations;
//         } catch (e) {
//             console.error('Error: ', error);
//         }
//     }

//     async submitMintTransaction(to, amount) {
//         try {
//             this.token.submitMintTransaction(to, amount);
//         } catch (e) {
//             console.error('Error: ', error);
//         }
//     }

//     async submitBurnTransaction(amount) {
//         try {
//             this.token.submitBurnTransaction(amount);
//         } catch (e) {
//             console.error('Error: ', error);
//         }
//     }

//     async confirmTransaction(id) {
//         try {
//             this.token.confirmTransaction(id);
//         } catch (e) {
//             console.error('Error: ', error);
//         }
//     }

//     async executeTransaction(id) {
//         try {
//             this.token.executeTransaction(id);
//         } catch (e) {
//             console.error('Error: ', error);
//         }
//     }

//     startEventListener(eventName) {
//         if (this.eventListeners.has(eventName)) {
//             console.log(`Already listening to ${eventName} events`);
//             return;
//         }

//         const listener = (...args) => {
//             const event = args[args.length - 1];
//             console.log('\nEvent detected:');
//             console.log('Event Name:', eventName);
//             console.log('Block Number:', event.blockNumber);
//             console.log('Transaction Hash:', event.transactionHash);
            
//             // Format event data based on event type
//             switch(eventName) {
//                 case 'Transfer':
//                     const [from, to, value] = args;
//                     console.log('From:', from);
//                     console.log('To:', to);
//                     console.log('Value:', ethers.formatUnits(value, 18));
//                     break;
//                 case 'Approval':
//                     const [owner, spender, amount] = args;
//                     console.log('Owner:', owner);
//                     console.log('Spender:', spender);
//                     console.log('Amount:', ethers.formatUnits(amount, 18));
//                     break;
//                 case 'TransactionSubmitted':
//                     const [transactionId, txType] = args;
//                     console.log('Transaction ID:', transactionId);
//                     console.log('Transaction Type:', txType);
//                     break;
//             }
//             console.log('------------------------');
//         };

//         this.token.on(eventName, listener);
//         this.eventListeners.set(eventName, listener);
//         console.log(`Started listening to ${eventName} events`);
//     }

//     listenToTransactionSubmittedEvent() {
//         this.token.on("TransactionSubmitted", (transactionId, txType) => {
//             console.log(`Transfer event detected: from ${transactionId} to ${txType} of ${value.toString()} tokens`);
//             // Handle the event (e.g., update UI, notify user, etc.)
//         });
//     }

//     async mintCarbonTokens(addr,carbonTons){
//         try{
//             await this.token.mintCarbonTokens(addr, carbonTons);
//         }
//         catch (e) {
//             console.log("ERROR: ", e);
//         }
//     }

//     async getAllowance(ownerAddress, spenderAddress) {
//         try {
//             const allowance = await this.token.allowance(ownerAddress, spenderAddress);
//             const decimals = await this.token.decimals();
//             return ethers.formatUnits(allowance, decimals);
//         } catch (error) {
//             console.error('Error getting allowance:', error);
//             throw error;
//         }
//     }

//     async transferFrom(fromAddress, toAddress, amount) {
//         try {
//             const decimals = await this.token.decimals();
//             const parsedAmount = ethers.parseUnits(amount.toString(), decimals);
//             const tx = await this.token.transferFrom(fromAddress, toAddress, parsedAmount);
//             const receipt = await tx.wait();
//             return receipt;
//         } catch (error) {
//             console.error('Error in transferFrom:', error);
//             throw error;
//         }
//     }
// }

// class InteractiveTokenCLI {
//     constructor(tokenInteraction) {
//         this.tokenInteraction = tokenInteraction;
//         this.rl = readline.createInterface({
//             input: process.stdin,
//             output: process.stdout
//         });
//     }

//     async showMenu() {
//         console.log('\nAvailable commands:');
//         console.log('1. Get token info');
//         console.log('2. Get balance');
//         console.log('3. Transfer tokens');
//         console.log('4. Approve tokens');
//         console.log('5. Get transactions');
//         console.log('6. Submit mint transaction');
//         console.log('7. Submit burn transaction');
//         console.log('8. Confirm transaction');
//         console.log('9. Execute transaction');
//         console.log('10. Check allowance');
//         console.log('0. Exit');
//         console.log('\nEnter command number:');
//     }

//     async prompt(question) {
//         return new Promise((resolve) => {
//             this.rl.question(question, resolve);
//         });
//     }

//     async handleCommand(command) {
//         try {
//             switch (command) {
//                 case '1':
//                     const info = await this.tokenInteraction.getTokenInfo();
//                     console.log('Token Info:', info);
//                     break;

//                 case '2':
//                     const address = await this.prompt('Enter address: ');
//                     const balance = await this.tokenInteraction.getBalance(address);
//                     console.log('Balance:', balance);
//                     break;

//                 case '3':
//                     const to = await this.prompt('Enter recipient address: ');
//                     const amount = await this.prompt('Enter amount: ');
//                     const transferResult = await this.tokenInteraction.transfer(to, amount);
//                     console.log('Transfer Result:', transferResult);
//                     break;

//                 case '4':
//                     const spender = await this.prompt('Enter spender address: ');
//                     const approveAmount = await this.prompt('Enter amount to approve: ');
//                     const approveResult = await this.tokenInteraction.approve(spender, approveAmount);
//                     console.log('Approve Result:', approveResult);
//                     break;

//                 case '5':
//                     const transactions = await this.tokenInteraction.getTransactions();
//                     console.log('Transactions:', transactions);
//                     break;

//                 case '6':
//                     const mintTo = await this.prompt('Enter recipient address: ');
//                     const mintAmount = await this.prompt('Enter amount to mint: ');
//                     await this.tokenInteraction.submitMintTransaction(mintTo, mintAmount);
//                     console.log('Mint transaction submitted');
//                     break;

//                 case '7':
//                     const burnAmount = await this.prompt('Enter amount to burn: ');
//                     await this.tokenInteraction.submitBurnTransaction(burnAmount);
//                     console.log('Burn transaction submitted');
//                     break;

//                 case '8':
//                     const confirmId = await this.prompt('Enter transaction ID to confirm: ');
//                     await this.tokenInteraction.confirmTransaction(confirmId);
//                     console.log('Transaction confirmed');
//                     break;

//                 case '9':
//                     const executeId = await this.prompt('Enter transaction ID to execute: ');
//                     await this.tokenInteraction.executeTransaction(executeId);
//                     console.log('Transaction executed');
//                     break;

//                 case '10':
//                     const owner = await this.prompt('Enter owner address: ');
//                     const spenderAddr = await this.prompt('Enter spender address: ');
//                     const allowance = await this.tokenInteraction.getAllowance(owner, spenderAddr);
//                     console.log('Allowance:', allowance);
//                     break;

//                 case '11':
//                     console.log('\nAvailable events:');
//                     console.log('1. Transfer');
//                     console.log('2. Approval');
//                     console.log('3. TransactionSubmitted');
//                     const eventChoice = await this.prompt('Choose event to listen to (1-3): ');
//                     const eventMap = {
//                         '1': 'Transfer',
//                         '2': 'Approval',
//                         '3': 'TransactionSubmitted'
//                     };
//                     const eventName = eventMap[eventChoice];
//                     if (eventName) {
//                         this.tokenInteraction.startEventListener(eventName);
//                     } else {
//                         console.log('Invalid event choice');
//                     }
//                     break;

//                 case '0':
//                     console.log('Goodbye!');
//                     this.rl.close();
//                     process.exit(0);
//                     break;

//                 default:
//                     console.log('Invalid command');
//                     break;
//             }
//         } catch (error) {
//             console.error('Error:', error.message);
//         }
//     }

//     async start() {
//         while (true) {
//             await this.showMenu();
//             const command = await this.prompt('');
//             await this.handleCommand(command);
//         }
//     }
// }

// // Main function to initialize and start the CLI
// async function main() {
//     const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS;
//     const PROVIDER_URL = process.env.PROVIDER_URL;
//     const PRIVATE_KEY = process.env.PRIVATE_KEY;

//     if (!TOKEN_ADDRESS || !PROVIDER_URL || !PRIVATE_KEY) {
//         console.error('Please set TOKEN_ADDRESS, PROVIDER_URL, and PRIVATE_KEY in your .env file');
//         process.exit(1);
//     }

//     const tokenInteraction = new TokenInteraction(
//         TOKEN_ADDRESS,
//         PROVIDER_URL,
//         PRIVATE_KEY
//     );

//     // tokenInteraction.listenToTransactionSubmittedEvent();
//     const cli = new InteractiveTokenCLI(tokenInteraction);
//     await cli.start();
// }

// // Run the interactive CLI
// main().catch(console.error);