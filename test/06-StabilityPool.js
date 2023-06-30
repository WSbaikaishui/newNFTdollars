const {
    time,
    loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("StabilityPool", function () {
    //first we need to deploy NFTUSD contract
    //than we need to deploy NDL contract
    // than we need to deploy NFTOracle contract
    // than we need to deploy LoanPool contract
    // than we need to deploy NFT contract
    //finally we need to deploy StabilityPool contract
    it ("contract", async function () {
        const [owner,address1,address2] = await ethers.getSigners();
        const NFTUSD = await ethers.getContractFactory("NFTUSDToken");
        const NFTUSDToken = await NFTUSD.deploy();
        await NFTUSDToken.deployed();
        const NDL = await ethers.getContractFactory("NDLToken");
        const NDLToken = await NDL.connect(owner).deploy();
        await NDLToken.deployed();
        const NFTOracle = await ethers.getContractFactory("NFTOracle");
        const NFTOracleToken = await NFTOracle.connect(owner).deploy();
        await NFTOracleToken.deployed();

        const GameItem = await ethers.getContractFactory("GameItem");
        const gameItem = await GameItem.deploy();
        await gameItem.deployed();

        const LoanPool = await ethers.getContractFactory("LoanPool");
        const LoanPoolToken = await LoanPool.deploy();
        await LoanPoolToken.deployed();

        const StabilityPool = await ethers.getContractFactory("StabilityPool");
        const StabilityPoolToken = await StabilityPool.deploy();
        await StabilityPoolToken.deployed();
        console.log("all the contracts is deployed successfully")

        //than we need to initialize those contracts
        await NFTUSDToken.initializePool(StabilityPoolToken.address);
        console.log("NFTUSDToken is initialized successfully")
        await NDLToken.connect( owner).initialize();
        await NDLToken.connect( owner).initializePool(StabilityPoolToken.address);
        console.log("NDLToken is initialized successfully")
        await NFTOracleToken.connect(owner).initialize(
            await owner.getAddress(),
            200000000000,
            100000000000,
            1800,
            600,
            600);
        console.log("NFTOracleToken is initialized successfully")
        await LoanPoolToken.initialize(StabilityPoolToken.address);
       console.log("LoanPoolToken is initialized successfully")
        await StabilityPoolToken.initialize(NFTOracleToken.address,NFTUSDToken.address,NDLToken.address,LoanPoolToken.address);

       //first we need to mint a nft
        const newItemId1 = await gameItem.connect(address1).awardItem(await address1.getAddress(), "tokenURI");
        const receipt1 = await newItemId1.wait();

        //first we need to mint a nft
        const newItemId2 = await gameItem.connect(address1).awardItem(await address1.getAddress(), "tokenURI");
        const receipt2 = await newItemId2.wait();

        const newItemId3 = await gameItem.connect(address2).awardItem(await address2.getAddress(), "tokenURI");
        const receipt3 = await newItemId3.wait();

        //than we need to add asset
        await NFTOracleToken.connect(owner).addAsset(gameItem.address,"solidity","s","s.com",1);
        //than we need to set the price of the nft
        await NFTOracleToken.connect(owner).setAssetData( gameItem.address ,100000, 20, 2900);
        //than we get nft price
        const assetData = await NFTOracleToken.connect(owner).getAssetPrice( gameItem.address );
        console.log("assetData: " + assetData);

        //than we need to approve the nft to the StabilityPoolToken
        await gameItem.connect(address1).approve(LoanPoolToken.address, receipt1.events[0].args[2].toNumber());
        await gameItem.connect(address1).approve(LoanPoolToken.address, receipt2.events[0].args[2].toNumber());
        await gameItem.connect(address2).approve(LoanPoolToken.address, receipt3.events[0].args[2].toNumber());
        console.log("approve successfully")
        console.log("Stabilitypooltoken ",await NDLToken.balanceOf(await owner.getAddress()))

        //transfer some NDL to address1, this is the fee
        await NDLToken.connect(owner).transfer(await address1.getAddress(),"1000000000000000000000")
        console.log("Stabilitypooltoken ",await NDLToken.balanceOf(StabilityPoolToken.address))
        //than we can borrow NFTUSD
        // await StabilityPoolToken.sendNDL(await address1.getAddress(),10000000)

        console.log("StabilityPoolToken sendNDL successfully")




       const tx1 = await StabilityPoolToken.connect(address1).LockedNFT(gameItem.address, receipt1.events[0].args[2].toNumber(),false, 1000000);
        await tx1.wait();
       const tx2 =  await StabilityPoolToken.connect(address1).LockedNFT(gameItem.address, receipt2.events[0].args[2].toNumber(),false, 1000000);
       await tx2.wait();
       const tx3 = await StabilityPoolToken.connect(address2).LockedNFT(gameItem.address, receipt3.events[0].args[2].toNumber(),false, 1000000);
       await tx3.wait();
        console.log("nftOracle final price: ",await NFTOracleToken.getFinalPrice(gameItem.address))

        // await StabilityPoolToken.connect(address1).LockedNFT(gameItem.address, receipt1.events[0].args[2].toNumber(),false, 100000000);

        const loanID1 = await LoanPoolToken.connect(address1).getCollateralLoanId(gameItem.address, receipt1.events[0].args[2].toNumber());
        const loanID2 = await LoanPoolToken.connect(address1).getCollateralLoanId(gameItem.address, receipt2.events[0].args[2].toNumber());
        const loanID3 = await LoanPoolToken.connect(address1).getCollateralLoanId(gameItem.address, receipt3.events[0].args[2].toNumber());
        console.log("loanID",loanID1,loanID2, loanID3)
        console.log("healthFactor",await StabilityPoolToken.connect(address1).healthFactor(await address1.getAddress()))
        await StabilityPoolToken.connect(address1).extraction(await address1.getAddress(), "1200000000000000000000");


        console.log("nftusd balance of address1: ",await NFTUSDToken.balanceOf(await address1.getAddress()))
        console.log("nftusd balance of StabilityPoolToken: ",await NFTUSDToken.balanceOf(StabilityPoolToken.address))
        console.log("NDL balance of address1: ",await NDLToken.balanceOf(await address1.getAddress()))

        //deposit NFTUSD
        await StabilityPoolToken.connect(address1).deposit(0,80000);
        console.log("NFTUSD total deposit: ",await StabilityPoolToken.getTotalNFTUSDDeposits())

        //withdraw NFTUSD
        await StabilityPoolToken.connect(address1).withdraw(0,80000);
        console.log("NFTUSD total deposit: ",await StabilityPoolToken.getTotalNFTUSDDeposits())

        const debt = await StabilityPoolToken.healthFactor(await address1.getAddress())
        console.log("address1 debt: ",debt);

        const debt3 = await  StabilityPoolToken.healthFactor(await address2.getAddress())
        console.log("address3 debt: ",debt3);




        // //repay NFTUSD
        // await StabilityPoolToken.connect(address1).repay(await address1.getAddress(),19999);



        //redeemNFT
       const txRedeem1 = await StabilityPoolToken.connect(address1).redeemNFT(gameItem.address, receipt1.events[0].args[2].toNumber(), "1000000000000000000000");
       await txRedeem1.wait();
       const ownerOf = await gameItem.ownerOf(receipt3.events[0].args[2].toNumber());
        const balance1 = await NFTUSDToken.balanceOf(await address1.getAddress());
        const balance2 = await NFTUSDToken.balanceOf(await address2.getAddress());
        console.log("address1 balance ",balance1.toString());
        console.log("address2 balance ",balance2.toString());
        console.log("nft1 ownerOf: " + ownerOf);
        console.log("unlock successfully")
        await StabilityPoolToken.connect(address2).redeemNFT(gameItem.address, receipt1.events[0].args[2].toNumber(),0);
        const ownerof3 = await gameItem.ownerOf(receipt3.events[0].args[2].toNumber());
        console.log("nft3 ownerOf: " + ownerof3);
        console.log("unlock successfully")

        const debt2 = await StabilityPoolToken.healthFactor(await address1.getAddress())
        console.log("debt after repay: ",debt2);




        const ownerof2 = await gameItem.ownerOf(receipt2.events[0].args[2].toNumber());
        console.log("nft2 ownerOf: " + ownerof2);

        console.log(await address1.getAddress());
        console.log("nftusd balance of address1: ",await NFTUSDToken.balanceOf(await address1.getAddress()))
        // const loanids = await StabilityPoolToken.getLoanIds(await address1.getAddress())
        // console.log("return loanid",loanids[0])
        // const loan = await StabilityPoolToken.getLoanCollateralAndReserve(loanids[0])
        // console.log("return loan",loan)

        const totalNDL = await StabilityPoolToken.getTotalExtractionFee()
        console.log("getTotalExtractionFee:",totalNDL)


    })

});