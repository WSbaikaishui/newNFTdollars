const {readAddressList,storeAddressList} = require('./help');
const { ethers, run, network } = require("hardhat")

async function main() {
    //initial ndl token
    const addressList = readAddressList();
    const ndlToken = await ethers.getContractFactory("NDLToken")
    const ndl = ndlToken.attach(addressList["NDLToken"])

    const TimeLock = await ethers.getContractFactory("Timelock")
    const timeLock = await TimeLock.deploy(3, [] , [] , "0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162")
    await timeLock.deployed()
    addressList["TimeLock"] = timeLock.address;
    console.log("TimeLock deployed to:", timeLock.address)

    const Governor = await ethers.getContractFactory("NDLGovernor")
    console.log("Deploying Governor...")
    const governor = await Governor.deploy(ndl.address, timeLock.address)
    await governor.deployed()
    console.log("Governor deployed to:", governor.address)
    addressList["Governor"] = governor.address;
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