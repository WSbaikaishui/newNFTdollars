

const fs = require('fs');
const {readAddressList} = require('./help');


async function main() {
    const addressList = readAddressList();
    for (let key in addressList) {
        if (addressList.hasOwnProperty(key)) {
            const value = addressList[key];
           await verify(key,value,[])
        }
    }

}

//verify nftusd token
const {run} = require("hardhat");
const verify = async (contract,address, constructorArguments) => {
    console.log("Verifying contract...",contract)
    try {
        await run("verify:verify", {
            address: address,
            constructorArguments: constructorArguments,
        })
    } catch (e) {
        if (e.message.toLowerCase().includes("already verified")) {
            console.log("Already Verified!")
        } else {
            console.log(e)
        }
    }

}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    }
    )