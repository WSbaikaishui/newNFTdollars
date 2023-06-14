const { ethers, run, network } = require("hardhat")


//deploy nftusd token
async function main() {
    const GameItem = await ethers.getContractFactory("GameItem")
    console.log("Deploying GameItem...")
    const gameItem = await GameItem.deploy()
    await gameItem.deployed()

    for (let i = 0; i < 100; i++) {
        let tx = await gameItem.awardItem("0xc7ae166404DfA77D2AF214e04Bb8B930274A02b8", "123");
        await tx.wait()
    }
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