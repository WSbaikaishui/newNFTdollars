const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("multiRewards", function () {

    it ("contract", async function(){
        const [owner,address1,address2] = await ethers.getSigners();

        //than we depoly a NDL token
        const NDL = await ethers.getContractFactory("NDLToken");
        const NDLToken = await NDL.connect(owner).deploy();
        await NDLToken.deployed();
        await NDLToken.connect(owner).initialize();

        const MultiRewards = await ethers.getContractFactory("MultiReward");
        const multiRewards = await MultiRewards.deploy(await owner.getAddress(),NDLToken.address);
        await multiRewards.deployed();
        console.log("multiRewards is deployed successfully")
        console.log("ndl balance ",await NDLToken.balanceOf(await owner.getAddress()));


        //we initialize the multiReword
        await multiRewards.addReward(NDLToken.address, await owner.getAddress(),1);
        console.log("multiRewards is addReward successfully")

        //transfer ndl to address1
        await NDLToken.connect(owner).transfer(await address1.getAddress(),10000000000000);

        //we stake ndl to multiRewards
        await NDLToken.connect(owner).approve(multiRewards.address,10000000000);
        await NDLToken.connect(address1).approve(multiRewards.address,10000000000);

        await multiRewards.connect(owner).stake(40000000);
        console.log("owner balance  after stake  ",await NDLToken.balanceOf(await owner.getAddress()));
        console.log("multiRewards is stake successfully")
        await multiRewards.notifyRewardAmount(NDLToken.address, 10000000);
        console.log("owner balance  after notify amount",await NDLToken.balanceOf(await owner.getAddress()));

        await multiRewards.connect(address1).stake(40000000);
        console.log("address1 balance  after stake  ",await NDLToken.balanceOf(await address1.getAddress()));
        await multiRewards.connect(address1).withdraw(20000000);
        await multiRewards.connect(owner).withdraw(20000000);
        await multiRewards.notifyRewardAmount(NDLToken.address, 10000000);
        console.log("owner balance after notifyRewardAmount ",await NDLToken.balanceOf(await owner.getAddress()));

        await multiRewards.connect(address1).getReward();
        await multiRewards.connect(owner).getReward();
        console.log("owner balance after second getReward ",await NDLToken.balanceOf(await owner.getAddress()));
        console.log("address1 balance after second getReward ",await NDLToken.balanceOf(await address1.getAddress()));

    });


});