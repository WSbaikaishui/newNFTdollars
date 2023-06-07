// const {
//     time,
//     loadFixture,
// } = require("@nomicfoundation/hardhat-network-helpers");
// const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
// const { expect } = require("chai");
//
// describe("nft", function () {
//     // We define a fixture to reuse the same setup in every test.
//     // We use loadFixture to run this setup once, snapshot that state,
//     // and reset Hardhat Network to that snapshot in every test.
//     it("contract", async function () {
//         const [owner, addr1, addr2] = await ethers.getSigners();
//         const Token = await ethers.getContractFactory("GameItem");
//         const hardhatToken = await Token.connect(owner).deploy();
//         await hardhatToken.deployed();
//         console.log("nft contract address is: " + hardhatToken.address);
//         //test mint
//        const tokenID = await hardhatToken.connect(addr1).awardItem(await addr1.getAddress(), "1234");
//
//         console.log( tokenID.value.toString());
//         const owner1 = await hardhatToken.ownerOf(tokenID.value.toString());
//         const address1 = await addr1.getAddress();
//         console.log("owner1: " + owner1, address1);
//     //test transfer
//             await hardhatToken.connect(addr1).transferFrom(await addr1.getAddress(), await addr2.getAddress(), tokenID.value.toString());
//
//             const newOwner = await hardhatToken.ownerOf(tokenID.value.toString());
//             expect(newOwner).to.equal(await addr2.getAddress());
//         console.log("owner2: " + newOwner, address1);
//     //test  balanceOf
//             const balance = await hardhatToken.balanceOf(await addr2.getAddress());
//             expect(balance).to.equal(1);
//
//            const tokenid = await hardhatToken.awardItem( await addr2.getAddress(), "asdasdasda");
//            console.log("the second token id is ",tokenID,tokenid);
//             const updatedTotalSupply = await hardhatToken.balanceOf(await addr2.getAddress());
//             console.log(updatedTotalSupply);
//             expect(updatedTotalSupply).to.equal(2);
//
//     } );
//
// });

// 导入必要的库和断言方法
const { expect } = require("chai");

// 在 describe 块中编写测试用例
describe("GameItem", function () {
    // 声明全局变量来保存合约实例和测试账户地址
    let gameItem;
    let playerAddress;
    let player2;

    // 部署合约并获取实例以供后续测试使用
    before(async function () {
        const GameItem = await ethers.getContractFactory("GameItem");
        gameItem = await GameItem.deploy();
        await gameItem.deployed();

        // 获取测试账户地址
        [playerAddress,player2] = await ethers.getSigners();
    });

    // 编写测试用例
    it("should award a new item and return its ID", async function () {
        const newItemId1 = await gameItem.awardItem(playerAddress.address, "tokenURI");
        const receipt1 = await newItemId1.wait();
        const newItemId2 = await gameItem.awardItem(playerAddress.address, "tokenURI");
        const receipt2 = await newItemId2.wait();

        //

        console.log(receipt1.events[0].args[2].toNumber(),receipt2.events[0].args[2].toNumber());
        // 使用断言方法验证返回值
        expect(receipt1.events[0].args[2].toNumber()).to.equal(0);

        //approve to  address
        await gameItem.connect(playerAddress).approve(await player2.getAddress(),receipt1.events[0].args[2].toNumber());
        console.log("approve to address",await player2.getAddress());
    });
});
