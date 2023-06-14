// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.8;

import "./dataType.sol";

contract LoanDataTest {
    DataTypes.LoanData[2] public loan;



    function setData(address nftAsset) public {
        for (uint256 i = 0; i < 2; i++){
            loan[i].nftAsset = nftAsset;
            loan[i].nftName = "test";
            loan[i].amount = 23;
            loan[i].loanId = i;
}
}
    function getData() external view returns (DataTypes.LoanData[] memory loanData){
        loanData = new DataTypes.LoanData[](2);
        for (uint256 i = 0; i < 2; i++){
            loanData[i] = loan[i];
        }

        return loanData;
    }
}