// scripts/index.js


async function main () {
    // const accounts = (await ethers.getSigners()).map(signer => signer.address);
    const [owner, addr1, addr2, addr3] = (await ethers.getSigners()).map(signer => signer.address);

    console.log("Owner: ", owner, "other accounts: ", addr1, "\n", addr2, "\n", addr3);

    const address = '0x14b67fC22D55C9564b4710EdF84BAC8f98427F77';
    const CarbonToken = await ethers.getContractFactory('CarbonToken42');
    const carbonToken = CarbonToken.attach(address);
    const totlaSupply = await carbonToken.totalSupply();
    console.log("Total Supply: ", totlaSupply);

    try {
      await carbonToken.addValidator(addr1)
    } catch (e) {
      console.log("ERROR: ", e)
      
    }

    await carbonToken.connect(addr1).mintCarbonTokens(addr3, 50);
    totlaSupply = await carbonToken.totalSupply();
    console.log("Total Supply: ", totlaSupply);

    balanceOf = await carbonToken.balanceOf(addr3); 
    console.log(`balanceOf, ${addr3} : `, balanceOf);


    await carbonToken.connect(addr3).transfer(addr2, 50);
    await carbonToken.connect(addr1).mintCarbonTokens(addr3,50);

    const balanceOf = await carbonToken.balanceOf(addr2); 
    console.log(`balanceOf, ${addr2} : `, balanceOf);

    await carbonToken.connect(addr3).transfer(addr2, 50);

    balanceOf = await carbonToken.balanceOf(addr2); 
    console.log(`balanceOf, ${addr1} : `, balanceOf);

    balanceOf = await carbonToken.balanceOf(addr3); 
    console.log(`balanceOf, ${addr3} : `, balanceOf);


  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });