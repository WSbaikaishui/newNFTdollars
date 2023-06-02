const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("NFTOracle", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    it("contract", async function () {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("NFTOracle");
        const hardhatToken = await Token.connect(owner).deploy();
        await hardhatToken.deployed();
        console.log("this contract address is: " + hardhatToken.address);
        //initialize
        await hardhatToken.connect(owner).initialize(
            await owner.getAddress(),
            200000000000,
            100000000000,
            1800,
            600,
            600
        );

        //test setaddressList
        await hardhatToken.connect(owner).setAssets([await addr1.getAddress(),await addr2.getAddress()],["hello","world"],["h","w"],["h.com","w.com"],0);
        //test setaddress
        await hardhatToken.connect(owner).addAsset(await owner.getAddress(),"solidity","s","s.com",  1);
        //test setAssetPrice
        await hardhatToken.connect(owner).setAssetData( await addr1.getAddress(),100, 2, 19);
        //test getAssetPrice
        const assetData = await hardhatToken.connect(owner).getAssetPrice( await addr1.getAddress());
        console.log("assetData: " + assetData);
        //test getAssetBaseMessage by type
        const assets = await hardhatToken.connect(owner).getAssets(0);
        console.log("assets: " + assets);

    } );

});
