const { ethers, run, network } = require("hardhat")


//deploy nftusd token
async function main() {
    const GameItem = await ethers.getContractFactory("GameItem")
    console.log("Deploying GameItem...")
    const gameItem = await GameItem.deploy()
    await gameItem.deployed()

    console.log("NDLToken deployed to:", gameItem.address)


}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )