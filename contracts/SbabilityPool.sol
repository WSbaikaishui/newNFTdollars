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
import "./utils/Errors.sol";
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
        uint256 public percentSecurityDeposit;
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
    uint256 public totalNDLEarned;

    mapping(uint8 => uint256) private _layerThreshold;
    mapping(uint8 => uint256) private _layerTotalNFTUSDDeposits;
    mapping(uint8 => mapping(address => uint256)) private _layerUserBalance;

    //normal reward token
    mapping(uint8 => mapping(address =>Reward)) private _layerRewardData;
    mapping(uint8 => mapping(address => mapping(address => uint256))) public layerUserRewardPerTokenPaid;
    mapping(uint8 => mapping(address => mapping(address => uint256)) )public layerRewards;
    mapping(uint8 => address[]) public layerRewardTokens;






    /* ========== EVENTS ========== */

    event RewardAdded(uint8 types,uint256 reward);
    event ExtraRewardAdd(uint256 reward)    ;
    event Staked(address indexed user, uint8 types,uint256 amount);
    event Withdrawn(address indexed user,uint8 types, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint8 types, uint256 reward);
    event ExtraRewardPaid(address indexed user,  address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint8 types, uint256 newDuration);


    event Recovered(address token, uint256 amount);
    event Extraction(address indexed initiator, address indexed onBehalfOf, uint256 extractionAmount);
    event Repay(address indexed initiator, address indexed borrower, uint256 payAmount);
    event RedeemNFT(address indexed initiator, address indexed borrower,address indexed nftAsset, uint256 tokenId);
    
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
            percentSecurityDeposit = 1*1e5;//percent 10%
            borrowFee = 4e4; //percent 4%
            redemptionFee = 2e4; //percent 2%
//            _renounceOwnership();
            for (uint8 i = 0; i < 4; i++) {
                addReward(i,_ndlToken,3600);
            }
            addExtraReward(_ndlToken,1);
        }

        function setThreshold(uint8 types,uint256 _threshold) external onlyOwner {
            _layerThreshold[types] = _threshold;
        }

        function getTotalNFTUSDDeposits() external view  returns (uint) {
            return totalNFTUSDDeposits;
        }

        /**
       * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying bTokens.
       * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
       **/
        function deposit(uint8 types,uint256 _amount) external  {
            address sender = msg.sender;
            _requireNonZeroAmount(_amount);
            if (_amount > nftusdToken.balanceOf(sender)) {
                _amount = nftusdToken.balanceOf(sender);
            }
            if (types ==0){
                _layerTotalNFTUSDDeposits[types] = _layerTotalNFTUSDDeposits[types].add(_amount);
                _layerUserBalance[types][sender] = _layerUserBalance[types][sender].add(_amount);
            }else{
                require(_layerThreshold[types] <= _amount || _layerThreshold[types] <= _layerUserBalance[types][sender] + _amount,"not enough amount for this type");
                    _layerTotalNFTUSDDeposits[types] = _layerTotalNFTUSDDeposits[types].add(_amount);
                    _layerUserBalance[types][sender] = _layerUserBalance[types][sender].add(_amount);
            }

            nftusdToken.sendToPool(sender, address(this), _amount);
            emit Staked(sender, types, _amount);
        }
//
    function withdraw(uint8 types, uint256 _amount) public {
        address sender = msg.sender;
        _requireNonZeroAmount(_amount);
        //判断withdraw的金额
        if (_layerUserBalance[types][sender] < _amount){
            _amount = _layerUserBalance[types][sender];
        }
        //减去值
        if (types ==0){
            _layerTotalNFTUSDDeposits[types] = _layerTotalNFTUSDDeposits[types].sub(_amount);
            _layerUserBalance[types][sender] = _layerUserBalance[types][sender].sub(_amount);
        }else{
            require(_layerThreshold[types] <=  _layerUserBalance[types][sender] - _amount || _layerUserBalance[types][sender] == _amount,"not enough amount for this type");
            _layerTotalNFTUSDDeposits[types] = _layerTotalNFTUSDDeposits[types].sub(_amount);
            _layerUserBalance[types][sender] = _layerUserBalance[types][sender].sub(_amount);
        }
        nftusdToken.returnFromPool(address(this), sender, _amount);
        emit Withdrawn(sender,types, _amount);
    }



    function LockedNFT(address nftAsset, uint256 nftTokenId, bool isUpLayer, uint256 threshold) public  returns(uint256 loanId){
        address initiator = msg.sender;
        loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);
        string memory nftName = nftOracle.getAssetName(nftAsset);
        require(loanId == 0,"this nft has been locked");
        uint8 nftType = nftOracle.getAssetType(nftAsset);
        if (nftType == 1){
            require(threshold >= 1e6,"threshold must be greater than 100%");
            loanId = poolLoan.createLoan(initiator,  nftAsset, nftTokenId, nftName, isUpLayer, threshold,true);
        }else{
            loanId = poolLoan.createLoan(initiator, nftAsset, nftTokenId, nftName, isUpLayer, 0,true);
        }

        return loanId;
    }


    function extraction(address onBehalfOf, uint256 amount)  public {
        require(onBehalfOf != address(0), "Errors.VL_INVALID_ONBEHALFOF_ADDRESS");
        require(amount > 0, "Errors.VL_INVALID_AMOUNT");
        require(!isLiquidate(msg.sender), "Errors.VL_INVALID_LIQUIDATE");

        DataTypes.ExtractionData memory eData;
        eData.borrower = msg.sender;
        (eData.accountDebt,eData.securityDeposit, eData.maxDebt) = healthFactor(eData.borrower);

        if ( eData.maxDebt >= eData.accountDebt + amount ){
            eData.amount = amount;
        }else{
            eData.amount = eData.maxDebt.sub(eData.accountDebt);
        }

        eData.extractionFee = eData.amount.percentMul(borrowFee);
        eData.securityDeposit = eData.amount.percentMul(percentSecurityDeposit);

        totalSecurityDeposit = totalSecurityDeposit.add(eData.securityDeposit);
        totalExtractionFee = totalExtractionFee.add(eData.extractionFee);
        //mint NFTUSD to contract and mint NFTUSD to onBehalfOf
        nftusdToken.mint(address(this), eData.securityDeposit);
        nftusdToken.mint(onBehalfOf, eData.amount.sub(eData.securityDeposit) );
     //the extraction fee is sent to  pool ,this is the reward for the pool
        ndlToken.sendNDLToPool(eData.borrower,eData.extractionFee);
        totalNDLEarned = totalNDLEarned.add(eData.extractionFee);


        _updateAMountAndDeposit(eData.borrower, eData.amount, eData.securityDeposit, true, true);
        emit Extraction(eData.borrower, onBehalfOf, eData.amount);

    }


    function repay(address onBehalfOf, uint256 amount)  public  {
        require(onBehalfOf != address(0), "Errors.VL_INVALID_ONBEHALFOF_ADDRESS");
        require(amount > 0, "Errors.VL_INVALID_AMOUNT");
        address initiator = msg.sender;
        uint256 accountDebt = poolLoan.getBorrowAmount(onBehalfOf);
        require(accountDebt > 0,"no debt");

        if (accountDebt < amount){
            if (accountDebt > nftusdToken.balanceOf(initiator)){
                amount = nftusdToken.balanceOf(initiator);
            }else{
                amount = accountDebt;
            }
        }
        //burn NFTUSD
        nftusdToken.burn(initiator, amount.percentMul(percentBorrow));
        nftusdToken.burn(address(this), amount.percentMul(percentSecurityDeposit));


        totalSecurityDeposit = totalSecurityDeposit.sub(amount.percentMul(percentSecurityDeposit));
        //send NDL to pool
        ndlToken.sendNDLToPool(initiator,amount.percentMul(redemptionFee));
        totalExtractionFee = totalExtractionFee.add(amount.percentMul(redemptionFee));

        totalNDLEarned = totalNDLEarned.add(amount.percentMul(redemptionFee));
        //update the borrow amount
        _updateAMountAndDeposit(onBehalfOf, amount, amount.percentMul(percentSecurityDeposit), false, false);

       emit Repay(initiator,  onBehalfOf, amount);

    }


        //redeem NFT
    //逻辑就是先如果是自己赎回，那就看看赎回之后会不会触发清算，不会触发那就直接赎回，会触发那就先还款再赎回
    //详细来说，就是先看这个nft是不是升级层了，因为升级层会导致可以借的钱变少，然后判断会不会超过最大借款，超过的话要付一笔钱的
function redeemNFT(address nftAsset, uint256 nftTokenId,uint256 amount)  public  {
    uint256 price = nftOracle.getFinalPrice(nftAsset);
    uint256 loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    if (loanId == 0){
        revert UnlockedNFT(nftAsset, nftTokenId);
    }
    address initiator = msg.sender;
    uint8 nftType = nftOracle.getAssetType(nftAsset);
    DataTypes.LoanData memory loanData = poolLoan.getLoan(loanId);
    (uint256 debt, , uint256 maxDebt) = _getUserDebtMessage(loanData.borrower);

    //if the initiator is the borrower,then the initiator can redeem the nft
    if (loanData.borrower == initiator){
        if(loanData.isUpLayer){
            price = price.percentMul(percentBorrow);
        }
        if (maxDebt < debt + price){
            _repay(initiator, initiator, debt + price - maxDebt);
            ndlToken.sendNDLToPool(initiator,(debt + price - maxDebt).percentMul(redemptionFee));
            totalNDLEarned = totalNDLEarned.add((debt + price - maxDebt).percentMul(redemptionFee));
        }
    }else{
        //if nft'type is not 2 or 1 with isReserve is true,then the nft is not a collateral
        if (amount > nftusdToken.balanceOf(initiator)){
            amount = nftusdToken.balanceOf(initiator);
        }
        if (amount <price){
            revert NotEnoughAmount(amount, price);
        }else if (nftType == 0 && loanData.isUpLayer || nftType == 1){
            if (loanData.threshold > 0){
                if (amount < price.percentMul(loanData.threshold)){
                    revert NotEnoughAmount(amount, price.percentMul(loanData.threshold));
                }
            }
        }else if (nftType ==2 || nftType == 1 && loanData.isUpLayer){
            revert CannotRedeemNFT(nftAsset, nftTokenId, nftType, loanData.isUpLayer);
        }

        if (amount >= debt){
            _repay(initiator,loanData.borrower,debt);
            nftusdToken.redeemedTransfer(initiator, loanData.borrower, amount - debt);
        }else{
            _repay(initiator,loanData.borrower,amount );
        }
//        _repay(initiator,loanData.borrower,amount );
        ndlToken.sendNDLToPool(initiator,amount.percentMul(redemptionFee));
        totalNDLEarned = totalNDLEarned.add(amount.percentMul(redemptionFee));
    }
    poolLoan.repayLoan(initiator, loanId);
}


    //_repay function ,the amount need to be the one which is less between debt and amount
    //这里的逻辑是先burn掉多的钱，就是超出maxDebt的钱，然后更新一下这个钱，然后
    function _repay(address initiator, address borrower, uint256 payAmount ) internal {
        nftusdToken.burn(initiator, payAmount.percentMul(percentBorrow));
        nftusdToken.burn(address(this), payAmount.percentMul(percentSecurityDeposit));
        _updateAMountAndDeposit(initiator,payAmount,payAmount.percentMul(percentSecurityDeposit),false,false);


        totalSecurityDeposit = totalSecurityDeposit.sub(payAmount.percentMul(percentSecurityDeposit));

        emit Repay(initiator, borrower, payAmount);
    }

    //liqutidate the borrower's loan
    //这里先要判断是不是达到了清算线，如果达到了清算线，那么就可以清算
    //达到清算线的条件有两种：
    //  1、价格 < 债务
    //  2、债务*10% > securityDeposit
    //达到清算线了才能发起清算，发起清算后，用户的securityDeposit 首先要用于补全差价，其次用于该nft的用户奖励
    //对于手头资金充裕的用户，把清算人的钱以及需要补上的亏空burn掉，把nft转给清算人，收取手续费作为奖励，这部分结束
    //对于资金不够的清算人，不转走nft，直接把nft换个用户重新createloan（即清算人），然后burn掉对应的钱
    //逻辑首先是判断是不是达到了清算线，然后检查用户是否有对应资金，钱不够不让清算，
    //然后开始计算被清算人的债务和securityDeposit，减去相对应的数值，
    //然后根据清算人的资金情况，分两种情况，一种是资金充裕，一种是资金不充裕

    function liquidate(address borrower,address nftAsset, uint256 nftTokenId,uint256 amount, bool isUpLayer, uint256 threshold) external updateExtraReward(address(0)) {
        require(!isLiquidate(borrower), "The borrower is liquidated");
        DataTypes.LiquityData memory lData;
        (lData.borrowDebt, lData.borrowSecurityDeposit, lData.borrowMaxDebt) = _getUserDebtMessage(borrower);
        lData.liquityAddress = msg.sender;

        uint256 loanID = poolLoan.getCollateralLoanId(nftAsset,nftTokenId);
        DataTypes.LoanData memory loan = poolLoan.getLoan(loanID);
        lData.price = nftOracle.getFinalPrice(nftAsset);

        //判断用户的钱够不够
        lData.userBalance = nftusdToken.balanceOf(lData.liquityAddress);
        require(lData.userBalance <= _isEnoughToken(lData.borrowMaxDebt, lData.borrowDebt,lData.borrowSecurityDeposit, lData.price), "The user's balance is not enough");

        //给被清算人消债，也分两种情况，一种是debt > totalLock, 一种是debt < totalLock
        //第一种情况是常规情况，
        //第二种情况的清算方式，其实区别就在于decreaseSecurityDeposit的算法上
        //第二种情况其实不需要再用securityDeposit 去补差价
        lData.decreaseAmount = lData.price;
        uint256 nftDepositNow = 0;
        if (lData.borrowDebt.percentMul(percentSecurityDeposit) > lData.borrowSecurityDeposit && lData.borrowDebt < lData.borrowMaxDebt){
            //这种情况就是第二种情况
            nftDepositNow = lData.borrowSecurityDeposit.mul(lData.borrowDebt).div(lData.borrowMaxDebt);
            lData.decreaseSecurityDeposit = nftDepositNow;
        } else{
            //如果不满足上述条件，那就是第一种情况，就是常规情况
            //这个 时候首先补差价，补完差价之后，再去算decreaseSecurityDeposit，按照（剩余*nft价格）/总价值
            lData.decreaseAmount += lData.borrowDebt - lData.borrowMaxDebt;
            lData.decreaseSecurityDeposit = lData.borrowDebt - lData.borrowMaxDebt ;
            nftDepositNow = (lData.borrowSecurityDeposit - lData.decreaseSecurityDeposit).mul(lData.price).div(lData.borrowDebt);
            lData.decreaseSecurityDeposit += nftDepositNow;
        }

        if (lData.userBalance < lData.price - nftDepositNow){
            poolLoan.liquidateLoan(loan.borrower, lData.liquityAddress, loan.loanId, false);
            string memory nftName = nftOracle.getAssetName(nftAsset);
            poolLoan.createLoan(lData.liquityAddress, nftAsset, nftTokenId, nftName, isUpLayer, threshold, false);

            uint256 stabilityPoolReward = (lData.price - nftDepositNow - lData.userBalance).percentMul(borrowFee);
            lData.userIncreaseAmount = lData.price;
            lData.userIncreaseSecurityDeposit = lData.price.percentMul(percentSecurityDeposit);
            //把借的钱还给池子，钱从哪里来，就从nft重新存来再借
            _updateAMountAndDeposit(lData.liquityAddress, lData.userIncreaseAmount, lData.userIncreaseSecurityDeposit,true,true);
//            nftusd.burn(lData.liquityAddress, lData.userBalance);
            nftusdToken.mint(lData.liquityAddress, lData.userIncreaseAmount.percentMul(percentBorrow).sub(lData.price - nftDepositNow - lData.userBalance));
            ndlToken.sendNDLToPool(lData.liquityAddress, stabilityPoolReward);
            notifyExtraRewardAmount(address(ndlToken), stabilityPoolReward);

        }else{
            poolLoan.liquidateLoan(
                loan.borrower,
                lData.liquityAddress,
                loan.loanId,
                true
            );
            //burn掉 price的钱，把nft转给清算人
            nftusdToken.burn(lData.liquityAddress, lData.price - nftDepositNow);
            nftusdToken.burn(address(this),  nftDepositNow);
        }
        _liquidate(lData.liquityAddress, lData.decreaseAmount, lData.decreaseSecurityDeposit);
    }


    function _updateAMountAndDeposit(address user, uint256 amount, uint256 sd, bool amountAdd, bool sdAdd) internal {
        poolLoan.updateBorrowAmount(user, amount, amountAdd);
        poolLoan.updateSecurityDeposit(user, sd, sdAdd);


    }

    function _isEnoughToken(uint256 maxDebt, uint256 accountDebt,uint256 security_deposit, uint256 nftPrice) internal view returns (uint256){
        require(security_deposit  + maxDebt >= accountDebt, "Not enough security deposit");
        uint256 decreaseDeposit = security_deposit -accountDebt + maxDebt;
        uint256 minTokenUsed = nftPrice.percentMul(percentSecurityDeposit) - decreaseDeposit.mul(nftPrice).div(maxDebt);
        return minTokenUsed;
    }


//    是不是admin其实就一个区别，就是通过pool去拿钱
//    function LiquidateLoanByAdmin(address liquidityAddress,address borrower,address nftAsset, uint256 nftTokenId,uint256 amount ) external  onlyOwner{
//        if (isLiquidate(borrower)){
//            revert IsNotLiquidity(borrower);
//        }
//        DataTypes.LiquityData memory lData;
//        (lData.borrowDebt, lData.borrowSecurityDeposit, lData.borrowMaxDebt) = healthFactor(borrower);
//        lData.liquityAddress = liquidityAddress;
//
//        uint256 loanID = poolLoan.getCollateralLoanId(nftAsset,nftTokenId);
//        DataTypes.LoanData memory loan = poolLoan.getLoan(loanID);
//        lData.price = nftOracle.getFinalPrice(nftAsset);
//        uint8 nftType = nftOracle.getAssetType(nftAsset);
//        //给被清算人消债，也分两种情况，一种是debt > totalLock, 一种是debt < totalLock
//        //第一种情况是常规情况，
//        //第二种情况的清算方式，其实区别就在于decreaseSecurityDeposit的算法上
//        //第二种情况其实不需要再用securityDeposit 去补差价
//        lData.decreaseAmount = lData.price;
//        uint256 nftDepositNow = 0;
//        if (lData.borrowDebt.percentMul(percentSecurityDeposit) > lData.borrowSecurityDeposit && lData.borrowDebt < lData.borrowMaxDebt){
//            //这种情况就是第二种情况
//            nftDepositNow = lData.borrowSecurityDeposit.mul(lData.borrowDebt).div(lData.borrowMaxDebt);
//            lData.decreaseSecurityDeposit = nftDepositNow;
//        } else{
//            //如果不满足上述条件，那就是第一种情况，就是常规情况
//            //这个 时候首先补差价，补完差价之后，再去算decreaseSecurityDeposit，按照（剩余*nft价格）/总价值
//            lData.decreaseAmount += lData.borrowDebt - lData.borrowMaxDebt;
//            lData.decreaseSecurityDeposit = lData.borrowDebt - lData.borrowMaxDebt ;
//            nftDepositNow = (lData.borrowSecurityDeposit - lData.decreaseSecurityDeposit).mul(lData.price).div(lData.borrowDebt);
//            lData.decreaseSecurityDeposit += nftDepositNow;
//        }
//        poolLoan.liquidateLoan(loan.borrower, lData.liquityAddress, loan.loanId, false);
//        string memory nftName = nftOracle.getAssetName(nftAsset);
//        poolLoan.createLoan(lData.liquityAddress, nftAsset, nftTokenId, nftName, false, 0, false);
//        uint256 burnAmount;
//        burnAmount= _isEnoughToken(lData.borrowMaxDebt, lData.borrowDebt ,lData.borrowSecurityDeposit, lData.price);
//        _layerUserBalance[nftType][lData.liquityAddress] = _layerUserBalance[nftType][lData.liquityAddress].sub(burnAmount);
//        lData.userIncreaseAmount = lData.price;
//        lData.userIncreaseSecurityDeposit = lData.price.percentMul(percentSecurityDeposit);
//        //把借的钱还给池子，钱从哪里来，就从nft重新存来再借
//        _updateAMountAndDeposit(lData.liquityAddress, lData.price, lData.price.percentMul(percentSecurityDeposit), true, true);
//        nftusdToken.burn(address(this), burnAmount);
//        nftusdToken.mint(lData.liquityAddress, lData.price.percentMul(percentSecurityDeposit).percentMul(percentBorrow).sub(lData.price - nftDepositNow - lData.userBalance));
//
//    }

    function _liquidate(address initiator, uint256 borrowAmount, uint256 securityDeposit) internal {
        _updateAMountAndDeposit(initiator, borrowAmount, securityDeposit, false, false);
        totalSecurityDeposit = totalSecurityDeposit - securityDeposit;
    }


    function isLiquidate(address user) public view returns (bool) {
        (uint256 accountDebt,uint256 securityDeposit,uint256 maxDebt) = _getUserDebtMessage(user);
        if (accountDebt.percentMul(percentSecurityDeposit) > securityDeposit){
            return true;
        }else{
            if (accountDebt > maxDebt){
                return true;
            }
        }
        return false;
    }

    function getTotalSecurityDeposit() external view returns (uint256) {
        return totalSecurityDeposit;
    }

    function getTotalExtractionFee() external view returns (uint256) {
        return totalExtractionFee;
    }

    function healthFactor(address user) public view  returns (uint256 accountDebt,uint256 securityDeposit, uint256 totalNFTLocked){
        uint256[] memory loanIds = poolLoan.getLoanIds(user);
        uint256 nftDebtPrice;
        address nftAsset;
        accountDebt = poolLoan.getBorrowAmount(user);
        securityDeposit = poolLoan.getSecurityDeposit(user);
        for (uint256 i = 0; i < loanIds.length; i++) {
            (nftAsset, ,) = poolLoan.getLoanCollateralAndReserve(loanIds[i]);
            nftDebtPrice = nftOracle.getFinalPrice(nftAsset);
            totalNFTLocked += nftDebtPrice;
        }
        return (accountDebt,securityDeposit,totalNFTLocked);
    }


    function _getUserDebtMessage(address user) public view returns  (uint256 accountDebt,uint256 securityDeposit, uint256 totalNFTLocked){
        uint256[] memory loanIds = poolLoan.getLoanIds(user);
        uint256 nftDebtPrice;
        address nftAsset;
        bool isUpLayer;
        accountDebt = poolLoan.getBorrowAmount(user);
        securityDeposit = poolLoan.getSecurityDeposit(user);
        for (uint256 i = 0; i < loanIds.length; i++) {
            (nftAsset, ,isUpLayer) = poolLoan.getLoanCollateralAndReserve(loanIds[i]);
            nftDebtPrice = nftOracle.getFinalPrice(nftAsset);
            if (isUpLayer){
                nftDebtPrice = nftDebtPrice.percentMul(percentBorrow);
            }
            totalNFTLocked += nftDebtPrice;
        }
        return (accountDebt,securityDeposit,totalNFTLocked);
    }

    function getDeposit(uint8 types, address user) external view returns (uint256) {
        return _layerUserBalance[types][user];
    }

    function getThreshold(uint8 types) external view returns (uint256) {
        return _layerThreshold[types];
    }

    function getLoanIds(address user) external view returns (uint256[] memory) {
        return poolLoan.getLoanIds(user);
    }

    function getLoanCollateralAndReserve(uint256 loanId) external view returns (address nftAsset, uint256 nftTokenId, bool isUpLayer) {
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

    function _requireNonZeroAmount(uint _amount) internal pure {
        if (_amount <= 0) {
            revert AmountMustGreaterThanZero(_amount);
        }
    }

    function getReward(uint8 types) public  updateReward(types,msg.sender) {

        for (uint i; i < layerRewardTokens[types].length; i++) {
            address _rewardsToken = layerRewardTokens[types][i];
            uint256 reward = layerRewards[types][msg.sender][_rewardsToken];
            if (reward > 0) {
                layerRewards[types][msg.sender][_rewardsToken] = 0;
                IERC20Upgradeable(_rewardsToken).transfer(msg.sender, reward);
                emit RewardPaid(msg.sender, _rewardsToken, types, reward);
            }
        }
    }

    function notifyRewardAmount(uint8 types, address _rewardsToken, uint256 reward) public updateReward(types, address(0)) {
    IERC20Upgradeable(_rewardsToken).transferFrom(msg.sender, address(this), reward);
        if (block.timestamp >= _layerRewardData[types][_rewardsToken].periodFinish) {
            _layerRewardData[types][_rewardsToken].rewardRate = reward.div(_layerRewardData[types][_rewardsToken].rewardsDuration);
        } else {
            uint256 remaining = _layerRewardData[types][_rewardsToken].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(_layerRewardData[types][_rewardsToken].rewardRate);
            _layerRewardData[types][_rewardsToken].rewardRate = reward.add(leftover).div(_layerRewardData[types][_rewardsToken].rewardsDuration);
        }

        _layerRewardData[types][_rewardsToken].lastUpdateTime = block.timestamp;
        _layerRewardData[types][_rewardsToken].periodFinish = block.timestamp.add(_layerRewardData[types][_rewardsToken].rewardsDuration);
//        emit RewardAdded(reward);
    }


    function setRewardsDuration(uint8 types, address _rewardsToken, uint256 _rewardsDuration) external {

        if (block.timestamp <= _layerRewardData[types][_rewardsToken].periodFinish){
            revert RewardPeriodNotFinish(block.timestamp, _layerRewardData[types][_rewardsToken].periodFinish);
        }
//        require(_layerRewardData[types][_rewardsToken].rewardsDistributor == msg.sender);
        require(_rewardsDuration > 0, "Reward duration must be non-zero");
        _layerRewardData[types][_rewardsToken].rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(_rewardsToken, types, rewardData[_rewardsToken].rewardsDuration);
    }


    modifier updateReward(uint8 types, address account) {
        for (uint i; i < layerRewardTokens[types].length; i++) {
            address token = layerRewardTokens[types][i];
            _layerRewardData[types][token].rewardPerTokenStored = rewardPerToken(types, token);
            _layerRewardData[types][token].lastUpdateTime = lastTimeRewardApplicable(types, token);
            if (account != address(0)) {
                layerRewards[types][account][token] = earned(types, account, token);
//                rewards[account][token] = earned(account, token);
                layerUserRewardPerTokenPaid[types][account][token] = _layerRewardData[types][token].rewardPerTokenStored;
//                userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
    }

    function addReward(
    uint8 types,
        address _rewardsToken,
        uint256 _rewardsDuration
    )
    private
    {
        require(_layerRewardData[types][_rewardsToken].rewardsDuration == 0);
        layerRewardTokens[types].push(_rewardsToken);
        _layerRewardData[types][_rewardsToken].rewardsDuration = _rewardsDuration;
    }


    function lastTimeRewardApplicable(uint8 types, address _rewardsToken) public view returns (uint256) {
        return Math.min(block.timestamp, _layerRewardData[types][_rewardsToken].periodFinish);
        //_layerRewardData[types][_rewardsToken].periodFinish
    }

    function rewardPerToken(uint8 types,address _rewardsToken) public view returns (uint256) {
        if (_layerTotalNFTUSDDeposits[types] == 0) {
            return _layerRewardData[types][_rewardsToken].rewardPerTokenStored;
        }
        return
        _layerRewardData[types][_rewardsToken].rewardPerTokenStored.add(
            lastTimeRewardApplicable(types,_rewardsToken).sub(_layerRewardData[types][_rewardsToken].lastUpdateTime).mul(_layerRewardData[types][_rewardsToken].rewardRate).mul(1e18).div(_layerTotalNFTUSDDeposits[types])
        );
    }

    function earned(uint8 types, address account, address _rewardsToken) public view returns (uint256) {
        return _layerUserBalance[types][account].mul(rewardPerToken(types,_rewardsToken).sub(layerUserRewardPerTokenPaid[types][account][_rewardsToken])).div(1e18).add(layerRewards[types][account][_rewardsToken]);
    }



    //添加奖励
    function addExtraReward(
        address _rewardsToken,
        uint256 _rewardsDuration
    )
    public
    onlyOwner
    {
        require(rewardData[_rewardsToken].rewardsDuration == 0);
        rewardTokens.push(_rewardsToken);
        rewardData[_rewardsToken].rewardsDuration = _rewardsDuration;
    }

    function lastTimeExtraRewardApplicable(address _rewardsToken) public view returns (uint256) {
        return Math.min(block.timestamp, rewardData[_rewardsToken].periodFinish);
    }

    function extraRewardPerToken(address _rewardsToken) public view returns (uint256) {
        if (_layerTotalNFTUSDDeposits[0] == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
        rewardData[_rewardsToken].rewardPerTokenStored.add(
            lastTimeExtraRewardApplicable(_rewardsToken).sub(rewardData[_rewardsToken].lastUpdateTime).mul(rewardData[_rewardsToken].rewardRate).mul(1e18).div(_layerTotalNFTUSDDeposits[0])
        );
    }

    function extraEarned(address account, address _rewardsToken) public view returns (uint256) {
        return _layerUserBalance[0][account].mul(extraRewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[account][_rewardsToken])).div(1e18).add(rewards[account][_rewardsToken]);
    }

    function getExtraRewardForDuration(address _rewardsToken) external view returns (uint256) {
        return rewardData[_rewardsToken].rewardRate.mul(rewardData[_rewardsToken].rewardsDuration);
    }

    function getExtraReward() public  updateExtraReward(msg.sender) {

        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20Upgradeable(_rewardsToken).transfer(msg.sender, reward);
                emit ExtraRewardPaid(msg.sender, _rewardsToken, reward);
            }
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyExtraRewardAmount(address _rewardsToken, uint256 reward) public  {
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20Upgradeable(_rewardsToken).transferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= rewardData[_rewardsToken].periodFinish) {
            rewardData[_rewardsToken].rewardRate = reward.div(rewardData[_rewardsToken].rewardsDuration);
        } else {
            uint256 remaining = rewardData[_rewardsToken].periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardData[_rewardsToken].rewardRate);
            rewardData[_rewardsToken].rewardRate = reward.add(leftover).div(rewardData[_rewardsToken].rewardsDuration);
        }

        rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
        rewardData[_rewardsToken].periodFinish = block.timestamp.add(rewardData[_rewardsToken].rewardsDuration);
//        emit RewardAdded(reward);
    }
    /* ========== MODIFIERS ========== */

    modifier updateExtraReward(address account) {
        for (uint i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];
            rewardData[token].rewardPerTokenStored = extraRewardPerToken(token);
            rewardData[token].lastUpdateTime = lastTimeExtraRewardApplicable(token);
            if (account != address(0)) {
                rewards[account][token] = extraEarned(account, token);
                userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
            }
        }
        _;
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