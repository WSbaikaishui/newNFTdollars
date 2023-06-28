const {readAddressList,storeAddressList} = require('./help');
const { ethers, run, network } = require("hardhat")

async function main() {
    addressList = readAddressList();
    //initial

    //initial nfusd token
    const nftusdToken = await ethers.getContractFactory("NFTUSDToken")
    const nftusd = nftusdToken.attach(addressList["NFTUSDToken"]);


    //initial ndl token
    const ndlToken = await ethers.getContractFactory("NDLToken")
    const ndl = ndlToken.attach(addressList["NDLToken"]);


    //initial nftoracle token
    const nftOracle = await ethers.getContractFactory("NFTOracle")
    const nftoracle = nftOracle.attach(addressList["NFTOracle"]);


    //initial loanpool token
    const LoanPool = await ethers.getContractFactory("LoanPool")
    const loanPool = LoanPool.attach(addressList["LoanPool"]);



    await nftusd.initializePool(addressList["StabilityPool"]);
    console.log("NFTUSDToken is initialized successfully")

    const tx1 =await ndl.initialize();
    await tx1.wait();
    console.log("Ndl is initialized successfully")
    const tx2 = await ndl.initializePool(addressList["StabilityPool"]);
    await tx2.wait();
    const tx3 = await ndl.transfer("0xc7ae166404DfA77D2AF214e04Bb8B930274A02b8", "10000000000000000000000");
    await tx3.wait();
    console.log("NDLToken is initializePool successfully  0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162")


    const tx4 = await nftoracle.initialize(
        "0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162",
        200000000000,
        100000000000,
        1800,
        600,
        600);
    await tx4.wait();
    console.log("NFTOracleToken is initialized successfully")
    const tx5 = await nftoracle.addAsset(
        "0xE2AF2a4CEb57B6b7BfBE350e9daC59be9d402F1A",
        "GameItem",
        "ITM",
        "helloWorld",
        1
    )
    await tx5.wait();
    console.log("NFTOracleToken is addAsset successfully")
    const tx6 = await nftoracle.setAssetData(
        "0xE2AF2a4CEb57B6b7BfBE350e9daC59be9d402F1A",
        100000,
        20,
        2900)
    await tx6.wait();
    console.log("NFTOracleToken is setAssetData successfully")


    const tx7 = await loanPool.initialize(addressList["StabilityPool"]);
    await tx7.wait();
    console.log("LoanPoolToken is initialized successfully")


//initial stabilitypool token
    const StabilityPool = await ethers.getContractFactory("StabilityPool")
    const stabilityPool = StabilityPool.attach(addressList["StabilityPool"]);

   const tx8 =  await stabilityPool.initialize(nftoracle.address,nftusd.address,ndl.address,loanPool.address);
   await tx8.wait();

   const tx9 = await stabilityPool.setThreshold(1,"5000000000000000000")
    await tx9.wait();
   const tx10 = await stabilityPool.setThreshold(2,"1000000000000000000")
    await tx10.wait();
    const tx11 = await stabilityPool.setThreshold(3,"15000000000000000000")
    await tx11.wait();
    console.log("StabilityPoolToken is initialized successfully")


}



//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )