
const { ethers, run, network } = require("hardhat")


//deploy nftusd token
async function main() {
    const nftusdToken = await ethers.getContractFactory("NFTUSDToken")
    console.log("Deploying NFTUSDToken...")
    const nftusd = await nftusdToken.deploy()
    await nftusd.deployed()

    console.log("NFTUSDToken deployed to:", nftusd.address)
    if (network.config.chainId === 5  && process.env.ETHERSCAN_API_KEY) {
        console.log("Waiting for block confirmations...")
        await simpleStorage.deployTransaction.wait(6)
        await verify(simpleStorage.address, [])
    }

}

//verify nftusd token
const verify = async (address, constructorArguments) => {
    console.log("Verifying contract...")
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        })
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already Verified!")
        } else {
            console.log(e)
        }
    }

}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    }
    )
