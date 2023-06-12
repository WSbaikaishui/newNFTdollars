const fs = require('fs');
const { ethers, run, network } = require("hardhat")
const { readAddressList, storeAddressList } = require('./help')

//deploy nftusd token
async function main() {
    const nftusdToken = await ethers.getContractFactory("NFTUSDToken")
    console.log("Deploying NFTUSDToken...")
    const nftusd = await nftusdToken.deploy()
    await nftusd.deployed()
    // 存储合约地址到文件
await loadJson(nftusd.address);
const addressList =  readAddressList();
addressList["nftusd"] = nftusd.address;
console.log(addressList)

    // console.log("NFTUSDToken deployed to:", nftusd.address)
    // console.log("network.config.chainId:", network.config.chainId)
    // if (network.config.chainId === 97  && process.env.BSCSCAN_API_KEY ) {
    //     console.log("Waiting for block confirmations...")
    //     await nftusd.deployTransaction.wait(6)
    //     await verify(nftusd.address, [])
    // }

}




const loadJson = async (address) => {
    const jsonFile = 'address.json';
    console.log("start loadJson")
// 读取文件内容
    fs.readFile(jsonFile, 'utf-8', (err, data) => {
        if (err) {
            console.error('Error reading file:', err);
            return;
        }
        console.log('File data:', data)

        // 解析 JSON 数据
        const jsonData = JSON.parse(data);

        // 在数组 A 中添加新元素
        jsonData.A.push(address);

        // 将更新后的数据转换为 JSON 字符串
        const updatedJsonData = JSON.stringify(jsonData, null, 2);

        // 将更新后的数据写回文件
        fs.writeFile(jsonFile, updatedJsonData, 'utf-8', (err) => {
            if (err) {
                console.error('Error writing file:', err);
                return;
            }

            console.log('Element added to the array in the JSON file.');
        });
    });
}


//main
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    }
    )


