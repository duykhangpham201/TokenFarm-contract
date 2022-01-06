const main = async () => {
    const fethContractFactory = await hre.ethers.getContractFactory("FETHToken");
    const fethContract = await fethContractFactory.deploy();

    await fethContract.deployed();
    console.log("Token contract addy:", fethContract.address);

    const tokenFarmContractFactory = await hre.ethers.getContractFactory("TokenFarm");
    const tokenFarmContract = await tokenFarmContractFactory.deploy(fethContract.address);

    await tokenFarmContract.deployed();
    console.log("Token Farm contract addy:", tokenFarmContract.address);
}

const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();