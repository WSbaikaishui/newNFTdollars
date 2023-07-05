// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.8;


//@dev nft been locked   LoanPool.sol
//@param nftContract nft contract address
//@param nftTokenId nft token id
//@param loanId loan id
error NFTHasBeenLocked(address nftContract, uint256 nftTokenId, uint256 loanId);

//@dev nft is unlocked   StabilityPool.sol
//@param nftContract nft contract address
//@param nftTokenId nft token id
error UnlockedNFT(address nftContract, uint256 nftTokenId);

//@dev amount is not enough   StabilityPool.sol
//@param amount amount
//@param balance price
error NotEnoughAmount(uint256 amount, uint256 price);

//@dev nft can not be redeemed   StabilityPool.sol
//@param nftContract nft contract address
//@param nftTokenId nft token id
//@param nftType nft type
//@param isUpLayer is up layer
error CannotRedeemNFT(address nftContract, uint256 nftTokenId, uint8 nftType, bool isUpLayer);

//@dev borrow is not liquidity status   StabilityPool.sol
//@param borrower borrower address
error IsNotLiquidity(address borrower);

error NotEnoughSecurityDeposit(uint256 securityDeposit, uint256 priceLoss);

//deposit 必须大于0
error DepositMustGreaterThanZero(uint deposit);

error AmountMustGreaterThanZero(uint amount);

error RewardPeriodNotFinish(uint256 nowTime, uint256 rewardEndTime);