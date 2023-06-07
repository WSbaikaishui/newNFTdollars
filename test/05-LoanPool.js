const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("LoanPool", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    it("contract", async function () {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const address1 =  await addr1.getAddress();

        const Token = await ethers.getContractFactory("LoanPool");
        const hardhatToken = await Token.connect(owner).deploy();
        await hardhatToken.deployed();
        console.log("loanPool contract address is: " + hardhatToken.address);


        const Token1 = await ethers.getContractFactory("GameItem");
        const hardhatToken1 = await Token1.connect(owner).deploy();
        await hardhatToken1.deployed();
        const nftAddress = hardhatToken1.address;
        console.log("nft contract address is: " + hardhatToken1.address);


        //test initialize
        await hardhatToken.initialize( address1 );

        const nftTx1 = await hardhatToken1.connect(addr1).awardItem(await addr1.getAddress(), "1234");
        const nftTx2 =  await hardhatToken1.connect(addr1).awardItem(await addr1.getAddress(), "12345");
        const receipt1 = await nftTx1.wait();
        const receipt2 = await nftTx2.wait();
        const tokenID1 = receipt1.events[0].args[2].toNumber();
        const tokenID2 = receipt2.events[0].args[2].toNumber();
        // await hardhatToken1.connect(addr1).transferFrom(address1, await addr2.getAddress(), tokenID.value.toString());

        //test createLoan

        await hardhatToken1.connect(addr1).setApprovalForAll(hardhatToken.address, true);
        const loanTx1 = await hardhatToken.connect(addr1).createLoan( address1, address1, nftAddress,tokenID1,15);
        const loanTx2 = await hardhatToken.connect(addr1).createLoan( address1, address1, nftAddress,tokenID2,15);
        const receipt3 = await loanTx1.wait();
        const receipt4 = await loanTx2.wait();
        const loanID1 = receipt3.events[1].args[2].toString();
        const loanID2 = receipt4.events[1].args[2].toString();
        // console.log("receipt3:",receipt3.events[1].args[2].toString());
        // console.log("receipt4:",receipt4.events[1].args[2].toString());
        //test getloan data
        const loanData1 = await hardhatToken.connect(addr1).getLoan(loanID1);
        console.log("loan data1:",loanData1);
        const loanData2 = await hardhatToken.connect(addr1).getLoan(loanID2);
        console.log("loan data2:",loanData2);
        //test borrowOf
        const borrowOf = await hardhatToken.connect(addr1).borrowerOf(loanID1);
        console.log("borrowOf:",borrowOf);


        //check nft owner
        const ownerOf1 = await hardhatToken1.connect(addr1).ownerOf(tokenID1);
        console.log("ownerOf1:",ownerOf1);

        //check hardhattoken nft balance
        const balanceOf1 = await hardhatToken1.connect(addr1).balanceOf(hardhatToken.address);
        console.log("balanceOf1:",balanceOf1);
        //test updateLoan
         await hardhatToken.connect(addr1).updateLoan(address1, loanID1, 16);
        const loanData3 = await hardhatToken.connect(addr1).getLoan(loanID1);
        console.log("loan data3: \n",loanData3);

        //test repayLoan
        await hardhatToken.connect(addr1).repayLoan(address1, loanID1, 16);

        //check hardhattoken nft balance
        const balanceOf2 = await hardhatToken1.connect(addr1).balanceOf(hardhatToken.address);
        console.log("balanceOf2:",balanceOf2);

        //test liquidateLoan
        await hardhatToken.connect(addr1).liquidateLoan(address1, loanID2,16);
        const loanData4 = await hardhatToken.connect(addr1).getLoan(loanID2);
        console.log("loan data4: \n",loanData4);
        //check hardhattoken nft balance
        const balanceOf3 = await hardhatToken1.connect(addr1).balanceOf(hardhatToken.address);
        console.log("balanceOf3:",balanceOf3);

    } );

});
