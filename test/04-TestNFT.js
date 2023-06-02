const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("NDL", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    it("contract", async function () {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const Token = await ethers.getContractFactory("GameItem");
        const hardhatToken = await Token.connect(owner).deploy();
        await hardhatToken.deployed();
        console.log("this contract address is: " + hardhatToken.address);
        //test mint
       const tokenID = await hardhatToken.connect(addr1).awardItem(await addr1.getAddress(), "1234");

        console.log( tokenID.value.toString());
        const owner1 = await hardhatToken.ownerOf(tokenID.value.toString());
        const address1 = await addr1.getAddress();
        console.log("owner1: " + owner1, address1);
    //test transfer
            await hardhatToken.connect(addr1).transferFrom(await addr1.getAddress(), await addr2.getAddress(), tokenID.value.toString());

            const newOwner = await hardhatToken.ownerOf(tokenID.value.toString());
            expect(newOwner).to.equal(await addr2.getAddress());
        console.log("owner2: " + newOwner, address1);
    //test  balanceOf
            const balance = await hardhatToken.balanceOf(await addr2.getAddress());
            expect(balance).to.equal(1);

            await hardhatToken.awardItem( await addr2.getAddress(), "asdasdasda");
            const updatedTotalSupply = await hardhatToken.balanceOf(await addr2.getAddress());
            expect(updatedTotalSupply).to.equal(2);

    } );

});
