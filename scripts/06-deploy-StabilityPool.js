const {readAddressList,storeAddressList} = require('./help');
const { ethers, run, network } = require("hardhat")


//deploy Stability token
async function main() {
    const addressList = readAddressList();
    const StabilityPool = await ethers.getContractFactory("StabilityPool")
    console.log("Deploying Stability Pool...")
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


}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )