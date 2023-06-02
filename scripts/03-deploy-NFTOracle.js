const { ethers, run, network } = require("hardhat")


//deploy nftusd token
async function main() {
    const nftOracle = await ethers.getContractFactory("NFTOracle")
    console.log("Deploying NFTOracle...")
    const nftoracle = await nftOracle.deploy()
    await nftoracle.deployed()

    console.log("NDLToken deployed to:", nftoracle.address)


}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
            console.error(error)
            process.exit(1)
        }
    )