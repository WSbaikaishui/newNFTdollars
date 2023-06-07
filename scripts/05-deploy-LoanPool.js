const { ethers, run, network } = require("hardhat")


//deploy loanpool token
async function main() {
  const LoanPool = await ethers.getContractFactory("LoanPool")
  console.log("Deploying GameItem...")
  const loanPool = await LoanPool.deploy()
  await loanPool.deployed()

  console.log("LoanPool deployed to:", loanPool.address)


}

//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
          console.error(error)
          process.exit(1)
        }
    )