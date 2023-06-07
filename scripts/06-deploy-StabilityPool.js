const { ethers, run, network } = require("hardhat")


//deploy Stability token
async function main() {
    const StabilityPool = await ethers.getContractFactory("StabilityPool")
    console.log("Deploying GameItem...")
    const stabilityPool = await StabilityPool.deploy()
    await stabilityPool.deployed()

    console.log("StabilityPool deployed to:", stabilityPool.address)


}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )