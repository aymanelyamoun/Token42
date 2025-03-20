const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("hardhat");
require("dotenv").config({ path: "../../.env" });

module.exports = buildModule("Carbon42", (m)=>{
    // const deployer = m.getAccount(0);

    if (!process.env.PRIVATE_KEYS) {
        throw new Error("PRIVATE_KEYS not found in environment variables");
    }
    const private_keys = process.env.PRIVATE_KEYS.split(',');

    const wallets = private_keys.map(key => new ethers.Wallet(key, ethers.provider));

    const owners = wallets.map(wallet => wallet.address);

    console.log("OWNERS list", owners);

    const carbon = m.contract("CarbonToken42", [owners, 3]);

    return {carbon};
})

