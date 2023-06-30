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
error NotEnoughAmount(uint256 amount, uint256 balance);

//@dev nft can not be redeemed   StabilityPool.sol
//@param nftContract nft contract address
//@param nftTokenId nft token id
//@param nftType nft type
//@param isUpLayer is up layer
error CannotRedeemNFT(address nftContract, uint256 nftTokenId, uint8 nftType, bool isUpLayer);