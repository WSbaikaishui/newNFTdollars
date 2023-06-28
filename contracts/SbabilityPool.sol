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
    mapping(uint8 => mapping(address =>Reward)) private _layerRewardData;

    // user -> reward token -> amount
    mapping(uint8 => mapping(address => mapping(address => uint256))) public layerRewardPerTokenPaid;
    mapping(uint8 => mapping(address => mapping(address => uint256)) )public layerRewards;
    mapping(uint8 => address[]) public layerRewardTokens;







    /* ========== EVENTS ========== */

    event RewardAdded(uint8 types,uint256 reward);
    event Staked(address indexed user, uint8 types,uint256 amount);
    event Withdrawn(address indexed user,uint8 types, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint256 newDuration);


    event Recovered(address token, uint256 amount);
    event Extraction(address indexed initiator, address indexed onBehalfOf, uint256 extractionAmount);
    event Repay(address indexed initiator, address indexed borrower, uint256 payAmount);
    
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
            addReward(_ndlToken,1);
            addReward(_nftUSDToken,1);
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
        function deposit(uint8 types,uint256 _amount) external updateReward(msg.sender) {
            address sender = msg.sender;
            _requireNonZeroAmount(_amount);
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
        function withdraw(uint8 types, uint256 _amount) public updateReward(msg.sender) {
            address sender = msg.sender;
            _requireNonZeroAmount(_amount);
            if (types ==0){
                _layerTotalNFTUSDDeposits[types] = _layerTotalNFTUSDDeposits[types].add(_amount);
                _layerUserBalance[types][sender] = _layerUserBalance[types][sender].add(_amount);
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


    function extraction(address onBehalfOf, uint256 amount)  public updateReward(address (0)) {
        require(onBehalfOf != address(0), "Errors.VL_INVALID_ONBEHALFOF_ADDRESS");
        require(amount > 0, "Errors.VL_INVALID_AMOUNT");
        require(!isLiquidate(msg.sender), "Errors.VL_INVALID_LIQUIDATE");
        DataTypes.ExtractionData memory extractionData;
        extractionData.borrower = msg.sender;
        (extractionData.accountDebt,extractionData.securityDeposit, extractionData.maxDebt) = healthFactor(extractionData.borrower);

        if ( extractionData.maxDebt > extractionData.accountDebt + amount ){
            extractionData.amount = amount;
        }else{
            extractionData.amount = extractionData.maxDebt.sub(extractionData.accountDebt);
        }

        extractionData.extractionFee = extractionData.amount.percentMul(borrowFee);
        extractionData.securityDeposit = amount.percentMul(percentSecurityDeposit);

        totalSecurityDeposit = totalSecurityDeposit.add(extractionData.securityDeposit);
        totalExtractionFee = totalExtractionFee.add(extractionData.extractionFee);
        //mint NFTUSD to contract and mint NFTUSD to onBehalfOf
        nftusdToken.mint(address(this), extractionData.securityDeposit);
        nftusdToken.mint(onBehalfOf, extractionData.amount.sub(extractionData.securityDeposit) );

     //the extraction fee is sent to  pool ,this is the reward for the pool
        ndlToken.sendNDLToPool(extractionData.borrower,extractionData.extractionFee);
        totalNDLEarned = totalNDLEarned.add(extractionData.extractionFee);

        poolLoan.updateBorrowAmount(extractionData.borrower,extractionData.amount, true);
        poolLoan.updateSecurityDeposit(extractionData.borrower,extractionData.securityDeposit, true);
        emit Extraction(extractionData.borrower, onBehalfOf, extractionData.amount);

    }


    function repay(address onBehalfOf, uint256 amount)  public  {
        require(onBehalfOf != address(0), "Errors.VL_INVALID_ONBEHALFOF_ADDRESS");
        require(amount > 0, "Errors.VL_INVALID_AMOUNT");
        address initiator = msg.sender;
        uint256 accountDebt = poolLoan.getBorrowAmount(onBehalfOf);
        require(accountDebt > 0,"no debt");

        if (accountDebt < amount){
            amount = accountDebt;
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
        poolLoan.updateBorrowAmount(onBehalfOf,amount, false);
        poolLoan.updateSecurityDeposit(onBehalfOf,amount.percentMul(percentSecurityDeposit), false);

       emit Repay(initiator,  onBehalfOf, amount);

    }


        //redeem NFT
    //逻辑就是先如果是自己赎回，那就看看赎回之后会不会触发清算，不会触发那就直接赎回，会触发那就先还款再赎回
    //详细来说，就是先看这个nft是不是升级层了，因为升级层会导致可以借的钱变少，然后判断会不会超过最大借款，超过的话要付一笔钱的
function redeemNFT(address nftAsset, uint256 nftTokenId,uint256 amount)  public  {
    uint256 price = nftOracle.getFinalPrice(nftAsset);
    uint256 loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);
    require(loanId != 0,"this nft has not been locked");
    address initiator = msg.sender;
    uint8 nftType = nftOracle.getAssetType(nftAsset);
    DataTypes.LoanData memory loanData = poolLoan.getLoan(loanId);
    (uint256 debt, , uint256 maxDebt) = healthFactor(initiator);

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
        require(price > amount,"amount is lower than this NFT");
        require(nftType != 2,"this nft is  a collateral nft, it could not be redeemed");
        require(nftType != 1 || !loanData.isUpLayer,"this nft is not a collateral");
        require(price.percentMul(loanData.threshold) > amount,"amount is lower than for this NFT");
        //Todo 逻辑有问题
        if (amount > debt){
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

    function liquidate(address borrower,address nftAsset, uint256 nftTokenId,uint256 amount, bool isLock, bool isUpLayer, uint256 threshold) external {
        require(!isLiquidate(borrower),"this user is not liquidatable");
        DataTypes.LiquityData memory lData;
        (lData.borrowDebt, lData.borrowSecurityDeposit, lData.borrowMaxDebt) = _getUserDebtMessage(borrower);
        lData.liquityAddress = msg.sender;

        uint256 loanID = poolLoan.getCollateralLoanId(nftAsset,nftTokenId);
        DataTypes.LoanData memory loan = poolLoan.getLoan(loanID);
        lData.price = nftOracle.getFinalPrice(nftAsset);

        //判断用户的钱够不够
        lData.userBalance = nftusdToken.balanceOf(lData.liquityAddress);
        require(lData.userBalance > _isEnoughToken(lData.borrowMaxDebt, lData.borrowDebt,lData.borrowSecurityDeposit, lData.price),"user balance is not enough");
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
            poolLoan.updateBorrowAmount(lData.liquityAddress, lData.userIncreaseAmount, true);
            poolLoan.updateSecurityDeposit(lData.liquityAddress, lData.userIncreaseSecurityDeposit, true);
            nftusdToken.mint(lData.liquityAddress, lData.userIncreaseAmount.percentMul(percentBorrow).sub(lData.price - nftDepositNow - lData.userBalance));
            ndlToken.sendNDLToPool(lData.liquityAddress, stabilityPoolReward);

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


    function _isEnoughToken(uint256 maxDebt, uint256 accountDebt,uint256 security_deposit, uint256 nftPrice) internal view returns (uint256){
       uint256 decreaseDeposit = security_deposit -accountDebt + maxDebt;
        require(decreaseDeposit > 0,"decreaseDeposit is not enough to cover this debt");
         uint256 minTokenUsed = nftPrice.percentMul(percentSecurityDeposit) - decreaseDeposit.mul(nftPrice).div(maxDebt);
        return minTokenUsed;
    }


//    //wendingchi
//    function LiquidateLoanByAdmin(address borrower,address nftAsset, uint256 nftTokenId,uint256 amount, bool isLock, bool isUpLayer, uint256 threshold) external  OnlyAdmin{
//        require(!isLiquidate(borrower),"this user is not liquidatable");
//        DataTypes.LiquityData memory liquityData;
//        (liquityData.borrowDebt, liquityData.borrowSecurityDeposit, liquityData.borrowMaxDebt) = healthFactor(borrower);
//        liquityData.liquityAddress = msg.
//
//
//
//    }

    function _liquidate(address initiator, uint256 borrowAmount, uint256 securityDeposit) internal {
        poolLoan.updateBorrowAmount(initiator,borrowAmount,false);
        poolLoan.updateSecurityDeposit(initiator,securityDeposit,false);
        totalSecurityDeposit = totalSecurityDeposit - securityDeposit;
    }

    //_repay function ,the amount need to be the one which is less between debt and amount
    //这里的逻辑是先burn掉多的钱，就是超出maxDebt的钱，然后更新一下这个钱，然后
    function _repay(address initiator, address borrower, uint256 payAmount ) internal {
            nftusdToken.burn(initiator, payAmount.percentMul(percentBorrow));
            nftusdToken.burn(address(this), payAmount.percentMul(percentBorrow));
            poolLoan.updateBorrowAmount(initiator, payAmount, false);
            poolLoan.updateSecurityDeposit(initiator, payAmount.percentMul(percentSecurityDeposit), false);

            totalSecurityDeposit = totalSecurityDeposit.sub(payAmount.percentMul(percentSecurityDeposit));

            emit Repay(initiator, borrower, payAmount);
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
//        emit RewardAdded(reward);
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