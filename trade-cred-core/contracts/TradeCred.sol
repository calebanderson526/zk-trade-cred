//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ISemaphore.sol";
import "./IOneSplit.sol";

contract TradeCred {

    ISemaphore public semaphore;
    IOneSplit public oneSplit;

    uint256 constant plus10GroupId = 1;
    uint256 constant plus20GroupId = 2;
    uint256 constant plus30GroupId = 3;
    uint256 constant plus40GroupId = 4;
    uint256 constant plus50GroupId = 5;
    uint256 constant plus60GroupId = 6;
    uint256 constant plus70GroupId = 7;
    uint256 constant plus80GroupId = 8;
    uint256 constant plus90GroupId = 9;
    uint256 constant plus100GroupId = 10;

    struct Position {
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        uint256 amountOut;
    }

    mapping(uint256 => uint256) groupIdToRequiredProfitRatio;
    mapping(address => Position[]) addressToPositions;
    mapping(address => mapping(uint256 => uint256)) lastPositionProoftime;
    mapping(address => mapping(uint256 => uint256)) addressToCredibility;

    constructor(address semaphoreAddress, address oneSplitAddress) {
        semaphore = ISemaphore(semaphoreAddress);
        oneSplit = IOneSplit(oneSplitAddress);

        semaphore.createGroup(plus10GroupId, 20, address(this));
        semaphore.createGroup(plus20GroupId, 20, address(this));
        semaphore.createGroup(plus30GroupId, 20, address(this));
        semaphore.createGroup(plus40GroupId, 20, address(this));
        semaphore.createGroup(plus50GroupId, 20, address(this));
        semaphore.createGroup(plus60GroupId, 20, address(this));
        semaphore.createGroup(plus70GroupId, 20, address(this));
        semaphore.createGroup(plus80GroupId, 20, address(this));
        semaphore.createGroup(plus90GroupId, 20, address(this));
        semaphore.createGroup(plus100GroupId, 20, address(this));

        // ratio to check profit performance is
        // (amountOut * 100) / (amountOut * Percentage Gain)
        groupIdToRequiredProfitRatio[plus10GroupId] = 1000; // (amountOut * 100) / (amountOut * 0.10)
        groupIdToRequiredProfitRatio[plus20GroupId] = 500; // (amountOut * 100) / (amountOut * 0.20)
        groupIdToRequiredProfitRatio[plus30GroupId] = 333; // (amountOut * 100) / (amountOut * 0.30)
        groupIdToRequiredProfitRatio[plus40GroupId] = 250; // (amountOut * 100) / (amountOut * 0.40)
        groupIdToRequiredProfitRatio[plus50GroupId] = 200; // (amountOut * 100) / (amountOut * 0.50)
        groupIdToRequiredProfitRatio[plus60GroupId] = 167; // (amountOut * 100) / (amountOut * 0.60)
        groupIdToRequiredProfitRatio[plus70GroupId] = 143; // (amountOut * 100) / (amountOut * 0.70)
        groupIdToRequiredProfitRatio[plus80GroupId] = 125; // (amountOut * 100) / (amountOut * 0.80)
        groupIdToRequiredProfitRatio[plus90GroupId] = 111; // (amountOut * 100) / (amountOut * 0.90)
        groupIdToRequiredProfitRatio[plus100GroupId] = 100; // (amountOut * 100) / (amountOut * 1)
    }
    /*
     @notice function to open a position, it uses the 1inch aggregator to route the trade
     @param fromToken starting token
     @param destToken token to receive
     @param minReturn minimum amount to receive
     @return the amount received
    */
    function openPosition(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    ) public payable returns (uint256 returnAmount) {
        uint256 ret = oneSplit.swap(
            fromToken,
            destToken,
            amount,
            minReturn,
            distribution,
            flags
        );
        Position memory curPos = Position(fromToken, destToken, amount, ret);
        addressToPositions[msg.sender].push(curPos);
        return ret;
    }

    /*
     @notice function to start a proof of trade performance, adds identity to a merkle tree
     @param identityCommitment identity commited to the tree
     @param positionId index of the position in msg.sender's addressToPositions
     @param plusGroupId id of the trade performance group to be added to
    */
    function joinGroup(
        uint256 identityCommitment,
        uint256 positionId,
        uint256 plusGroupId
    ) external {
        Position memory pos = addressToPositions[msg.sender][positionId];
        (uint256 newAmountOut, ) = oneSplit.getExpectedReturn(
            pos.tokenIn,
            pos.tokenOut,
            pos.amountIn,
            0,
            0
        );
        require(newAmountOut > pos.amountOut, "No profit");
        uint256 requiredProfitRatio = groupIdToRequiredProfitRatio[plusGroupId];
        uint256 delta = newAmountOut - pos.amountOut;
        uint256 profitRatio = (pos.amountOut * 100) / delta;
        require(profitRatio <= requiredProfitRatio, "Not enough alpha");
        semaphore.addMember(plusGroupId, identityCommitment);
        lastPositionProoftime[msg.sender][positionId] = block.timestamp;
    }

    /*
     @notice function to prove trade performance
     @param greeting greeting for the semaphore verifier
     @param merkleTreeRoot root of group merkle tree
     @param nullifierHash nullifierHash for the proof
     @param proof the proof to be verified
     @param plusGroupId the id for the trade performance group
    */
    function proveTradePerformance(
        bytes32 greeting,
        uint256 merkleTreeRoot,
        uint256 nullifierHash,
        uint256[8] calldata proof,
        uint256 plusGroupId
    ) external {
        semaphore.verifyProof(plusGroupId, merkleTreeRoot, uint256(greeting), nullifierHash, plusGroupId, proof);
        addressToCredibility[msg.sender][plusGroupId] += 1;
    }
}
