// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.8;

import {DataTypes} from "../dataType.sol";

interface ILoanPool {
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
//  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a loan is created
   * @param user The address initiating the action
   */
  event LoanCreated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    string nftName,
    uint256 nftTokenId
  );


  /**
   * @dev Emitted when a loan is repaid by the borrower
   * @param user The address initiating the action
   */
  event LoanRepaid(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
  string nftName,
    uint256 nftTokenId
  );




  /**
   * @dev Emitted when a loan is liquidate by the liquidator
   * @param user The address initiating the action
   */
  event LoanLiquidated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    string nftName,
    uint256 nftTokenId
  );

  event BorrowAmountUpdated(
    address indexed initiator,
    uint256 amount
  );

  event SecurityDepositUpdated(
    address indexed initiator,
    uint256 amount
  );

  event ThresholdUpdated(
    uint256 loanID,
    uint256 threshold
  );

  /**
   * @dev Create store a loan object with some params
   * @param initiator The address of the user initiating the borrow

   */
  function createLoan(
    address initiator,
    address nftAsset,
    uint256 nftTokenId,
  string memory nftName,
    bool isUpLayer,
    uint256 threshold,
    bool isTransfer
  ) external returns (uint256);


  /**
   * @dev Repay the given loan
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the repay
   * @param loanId The loan getting burned

   */
  function repayLoan(
    address initiator,
    uint256 loanId

  ) external;




  function getLoanIds(address user) external view  returns (uint256[] memory);



  /**
   * @dev Liquidate the given loan
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting burned

   */
  function liquidateLoan(
    address initiator,
  address liquidator,
    uint256 loanId,
    bool isTransfer
  ) external;



  function borrowerOf(uint256 loanId) external view returns (address);

  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

  function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

  function getLoanCollateralAndReserve(uint256 loanId)
    external
    view
    returns (
      address nftAsset,
      uint256 nftTokenId,
    bool isUpLayer
    );

  function updateSecurityDeposit(address initiator,uint256 amount,bool isAdd) external;
  function updateBorrowAmount(address initiator,uint256 amount,bool isAdd) external;
  function updateThreshold( uint256 loanID,uint256 threshold) external;
  function getBorrowAmount(address initiator) external view returns(uint256);
  function getSecurityDeposit(address initiator) external view returns(uint256);

  function getNftCollateralAmount(address nftAsset) external view returns(uint256);

  function getUserNftCollateralAmount(address user, address nftAsset) external view returns(uint256);
}