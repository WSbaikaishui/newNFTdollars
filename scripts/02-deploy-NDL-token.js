
const { ethers, run, network } = require("hardhat")
const {readAddressList, storeAddressList} = require("./help");


//deploy nftusd token
async function main() {
    const addressList = readAddressList();
    const ndlToken = await ethers.getContractFactory("NDLToken")
    console.log("Deploying NDLToken...")
    const ndl = await ndlToken.deploy()
    await ndl.deployed()
    addressList["NDLToken"] = ndl.address;
    console.log("NDLToken deployed to:", ndl.address)
    storeAddressList(addressList);
    const tx1 =await ndl.initialize();
    await tx1.wait();
    console.log("Ndl is initialized successfully")



}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )