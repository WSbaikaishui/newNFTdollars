# NFTdollars contract

this  is NFTdollars contract, and you can check all of our contracts .
addresses of deployed ,you can find in address.json 
try npm hardhat:

```shell    
npm install --save-dev hardhat
```

Try running :

```shell
npx hardhat help
npx hardhat test test/sample-test.js   //as you want 
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/06-deploy-StabilityPool.js --network 
npx hardhat run scripts/07-verifyContract.js --network
npx hardhat run scripts/08-initializeContract.js --network
```
of course，you need enough money to deploy contract, you can change the value of money in hardhat.config.js
