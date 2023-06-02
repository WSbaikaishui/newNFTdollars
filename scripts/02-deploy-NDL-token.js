
const { ethers, run, network } = require("hardhat")


//deploy nftusd token
async function main() {
    const ndlToken = await ethers.getContractFactory("NDLToken")
    console.log("Deploying NDLToken...")
    const ndl = await ndlToken.deploy()
    await ndl.deployed()

    console.log("NDLToken deployed to:", ndl.address)


}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )