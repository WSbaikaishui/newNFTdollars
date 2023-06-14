
const { ethers, run, network } = require("hardhat")


//deploy nftusd token
async function main() {
    const GameItem = await ethers.getContractFactory("LoanDataTest")
    console.log("Deploying LoanDataTest...")
    const gameItem = await GameItem.deploy()
    await gameItem.deployed()

    console.log("LoanDataTest deployed to:", gameItem.address)

    await gameItem.setData("0xE2AF2a4CEb57B6b7BfBE350e9daC59be9d402F1A");


}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )