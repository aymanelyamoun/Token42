const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("hardhat");

module.exports = buildModule("Glasses42", (m)=>{
    const deployer = m.getAccount(0);

    // const private_keys = "62cfc138bf0bcf0d7c02884e32da6ca37cc44d3f935d7b45f0a85b37b9723070,f8e4fb80f2fafeed15a5edc259e958d7084f6c9a3a1c3815c3338435b88720b5,a120eebd38d7ea5dbca03e9038115c67110f687a9564e0465aadbfbe018d26fe,cc9f97ff281b09d5366d73811f6ec3d663f46027fa1f450aba2b356d93d3c058".split(',')

    // const wallets = private_keys.map(key => new ethers.Wallet(key, ethers.provider));

    // const owners = wallets.map(wallet => wallet.address);

    // console.log(owners);

    const glasses = m.contract("Glasses42", [],{
        from: deployer,
    });

    return {glasses};
})