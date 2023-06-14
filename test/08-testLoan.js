const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("NFTUSDToken", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    it("contract", async function () {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("LoanDataTest");
        const hardhatToken = await Token.deploy();
        await hardhatToken.deployed();

        await hardhatToken.setData("0x40ebF7a33f8FAb287B9616F54d45fC6371c6f162");
        const data = await hardhatToken.getData();
        console.log("data="+data);


    })
})
