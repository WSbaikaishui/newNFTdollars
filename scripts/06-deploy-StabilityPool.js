const {readAddressList,storeAddressList} = require('./help');
const { ethers, run, network } = require("hardhat")


//deploy Stability token
async function main() {
    const addressList = readAddressList();
    const StabilityPool = await ethers.getContractFactory("StabilityPool")
    console.log("Deploying GameItem...")
    const stabilityPool = await StabilityPool.deploy()
    await stabilityPool.deployed()
    addressList["StabilityPool"] = stabilityPool.address;
    console.log("StabilityPool deployed to:", stabilityPool.address)

    const nftusdToken = await ethers.getContractFactory("NFTUSDToken")
    console.log("Deploying NFTUSDToken...")
    const nftusd = await nftusdToken.deploy()
    await nftusd.deployed()
    addressList["NFTUSDToken"] = nftusd.address;
    console.log("nftusd deployed to:", nftusd.address)

    const ndlToken = await ethers.getContractFactory("NDLToken")
    console.log("Deploying NDLToken...")
    const ndl = await ndlToken.deploy()
    await ndl.deployed()
    addressList["NDLToken"] = ndl.address;
    console.log("NDLToken deployed to:", ndl.address)

    const nftOracle = await ethers.getContractFactory("NFTOracle")
    console.log("Deploying NFTOracle...")
    const nftoracle = await nftOracle.deploy()
    await nftoracle.deployed()
    addressList["NFTOracle"] = nftoracle.address;
    console.log("NFTOracle deployed to:", nftoracle.address)

    const LoanPool = await ethers.getContractFactory("LoanPool")
    console.log("Deploying GameItem...")
    const loanPool = await LoanPool.deploy()
    await loanPool.deployed()
    addressList["LoanPool"] = loanPool.address;
    console.log("LoanPool deployed to:", loanPool.address)
    storeAddressList(addressList);
    //initial
    await nftusd.initializePool(stabilityPool.address);
    console.log("NFTUSDToken is initialized successfully")

    await ndl.initialize();
    console.log("Ndl is initialized successfully")
    await ndl.initializePool(stabilityPool.address);
    console.log("NDLToken is initializePool successfully  0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162")
    await nftoracle.initialize(
        "0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162",
        200000000000,
        100000000000,
        1800,
        600,
        600);
    console.log("NFTOracleToken is initialized successfully")
    await loanPool.initialize(stabilityPool.address);
    console.log("LoanPoolToken is initialized successfully")
    await stabilityPool.initialize(nftoracle.address,nftusd.address,ndl.address,loanPool.address);

}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )