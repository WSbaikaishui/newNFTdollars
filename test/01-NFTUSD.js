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
    const Token = await ethers.getContractFactory("NFTUSDToken");
    const hardhatToken = await Token.deploy();
    await hardhatToken.deployed();

    //设置pool地址为addr1
    await hardhatToken.initializePool(await addr1.getAddress());
    //addr1调用合约给自己mint 100000代币
    await hardhatToken.connect(addr1).mint(await addr1.getAddress(), 100000);
    const balance = await hardhatToken.balanceOf(await addr1.getAddress());
    console.log("地址1的token数量="+balance);
    await hardhatToken.connect(addr1).transfer(await addr2.getAddress(), 100);
    //查询地址addr1余额
    const balanceAddr1 = await hardhatToken.balanceOf(await addr1.getAddress());
    console.log("地址addr1余额="+balanceAddr1)
    // 钱包addr1给钱包addr2转移100代币数量
    await hardhatToken.connect(addr1).transfer(await addr2.getAddress(), 100);
    const balanceAddr11 = await hardhatToken.balanceOf(await addr1.getAddress());
    console.log("余额转移给addr2后地址addr1余额="+balanceAddr11)
    //查询地址addr2余额
    const balanceAddr2 = await hardhatToken.balanceOf(await addr2.getAddress());
    console.log("地址addr2余额="+balanceAddr2)
    //断言判断
    expect(await hardhatToken.balanceOf(await addr2.getAddress())).to.equal(200);

    //写一个检测burn失败的用例
    await expect(hardhatToken.connect(addr2).burn(await addr2.getAddress(), 100)).to.be.revertedWith("Ownable: caller is not the pool");
    var balanceAddr3 = await hardhatToken.balanceOf(await addr2.getAddress());
    console.log("地址addr2余额="+balanceAddr3)
    //写一个检测burn成功的用例
    await hardhatToken.connect(addr1).burn(await addr1.getAddress(), 5);
    var balanceAddr4 = await hardhatToken.balanceOf(await addr1.getAddress());
    console.log("地址addr1余额="+balanceAddr4)

  } );




  // async function deployOneYearLockFixture() {
  //   const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  //   const ONE_GWEI = 1_000_000_000;
  //
  //   const lockedAmount = ONE_GWEI;
  //   const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;
  //
  //   // Contracts are deployed using the first signer/account by default
  //   const [owner, otherAccount] = await ethers.getSigners();
  //
  //   const Lock = await ethers.getContractFactory("Lock");
  //   const lock = await Lock.deploy(unlockTime, { value: lockedAmount });
  //
  //   return { lock, unlockTime, lockedAmount, owner, otherAccount };
  // }
  //
  // describe("Deployment", function () {
  //   it("Should set the right unlockTime", async function () {
  //     const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);
  //
  //     expect(await lock.unlockTime()).to.equal(unlockTime);
  //   });
  //
  //   it("Should set the right owner", async function () {
  //     const { lock, owner } = await loadFixture(deployOneYearLockFixture);
  //
  //     expect(await lock.owner()).to.equal(owner.address);
  //   });
  //
  //   it("Should receive and store the funds to lock", async function () {
  //     const { lock, lockedAmount } = await loadFixture(
  //       deployOneYearLockFixture
  //     );
  //
  //     expect(await ethers.provider.getBalance(lock.address)).to.equal(
  //       lockedAmount
  //     );
  //   });
  //
  //   it("Should fail if the unlockTime is not in the future", async function () {
  //     // We don't use the fixture here because we want a different deployment
  //     const latestTime = await time.latest();
  //     const Lock = await ethers.getContractFactory("Lock");
  //     await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
  //       "Unlock time should be in the future"
  //     );
  //   });
  // });
  //
  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);
  //
  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });
  //
  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);
  //
  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });
  //
  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });
  //
  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });
  //
  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
