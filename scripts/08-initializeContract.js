const {readAddressList,storeAddressList} = require('./help');
const { ethers, run, network } = require("hardhat")

async function main() {
    addressList = readAddressList();
    //initial

    //initial nfusd token
    const nftusdToken = await ethers.getContractFactory("NFTUSDToken")
    const nftusd = nftusdToken.attach(addressList["NFTUSDToken"]);

    await nftusd.initializePool(addressList["StabilityPool"]);
    console.log("NFTUSDToken is initialized successfully")

    //initial ndl token
    const ndlToken = await ethers.getContractFactory("NDLToken")
    const ndl = ndlToken.attach(addressList["NDLToken"]);

    await ndl.initialize();
    console.log("Ndl is initialized successfully")
    await ndl.initializePool(addressList["StabilityPool"]);
    console.log("NDLToken is initializePool successfully  0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162")

    //initial nftoracle token
    const nftOracle = await ethers.getContractFactory("NFTOracle")
    const nftoracle = nftOracle.attach(addressList["NFTOracle"]);

    await nftoracle.initialize(
        "0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162",
        200000000000,
        100000000000,
        1800,
        600,
        600);
    console.log("NFTOracleToken is initialized successfully")
    await nftoracle.addAsset(
        "0xE2AF2a4CEb57B6b7BfBE350e9daC59be9d402F1A",
        "GameItem",
        "ITM",
        "helloWorld",
        1
    )
   console.log("NFTOracleToken is addAsset successfully")
    await nftoracle.setAssetData(
        "0xE2AF2a4CEb57B6b7BfBE350e9daC59be9d402F1A",
        100000,
        29,
        19)
    console.log("NFTOracleToken is setAssetData successfully")




    //initial loanpool token
    const LoanPool = await ethers.getContractFactory("LoanPool")
    const loanPool = LoanPool.attach(addressList["LoanPool"]);

    await loanPool.initialize(addressList["StabilityPool"]);
    console.log("LoanPoolToken is initialized successfully")


//initial stabilitypool token
    const StabilityPool = await ethers.getContractFactory("StabilityPool")
    const stabilityPool = StabilityPool.attach(addressList["StabilityPool"]);

    await stabilityPool.initialize(nftoracle.address,nftusd.address,ndl.address,loanPool.address);
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