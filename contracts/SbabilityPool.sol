// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.8;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./dependencies/SafeMath.sol";
import "./dependencies/LiquitySafeMath128.sol";

import "./interfaces/INFTOracle.sol";
import "./dependencies/Ownable.sol";
import "./interfaces/ILoanPool.sol";
import "./libraries/math/PercentageMath.sol";
import "./interfaces/INFTUSDToken.sol";
import "./interfaces/INDLToken.sol";
import "./dataType.sol";
/**
 * @title LendPool contract
 * @dev Main point of interaction with an Bend protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Auction
 *   # Liquidate
 * - To be covered by a proxy contract, owned by the LendPoolAddressesProvider of the specific market
 * - All admin functions are callable by the LendPoolConfigurator contract defined also in the
 *   LendPoolAddressesProvider
 * @author Bend
 **/
// !!! For Upgradable: DO NOT ADJUST Inheritance Order !!!

contract StabilityPool is
    Initializable,
    ContextUpgradeable,
    IERC721ReceiverUpgradeable,
    Ownable
    {

//        using WadRayMath for uint256;
//        using PercentageMath for uint256;
//        using SafeERC20Upgradeable for IERC20Upgradeable;
//        using ReserveLogic for DataTypes.ReserveData;
//        using NftLogic for DataTypes.NftData;
//        using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
//        using NftConfiguration for DataTypes.NftConfigurationMap;

    using LiquitySafeMath128 for uint128;
    using SafeMath for uint256;
    using PercentageMath for uint256;

        //address for all
        INFTUSDToken public nftusdToken;
        INFTOracle public nftOracle;
        INDLToken public ndlToken;
        ILoanPool public poolLoan;


        uint256 public percentBorrow;
        uint256 public borrowFee;
        uint256 public liquidationFee;
        uint256 public redemptionFee;

        // Tracker for NFTUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
        uint internal constant DECIMAL_PRECISION = 1e18;
        uint256 internal totalNFTUSDDeposits;

        struct Reward {
            uint256 rewardsDuration;//奖励持续时间
            uint256 periodFinish; //奖励结束时间
            uint256 rewardRate;    //奖励速率
            uint256 lastUpdateTime;//上次更新时间
            uint256 rewardPerTokenStored;    //奖励每个代币存储
        }


    //reward token -> reward data
    mapping(address => Reward) public rewardData;
    address[] public rewardTokens;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    mapping(address => uint256) private _balances;

    uint256 public totalSecurityDeposit;
    uint256 public totalExtractionFee;


    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event Recovered(address token, uint256 amount);
    
    
        /**
       * @dev Function is invoked by the proxy contract when the LendPool contract is added to the
       * LendPoolAddressesProvider of the market.
       * - Caching the address of the LendPoolAddressesProvider in order to reduce gas consumption
       *   on subsequent operations

       **/
        function initialize(address _nftOracle, address _nftUSDToken, address _ndlToken, address _poolLoans) public initializer {
            nftusdToken = INFTUSDToken(_nftUSDToken);
            ndlToken = INDLToken(_ndlToken);
            nftOracle = INFTOracle(_nftOracle);
            poolLoan = ILoanPool(_poolLoans);
            percentBorrow = 9*1e5;//percent 90%;
            borrowFee = 4e4; //percent 4%
            redemptionFee = 2e4; //percent 2%
            _renounceOwnership();
            addReward(_ndlToken,1);
            addReward(_nftUSDToken,1);
        }

        function getTotalNFTUSDDeposits() external view  returns (uint) {
            return totalNFTUSDDeposits;
        }

        /**
       * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying bTokens.
       * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
       **/
        function deposit(uint _amount) external updateReward(msg.sender) {
            address sender = msg.sender;
            _requireNonZeroAmount(_amount);
            totalNFTUSDDeposits = totalNFTUSDDeposits.add(_amount);
            _balances[sender] = _balances[sender].add(_amount);

            nftusdToken.sendToPool(sender, address(this), _amount);
            emit Staked(sender, _amount);
        }
//
        function withdraw(uint256 _amount) public updateReward(msg.sender) {
            address sender = msg.sender;
            _requireNonZeroAmount(_amount);
            totalNFTUSDDeposits = totalNFTUSDDeposits.sub(_amount);
            _balances[sender] = _balances[sender].sub(_amount);

            nftusdToken.returnFromPool(address(this), sender, _amount);
            emit Withdrawn(sender, _amount);
        }


        function borrow(
            address asset,
            uint256 amount,
            address nftAsset,
            uint256 nftTokenId,
            address onBehalfOf
        ) external updateReward(address (0))  {
            require(onBehalfOf != address(0), "Errors.VL_INVALID_ONBEHALFOF_ADDRESS");
            require(amount > 0, "Errors.VL_INVALID_AMOUNT");
            address initiator = _msgSender();
            uint256 loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);

            uint256  nftPrice = nftOracle.getFinalPrice(nftAsset);
            require(nftPrice != 0,"no such nft supplyed");
            require(nftPrice > amount,"borrow amount is to high for this NFT");

            if (loanId == 0) {
                string memory nftName = nftOracle.getAssetName(nftAsset);
                loanId = poolLoan.createLoan( initiator, onBehalfOf, nftAsset, nftTokenId,nftName, amount);
            } else {
                poolLoan.updateLoan(initiator, loanId, amount, true);
            }
            notifyRewardAmount(address(ndlToken),amount.percentMul(borrowFee));
            ndlToken.sendNDLToPool(initiator,amount.percentMul(borrowFee));
            totalExtractionFee += amount.percentMul(borrowFee);


            nftusdToken.mint( onBehalfOf, amount.percentMul(percentBorrow));
            nftusdToken.mint(address(this), amount - amount.percentMul(percentBorrow));
            totalSecurityDeposit += amount - amount.percentMul(percentBorrow);
    }



    function repay(
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) external  updateReward(address (0)) returns (uint256, bool) {

        address initiator = _msgSender();
        uint256 loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);
        require(loanId != 0,"no such debt nft");
        (, ,uint256 borrowAmount) = poolLoan.getLoanCollateralAndReserve(loanId);
        uint256 repayAmount = borrowAmount;
        bool isUpdate = false;
        if ( amount.percentDiv(percentBorrow) < repayAmount) {
           repayAmount = amount.percentDiv(percentBorrow);
            poolLoan.updateLoan(
            initiator,
            loanId,
            repayAmount,
            false
            );
        } else {
            isUpdate = true;
            poolLoan.repayLoan(
            initiator,
            loanId,
           repayAmount
            );
        }

        ndlToken.sendNDLToPool(
           initiator,
            repayAmount.percentMul(redemptionFee)
        );
        notifyRewardAmount(address(ndlToken),repayAmount.percentMul(redemptionFee));

        nftusdToken.burn(
            initiator,
            repayAmount.percentMul(percentBorrow)
        );
        nftusdToken.burn(
            address(this),
         repayAmount.percentMul(1e6 - percentBorrow)
        );
        totalSecurityDeposit -=  repayAmount.percentMul(1e6 - percentBorrow);
        totalExtractionFee += repayAmount.percentMul(redemptionFee);
        return (repayAmount, !isUpdate);
    }

    function getTotalSecurityDeposit() external view returns (uint256) {
        return totalSecurityDeposit;
    }

    function getTotalExtractionFee() external view returns (uint256) {
        return totalExtractionFee;
    }

    function liquidate(
        address borrower,
        address nftAsset,
        uint256 nftTokenId
    ) external  returns (uint256) {

        (uint256 accountDebt,uint256 totalNFTLocked) = healthFactor(borrower);
        require(accountDebt < totalNFTLocked,"this is not the liquidate line");
        address initiator = _msgSender();
        uint256 loanID = poolLoan.getCollateralLoanId(nftAsset,nftTokenId);
        DataTypes.LoanData memory loan = poolLoan.getLoan(loanID);
        //if reach the liquidate line
        uint256 nftDebtPrice = nftOracle.getFinalPrice(nftAsset);
        require(nftDebtPrice > loan.amount,"this is not the liquidate line");
        uint256 userBalance = nftusdToken.balanceOf(msg.sender);
        if (userBalance >= loan.amount.percentMul(percentBorrow)){
            nftusdToken.burn(
                initiator,
                loan.amount.percentMul(percentBorrow)
            );
            nftusdToken.transfer(
                initiator,
                loan.amount - loan.amount.percentMul(percentBorrow)
            );
            poolLoan.liquidateLoan(
                loan.borrower,
                loan.loanId,
                loan.amount,
                true
            );
            ndlToken.sendNDLToPool(initiator,loan.amount.percentMul(borrowFee));
            notifyRewardAmount(address(ndlToken),loan.amount.percentMul(borrowFee));
            totalExtractionFee += loan.amount.percentMul(borrowFee);
            totalSecurityDeposit = totalSecurityDeposit - loan.amount.percentMul(1e6-percentBorrow);

        }else{
            poolLoan.liquidateLoan(
                loan.borrower,
                loan.loanId,
                loan.amount,
                false
            );
            string memory nftName = nftOracle.getAssetName(nftAsset);
            poolLoan.createLoan(
                initiator,
                initiator,
                nftAsset,
                nftTokenId,
                nftName,
                nftDebtPrice
            );
            nftusdToken.mint(
                initiator,
                nftDebtPrice.percentMul(percentBorrow)- userBalance
            );
            ndlToken.sendNDLToPool(initiator,userBalance.percentMul(borrowFee));
            notifyRewardAmount(address(ndlToken),userBalance.percentMul(borrowFee));
            totalExtractionFee += userBalance.percentMul(borrowFee);
            notifyRewardAmount(address(nftusdToken),(loan.amount - nftDebtPrice).percentMul(1e6-percentBorrow));
            totalSecurityDeposit = totalSecurityDeposit - (loan.amount - nftDebtPrice).percentMul(1e6-percentBorrow);
        }
        return 0;
    }

    function healthFactor(address user) public view  returns (uint256 accountDebt,uint256 totalNFTLocked){
        uint256[] memory loanIds = poolLoan.getLoanIds(user);
        uint256 nftDebtPrice;
        address nftAsset;
        uint256 amount ;

        for (uint256 i = 0; i < loanIds.length; i++) {
            (nftAsset, , amount) = poolLoan.getLoanCollateralAndReserve(loanIds[i]);
            nftDebtPrice = nftOracle.getFinalPrice(nftAsset);
            totalNFTLocked += nftDebtPrice;
           accountDebt += amount;
        }
        return (accountDebt,totalNFTLocked);
    }

    function getLoanIds(address user) external view returns (uint256[] memory) {
        return poolLoan.getLoanIds(user);
    }

    function getLoanCollateralAndReserve(uint256 loanId) external view returns (address nftAsset, uint256 nftTokenId, uint256 amount) {
        return poolLoan.getLoanCollateralAndReserve(loanId);
    }

    function getAllLoanMessage(address user) external view returns (DataTypes.LoanData[] memory loanData) {

        uint256[] memory  loanIds = poolLoan.getLoanIds(user);
        loanData = new DataTypes.LoanData[](loanIds.length);
        for (uint256 i = 0; i < loanIds.length; i++) {
            loanData[i] = poolLoan.getLoan(loanIds[i]);
        }
        return loanData;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }



    function _requireUserHasDeposit(uint _initialDeposit) internal pure {
        require(_initialDeposit > 0, 'StabilityPool: User must have a non-zero deposit');
    }

    function _requireNonZeroAmount(uint _amount) internal pure {
        require(_amount > 0, 'StabilityPool: Amount must be non-zero');
    }

    function _requireUserHasNoDeposit(address _address) internal view {
        uint initialDeposit = _balances[_address];
        require(initialDeposit == 0, 'StabilityPool: User must have no deposit');
    }



    function getReward() public  updateReward(msg.sender) {

        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20Upgradeable(_rewardsToken).transfer(msg.sender, reward);
                emit RewardPaid(msg.sender, _rewardsToken, reward);
            }
        }
    }

    function notifyRewardAmount(address _rewardsToken, uint256 reward) public  {

        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
            rewardData[_rewardsToken].rewardRate = reward.div(rewardData[_rewardsToken].rewardsDuration);
        } else {
            uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardData[_rewardsToken].rewardRate);
            rewardData[_rewardsToken].rewardRate = reward.add(leftover).div(rewardData[_rewardsToken].rewardsDuration);
        }

        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp.add(rewardData[_rewardsToken].rewardsDuration);
        emit RewardAdded(reward);
    }



//    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
//    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
//        require(tokenAddress != address(stakingToken), "Cannot withdraw staking token");
//        require(rewardData[tokenAddress].lastUpdateTime == 0, "Cannot withdraw reward token");
//        IERC20Upgradeable(tokenAddress).transfer(owner, tokenAmount);
//        emit Recovered(tokenAddress, tokenAmount);
//    }

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external {
        require(
            block.timestamp > rewardData[_rewardsToken].periodFinish,
            "Reward period still active"
        );
//        require(rewardData[_rewardsToken].rewardsDistributor == msg.sender);
        require(_rewardsDuration > 0, "Reward duration must be non-zero");
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(_rewardsToken, rewardData[_rewardsToken].rewardsDuration);
    }


    modifier updateReward(address account) {
        for (uint i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = rewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = earned(account, token);
                userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }


    function addReward(
        address _rewardsToken,
        uint256 _rewardsDuration
    )
    private
    {
        require(rewardData[_rewardsToken].rewardsDuration == 0);
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
    }


    function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
        return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
    }

    function rewardPerToken(address _rewardsToken) public view returns (uint256) {
        if (totalNFTUSDDeposits == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
        rewardData[_rewardsToken].rewardPerTokenStored.add(
            lastTimeRewardApplicable(_rewardsToken).sub(rewardData[_rewardsToken].lastUpdateTime).mul(rewardData[_rewardsToken].rewardRate).mul(1e18).div(totalNFTUSDDeposits)
        );
    }

    function earned(address account, address _rewardsToken) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[account][_rewardsToken])).div(1e18).add(rewards[account][_rewardsToken]);
    }


}


library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}