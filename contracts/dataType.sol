// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.8;

library DataTypes {
    struct ReserveData {

    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address NFTUSDTokenAddress;
    address NFTdollarsTokenAddress;
    //address of the interest rate strategy
    address interestRateAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }
       
       
       
   /**
   * @dev Enum describing the current state of a loan
   * State change flow:
   *  Created -> Active -> Repaid
   *                    -> liquity -> Defaulted
   */
  enum LoanState {
    // We need a default that is not 'Created' - this is the zero value
    None,
    // The loan data is stored, but not initiated yet.
    Created,
    // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
    Active,
    // The loan is in auction, higest price liquidator will got chance to claim it.
    Auction,
    // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
    Repaid,
    // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
    Defaulted
  }
      
      
struct LoanData {
    //the id of the nft loan
    uint256 loanId;
    //the current state of the loan
    LoanState state;
    //address of borrower
    address borrower;
    //address of nft asset token
    address nftAsset;
    //the name of nft token
    string nftName;
    //the id of nft token
    uint256 nftTokenId;
    //scaled borrow amount. Expressed in ray
    uint256 amount;
    //bidder address of first bid
    address liquityAddress;
  }


}
