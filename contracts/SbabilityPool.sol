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
        // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
        uint128 public currentScale;

        // With each offset that fully empties the Pool, the epoch is incremented by 1
        uint128 public currentEpoch;

        // Tracker for NFTUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
        uint internal constant DECIMAL_PRECISION = 1e18;
        uint256 internal totalNFTUSDDeposits;
        struct Snapshots {
            uint S;
            uint P;
            uint G;
            uint128 scale;
            uint128 epoch;
        }
        mapping (address => uint256) public deposits;
        mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct

        mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToSum;
    mapping (uint128 => mapping(uint128 => uint)) public epochToScaleToG;

        uint256 public totalSecurityDeposit;
        uint256 public totalExtractionFee;
    uint256 internal NFTUSDGain;  // deposited ether tracker

    uint public P = DECIMAL_PRECISION;

        event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
        event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
        event EpochUpdated(uint128 _currentEpoch);
        event ScaleUpdated(uint128 _currentScale);

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
            percentBorrow = 9*1000;//percent 90%;
            borrowFee = 400; //percent 4%
            _renounceOwnership();
        }

        function getTotalNFTUSDDeposits() external view  returns (uint) {
            return totalNFTUSDDeposits;
        }

        /**
       * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying bTokens.
       * - E.g. User deposits 100 USDC and gets in return 100 bUSDC
       **/
        function deposit(uint _amount) external  {
            _requireNonZeroAmount(_amount);
            uint initialDeposit = deposits[msg.sender];
//            ICommunityIssuance communityIssuanceCached = communityIssuance;
//            _triggerNDLIssuance(communityIssuanceCached);
            uint depositorNFTUSDGain = getDepositorNFTUSDGain(msg.sender);
            _payOutNDLGains(msg.sender);
            _sendNFTUSDtoStabilityPool(msg.sender, _amount);
//            emit UserDepositChanged(msg.sender, newDeposit);
//            emit NFTUSDGainWithdrawn(msg.sender, depositorNFTUSDGain, LUSDLoss); // LUSD Loss required for event log
            _sendNFTUSDGainToDepositor(msg.sender, depositorNFTUSDGain);
        }
//
//        function withdraw(uint _amount) external override {
//            require(_amount != 0, "withdraw can't zero");
//            uint initialDeposit = deposits[msg.sender].initialValue;
//            _requireUserHasDeposit(initialDeposit);
//
////            ICommunityIssuance communityIssuanceCached = communityIssuance;
//
////            _triggerNDLIssuance(communityIssuanceCached);
//            uint depositorNFTUSDGain = getDepositorNFTUSDGain(msg.sender);
//            uint NFTUSDtoWithdraw;
//            if (_amount >= compoundedNFTUSDDeposit){
//                NFTUSDtoWithdraw = compoundedNFTUSDDeposit;
//            }else{
//                NFTUSDtoWithdraw = _amount;
//            }
//            uint NFTUSDtoWithdraw = LiquityMath._min(_amount, compoundedNFTUSDDeposit);
//            _payOutNDLGains(communityIssuanceCached, msg.sender);
//            _sendNFTUSDToDepositor(msg.sender, NFTUSDtoWithdraw);
//
//            // Update deposit
//            uint newDeposit = compoundedNFTUSDDeposit.sub(NFTUSDtoWithdraw);
//            _updateDepositAndSnapshots(msg.sender, newDeposit);
//            emit UserDepositChanged(msg.sender, newDeposit);
//            emit UserDepositChanged(msg.sender, newDeposit);
//
//
//            emit NFTUSDGainWithdrawn(msg.sender, depositorNFTUSDGain, LUSDLoss); // LUSD Loss required for event log
//
//            _sendNFTUSDGainToDepositor(depositorNFTUSDGain);
//
//        }
        // --- Reward calculator functions for depositor and front end ---

        /* Calculates the NFTUSD gain earned by the deposit since its last snapshots were taken.
        * Given by the formula:  E = d0 * (S - S(0))/P(0)
        * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
        * d0 is the last recorded deposit value.
        */
        function getDepositorNFTUSDGain(address _depositor) public view  returns (uint) {
            uint initialDeposit = deposits[_depositor];

            if (initialDeposit == 0) { return 0; }

            Snapshots memory snapshots = depositSnapshots[_depositor];

            uint NFTUSD = _getNFTUSDGainFromSnapshots(initialDeposit, snapshots);
            return NFTUSD;
        }

        function _getNFTUSDGainFromSnapshots(uint initialDeposit, Snapshots memory snapshots) internal view returns (uint) {
            /*
            * Grab the sum 'S' from the epoch at which the stake was made. The ETH gain may span up to one scale change.
            * If it does, the second portion of the ETH gain is scaled by 1e9.
            * If the gain spans no scale change, the second portion will be 0.
            */
            uint128 epochSnapshot = snapshots.epoch;
            uint128 scaleSnapshot = snapshots.scale;
            uint S_Snapshot = snapshots.S;
            uint P_Snapshot = snapshots.P;

            uint firstPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot].sub(S_Snapshot);
            uint secondPortion = epochToScaleToSum[epochSnapshot][scaleSnapshot.add(1)];

            uint NFTUSD = initialDeposit.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(DECIMAL_PRECISION);

            return NFTUSD;
        }

        function _sendNFTUSDToDepositor(address _depositor, uint NFTUSDWithdrawal) internal {
            if (NFTUSDWithdrawal == 0) {return;}
            nftusdToken.transferFrom(address(this), _depositor, NFTUSDWithdrawal);
            _decreaseNFTUSD(NFTUSDWithdrawal);
        }
        function _decreaseNFTUSD(uint _amount) internal {
            uint newTotalNFTUSDDeposits = totalNFTUSDDeposits.sub(_amount);
            totalNFTUSDDeposits = newTotalNFTUSDDeposits;
//            emit StabilityPoolNFTUSDBalanceUpdated(newTotalNFTUSDDeposits);
        }

        function _sendNFTUSDGainToDepositor(address _depositor,uint _amount) internal {
            if (_amount == 0) {return;}
            uint newNFTUSD = NFTUSDGain.sub(_amount);
            NFTUSDGain = newNFTUSD;
//            emit StabilityPoolNFTUSDBalanceUpdated(newNFTUSD);


            nftusdToken.transfer(_depositor,_amount);
//            emit NFTUSDPaidToDepositor(_depositor, _amount);
        }

        function _updateDepositAndSnapshots(address _depositor, uint _newValue) internal {

            deposits[_depositor] = _newValue;
            if (_newValue == 0) {
                delete depositSnapshots[_depositor];
//                emit DepositSnapshotUpdated(_depositor, 0, 0, 0);
                return;
            }
            uint128 currentScaleCached = currentScale;
            uint128 currentEpochCached = currentEpoch;
            uint currentP = P;

            // Get S and G for the current epoch and current scale
            uint currentS = epochToScaleToSum[currentEpochCached][currentScaleCached];
            uint currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

            // Record new snapshots of the latest running product P, sum S, and sum G, for the depositor
            depositSnapshots[_depositor].P = currentP;
            depositSnapshots[_depositor].S = currentS;
            depositSnapshots[_depositor].G = currentG;
            depositSnapshots[_depositor].scale = currentScaleCached;
            depositSnapshots[_depositor].epoch = currentEpochCached;

//            emit DepositSnapshotUpdated(_depositor, currentP, currentS, currentG);
        }

        function getDepositorNDLGain(address _depositor) public view  returns (uint) {
            uint initialDeposit = deposits[_depositor];
            if (initialDeposit == 0) {return 0;}
            /*
            * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
            * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
            * which they made their deposit.
            */
            uint kickbackRate =  DECIMAL_PRECISION ;

            Snapshots memory snapshots = depositSnapshots[_depositor];
            uint NDLGain = kickbackRate.mul(_getNDLGainFromSnapshots(initialDeposit, snapshots)).div(DECIMAL_PRECISION);
            return NDLGain;
        }

        function _getNDLGainFromSnapshots(uint initialStake, Snapshots memory snapshots) internal view returns (uint) {
            /*
             * Grab the sum 'G' from the epoch at which the stake was made. The NDL gain may span up to one scale change.
             * If it does, the second portion of the NDL gain is scaled by 1e9.
             * If the gain spans no scale change, the second portion will be 0.
             */
            uint128 epochSnapshot = snapshots.epoch;
            uint128 scaleSnapshot = snapshots.scale;
            uint G_Snapshot = snapshots.G;
            uint P_Snapshot = snapshots.P;

            uint firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot].sub(G_Snapshot);
            uint secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot.add(1)];

            uint NDLGain = initialStake.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(DECIMAL_PRECISION);

            return NDLGain;
        }

        function _payOutNDLGains(address _depositor) internal {
            // Pay out depositor's NDL gain
            uint depositorNDLGain = getDepositorNDLGain(_depositor);
//            _communityIssuance.sendNDL(_depositor, depositorNDLGain);
//            emit NDLPaidToDepositor(_depositor, depositorNDLGain);
        }

        function _sendNFTUSDtoStabilityPool(address _address, uint _amount) internal {
            nftusdToken.sendToPool(_address, address(this), _amount);
            uint newTotalNFTUSDDeposits = totalNFTUSDDeposits.add(_amount);
            totalNFTUSDDeposits = newTotalNFTUSDDeposits;
//            emit StabilityPoolNFTUSDBalanceUpdated(newTotalNFTUSDDeposits);
        }



        function borrow(
            address asset,
            uint256 amount,
            address nftAsset,
            uint256 nftTokenId,
            address onBehalfOf
        ) external payable  {
            require(onBehalfOf != address(0), "Errors.VL_INVALID_ONBEHALFOF_ADDRESS");
            address initiator = _msgSender();
            uint256 loanId = poolLoan.getCollateralLoanId(nftAsset, nftTokenId);
//            uint256 totalSupply = IERC721EnumerableUpgradeable(nftAsset).totalSupply();

            (uint256  nftfloorPrice, uint256  nftAverageSales,uint256  nftvolatility) = nftOracle.getAssetPrice(nftAsset);
            require(nftfloorPrice != 0,"no such nft supplyed");
            uint256  collectionScore ; //TODO 回头把这部分逻辑补充上去


            collectionScore = 1e4-nftvolatility+3*nftAverageSales;
            nftAverageSales = nftfloorPrice.percentMul(collectionScore);
            require(nftAverageSales > amount,"borrow amount is to high for this NFT");

            if (loanId == 0) {
                loanId = poolLoan.createLoan( initiator, onBehalfOf, nftAsset, nftTokenId, amount);
            } else {
                poolLoan.updateLoan(initiator, loanId, amount);
            }

            ndlToken.sendToNDLStaking(initiator,amount.percentMul(borrowFee));
            nftusdToken.mint( onBehalfOf, amount.percentMul(percentBorrow)); //TODO 定义percentBorrow

            nftusdToken.mint(address(this), amount - amount.percentMul(percentBorrow));//TODO 定义percentBorrow
            totalSecurityDeposit += amount - amount.percentMul(percentBorrow);

//            emit Borrow(
//                initiator,
//                asset,
//                amount,
//                nftAsset,
//                nftTokenId,
//                onBehalfOf,
//                loanId
//            );
    }


//    function _triggerNDLIssuance(ICommunityIssuance _communityIssuance) internal {
//        uint NDLIssuance = _communityIssuance.issueNDL();
//        _updateG(NDLIssuance);
//    }

    function _updateG(uint _NDLIssuance) internal {
        uint totalNFTUSD = totalNFTUSDDeposits; // cached to save an SLOAD
        /*
        * When total deposits is 0, G is not updated. In this case, the NDL issued can not be obtained by later
        * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
        *
        */
        if (totalNFTUSD == 0 || _NDLIssuance == 0) {return;}

//        uint NDLPerUnitStaked;
//        NDLPerUnitStaked =_computeNDLPerUnitStaked(_NDLIssuance, totalNFTUSD);
//
//        uint marginalNDLGain = NDLPerUnitStaked.mul(P);
//        epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale].add(marginalNDLGain);

//        emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
    }

//    function _computeNDLPerUnitStaked(uint _NDLIssuance, uint _totalNFTUSDDeposits) internal returns (uint) {
//        /*
//        * Calculate the NDL-per-unit staked.  Division uses a "feedback" error correction, to keep the
//        * cumulative error low in the running total G:
//        *
//        * 1) Form a numerator which compensates for the floor division error that occurred the last time this
//        * function was called.
//        * 2) Calculate "per-unit-staked" ratio.
//        * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
//        * 4) Store this error for use in the next correction when this function is called.
//        * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
//        */
//        uint NDLNumerator = _NDLIssuance.mul(DECIMAL_PRECISION).add(lastNDLError);
//
//        uint NDLPerUnitStaked = NDLNumerator.div(_totalNFTUSDDeposits);
////        lastNDLError = NDLNumerator.sub(NDLPerUnitStaked.mul(_totalNFTUSDDeposits));
//
//        return NDLPerUnitStaked;
//    }

//    function repay(
//        address nftAsset,
//        uint256 nftTokenId,
//        uint256 amount
//    ) external override nonReentrant whenNotPaused returns (uint256, bool) {
//        RepayLocalVars memory vars;
//        vars.initiator = _msgSender();
//        uint loadId = ILendPoolLoan(vars.loanAddress).getCollateralLoanId(nftAsset, nftTokenId);
//        require(loadId != 0,"no such debt nft");
//        (, vars.borrowAmount) = ILendPoolLoan(vars.poolLoan).getLoanReserveBorrowAmount(vars.loanId);
//
//        vars.repayAmount = vars.borrowAmount.mul(percentBorrow);
//        vars.isUpdate = false;
//        if ( amount < vars.repayAmount) {
//        vars.isUpdate = true;
//        vars.repayAmount = amount;
//        }
//
//        if (vars.isUpdate) {
//            ILendPoolLoan(vars.poolLoan).updateLoan(
//            vars.initiator,
//            vars.loanId,
//            0,
//            vars.repayAmount
//            );
//        } else {
//            ILendPoolLoan(vars.poolLoan).repayLoan(
//            vars.initiator,
//            vars.loanId,
//            vars.repayAmount
//            );
//        }
//
//        INDLToken(NDLToken).transferFrom(
//            vars.initiator,
//            address(this),
//            amount//TODO amount
//        );
//
//        IERC20(NFTUSDTokenAddress).burn(
//            vars.initiator,
//            amount //TODO 定义percentBorrow
//        );
//
//        INFTUSDToken(NFTUSDTokenAddress).burn(
//            address(this),
//            (vars.borrowAmount - vars.borrowAmount.percentMul(percentBorrow))*amount/vars.borrowAmount//TODO 定义percentBorrow
//        );
//        if (!vars.isUpdate) {
//            IERC721Upgradeable(loanData.nftAsset).safeTransferFrom(address(this), loanData.borrower, params.nftTokenId);
//        }
//        emit Repay(
//            vars.initiator,
//            vars.repayAmount,
//            nftAsset,
//            nftTokenId,
//            borrower,
//            vars.loanId
//        );
//        return (vars.repayAmount, !vars.isUpdate);
//    }

//    function liquidate(
//        address borrower,
//        address nftAsset,
//        uint256 nftTokenId
//    ) external override nonReentrant whenNotPaused returns (uint256) {
//        (uint256 accountDebt,uint256 totalNFTLocked) = healthFactor(borrower);
//        require(accountDebt < totalNFTLocked,"this is not the liquidate line");
//        uint256 loanID = poolLoan.getCollateralLoanId(nftAsset,nftTokenId);
//        DataTypes.LoanData loan = poolLoan.getLoan(loadID);
//        require(borrow != loan.borrower, "no right borrower");
//        //if reach the liquidate line
//        (uint256 nftfloorPrice, uint256 nftAverageSales,uint256 nftvolatility) = nftOracle.getAssetPrice(nftAsset);
//        uint collectionScore ; //TODO 回头把这部分逻辑补充上去
//        uint maxDebtPrice;
//        collectionScore = 1e4 - nftvolatility + 3 * nftAverageSales;
//        maxDebtPrice = nftfloorPrice.percentMul(collectionScore);
//        bool success =  INFTUSDToken(NFTUSDTokenAddress).transferFrom(
//        _msgSender(),
//        address(this),
//        maxDebtPrice
//        );
//
//        poolLoan.liquidateLoan(
//            loanId,
//            borrowAmount
//        );
//        nftusdToken.transferFrom(
//            _msgSender(),
//            address(this),
//            maxDebtPrice - loan.amount.percentMul(1e4-percentBorrow)
//        );
//        nftusdToken.burn(
//            address(this),
//            maxDebtPrice
//        );
//    uint256 newtotalSecurityDeposit = totalSecurityDeposit - loan.amount.percentMul(1e4-percentBorrow);
//    if (!success){
//        ndlToken.transferFrom(_msgSender(),address(this), amount.percentMul(borrowFee));
//    }
//        return 0;
//    }

//    function healthFactor(address user) external view nonReentrant whenNotPaused returns (uint256 accountDebt,uint256 totalNFTLocked){
//        var list = addressLoans[user];
//        require(list.length !=0,"no such user");
//        uint256 totalDebt;
//        uint256 totalNFTValue;
//        for (uint256 i = 0 ; i < list.length; i++){
//            if (_loads[list[i]].state != dataTypes.LoabState.active){
//                continue;
//            }
//            (uint256 nftfloorPrice, uint256 nftAverageSales,uint256 nftvolatility) = nftOracle.getAssetPrice(nftAsset);
//            uint collectionScore ; //TODO 回头把这部分逻辑补充上去
//            uint maxDebtPrice;
//            collectionScore = 1e4 - nftvolatility + 3 * nftAverageSales;
//            maxDebtPrice = nftfloorPrice.percentMul(collectionScore);
//            totalNFTLocked += maxDebtPrice;
//            accountDebt = _loads[list[i]].amount;
//        }
//        return;
//    }

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
        uint initialDeposit = deposits[_address];
        require(initialDeposit == 0, 'StabilityPool: User must have no deposit');
    }


}