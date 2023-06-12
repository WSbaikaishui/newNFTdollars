// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.8;



import {DataTypes} from "./dataType.sol";
import {WadRayMath} from "./libraries/math/WadRayMath.sol";
import {ILoanPool} from "./interfaces/ILoanPool.sol";
import {IStabilityPool} from "./interfaces/IStabilityPool.sol";

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";


contract LoanPool is Initializable, ILoanPool, ContextUpgradeable, IERC721ReceiverUpgradeable {
    using WadRayMath for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _loanIdTracker;
    mapping(uint256 => DataTypes.LoanData) private _loans;

    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
    mapping(address => uint256) private _nftTotalCollateral;
    mapping(address => mapping(address => uint256)) private _userNftCollateral;

    mapping(address => uint256[]) private _userLoans;


//    IStabilityPool private _stabilityPool;
    address private _stabilityPoolAddress;

    /**
     * @dev Only lending pool can call functions marked by this modifier
   **/
    modifier onlyStabilityPool() {
//        require(_msgSender() == address(_getStabilityPool()), "Errors.CT_CALLER_MUST_BE_LEND_POOL");
        require(_msgSender() == _stabilityPoolAddress, "Errors.CT_CALLER_MUST_BE_LEND_POOL");
        _;
    }
    // called once by the factory at time of deployment
    function initialize(address stabilityPool) external  initializer {
        __Context_init();

//        _stabilityPool = IStabilityPool(stabilityPool);
        _stabilityPoolAddress = stabilityPool;
        // Avoid having loanId = 0
        _loanIdTracker.increment();

//        emit Initialized(address(_getStabilityPool()));
    }



    function createLoan(
        address initiator,
        address onBehalfOf,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    ) external override onlyStabilityPool returns (uint256) {
        require(_nftToLoanIds[nftAsset][nftTokenId] == 0, "Errors.LP_NFT_HAS_USED_AS_COLLATERAL");

        uint256 loanId = _loanIdTracker.current();
        _loanIdTracker.increment();

        _nftToLoanIds[nftAsset][nftTokenId] = loanId;

        // transfer underlying NFT asset to pool
        IERC721Upgradeable(nftAsset).safeTransferFrom(initiator, address(this), nftTokenId);

        // Save Info
        DataTypes.LoanData storage loanData = _loans[loanId];
        loanData.loanId = loanId;
        loanData.state = DataTypes.LoanState.Active;
        loanData.borrower = onBehalfOf;
        loanData.nftAsset = nftAsset;
        loanData.nftTokenId = nftTokenId;
        loanData.amount = amount;

        _userNftCollateral[onBehalfOf][nftAsset] += 1;

        _nftTotalCollateral[nftAsset] += 1;
        _userLoans[initiator].push(loanId);
        emit LoanCreated(initiator, onBehalfOf, loanId, nftAsset, nftTokenId, amount);
        return (loanId);
}


    function updateLoan(
        address initiator,
        uint256 loanId,
        uint256 amountAdded,
        bool isAdd
    ) external override onlyStabilityPool {
    // Must use storage to change state
        DataTypes.LoanData storage loan = _loans[loanId];

        // Ensure valid loan state
        require(loan.state == DataTypes.LoanState.Active, "LPL_INVALID_LOAN_STATE");
        if (isAdd){
            loan.amount += amountAdded;
        }else{
            loan.amount -= amountAdded;
        }


        emit LoanUpdated(
        initiator,
        loanId,
        loan.nftAsset,
        loan.nftTokenId,
        amountAdded
        );
    }


    function repayLoan(
        address initiator,
        uint256 loanId,
        uint256 amount
    ) external override onlyStabilityPool {
    // Must use storage to change state
    DataTypes.LoanData storage loan = _loans[loanId];

        // Ensure valid loan state
        require(loan.state == DataTypes.LoanState.Active,"Loan is not active");


        // state changes and cleanup
        // NOTE: these must be performed before assets are released to prevent reentrance
        _loans[loanId].state = DataTypes.LoanState.Repaid;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, "LP_INVALIED_USER_NFT_AMOUNT");
        _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

        require(_nftTotalCollateral[loan.nftAsset] >= 1, "LP_INVALIED_NFT_AMOUNT");
        _nftTotalCollateral[loan.nftAsset] -= 1;

        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

        for (uint256 i = 0; i < _userLoans[initiator].length; i++) {
            if (_userLoans[initiator][i] == loanId) {
                _userLoans[initiator][i] = _userLoans[initiator][_userLoans[initiator].length - 1];
                _userLoans[initiator].pop();
                break;
            }
        }
        emit LoanRepaid(initiator, loanId, loan.nftAsset, loan.nftTokenId,  amount);

    }


    function liquidateLoan(
        address initiator,
        uint256 loanId,
        uint256 borrowAmount,
        bool isTransfer
    ) external override onlyStabilityPool {
        // Must use storage to change state
        DataTypes.LoanData storage loan = _loans[loanId];

        // Ensure valid loan state
        require(loan.state == DataTypes.LoanState.Active, "LPL_INVALID_LOAN_STATE");


        // state changes and cleanup
        // NOTE: these must be performed before assets are released to prevent reentrance
        _loans[loanId].state = DataTypes.LoanState.Defaulted;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(_userNftCollateral[loan.borrower][loan.nftAsset] >= 1, "LP_INVALIED_USER_NFT_AMOUNT");
        _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

        require(_nftTotalCollateral[loan.nftAsset] >= 1, "LP_INVALIED_NFT_AMOUNT");
        _nftTotalCollateral[loan.nftAsset] -= 1;
        if (isTransfer) {
            IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);
        }
        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(address(this), _msgSender(), loan.nftTokenId);

        for (uint256 i = 0; i < _userLoans[initiator].length; i++) {
            if (_userLoans[initiator][i] == loanId) {
                _userLoans[initiator][i] = _userLoans[initiator][_userLoans[initiator].length - 1];
                _userLoans[initiator].pop();
                break;
            }
        }
        emit LoanLiquidated(
            initiator,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            borrowAmount
        );
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



    function getLoanIds(address user) external view override returns (uint256[] memory) {
        return _userLoans[user];
    }
    function borrowerOf(uint256 loanId) external view override returns (address) {
        return _loans[loanId].borrower;
    }

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view override returns (uint256) {
        return _nftToLoanIds[nftAsset][nftTokenId];
    }

    function getLoan(uint256 loanId) external view override returns (DataTypes.LoanData memory loanData) {
        return _loans[loanId];
    }

    function getLoanCollateralAndReserve(uint256 loanId)
    external
    view
    override
    returns (
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount
    )
    {
        return (
            _loans[loanId].nftAsset,
            _loans[loanId].nftTokenId,
            _loans[loanId].amount
        );
    }

    function getNftCollateralAmount(address nftAsset) external view override returns (uint256) {
        return _nftTotalCollateral[nftAsset];
    }

    function getUserNftCollateralAmount(address user, address nftAsset) external view override returns (uint256) {
        return _userNftCollateral[user][nftAsset];
    }

    function getCurrentLoanId() public view returns (uint256) {
        return _loanIdTracker.current();
    }

//    function _getStabilityPool() internal view returns (IStabilityPool) {
//        return _stabilityPool;
//    }



}