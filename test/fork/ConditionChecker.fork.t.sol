// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ChickenBondsLike} from "../../src/interfaces/ChickenBondsLike.sol";
import {UniswapNonFungiblePositionManagerLike} from "../../src/interfaces/UniswapNonFungiblePositionManagerLike.sol";
import {ConditionChecker, Operator, Condition} from "../../src/ConditionChecker.sol";


contract ConditionCheckerForkTest is Test {
    using ConditionChecker for Condition;
    using ConditionChecker for Condition[];

    function setUp() external {
        vm.createSelectFork("mainnet");
    }

    function test_ChickenBonds_1() external {
        address CHICKEN_BONDS_ADDRESS = 0xa8384862219188a8f03c144953Cf21fc124029Ee;

        uint256 tokenId = 2510;

        uint256 amount = 1000e18;
        uint256 timestamp = 1685078207;

        Condition[] memory conditions = new Condition[](2);
        // Bond with amount > 1000
        conditions[0] = Condition({
            token: CHICKEN_BONDS_ADDRESS,
            stateSelector: ChickenBondsLike.getBondAmount.selector,
            dynamicInputIndex: 0,
            staticInputs: new uint256[](0),
            returnDataWordIndex: 0,
            operator: Operator.gt,
            value: amount
        });
        // Bond with end time after 26th May 2023
        conditions[1] = Condition({
            token: CHICKEN_BONDS_ADDRESS,
            stateSelector: ChickenBondsLike.getBondEndTime.selector,
            dynamicInputIndex: 0,
            staticInputs: new uint256[](0),
            returnDataWordIndex: 0,
            operator: Operator.ge,
            value: timestamp
        });

        uint256 stateAmount = ChickenBondsLike(CHICKEN_BONDS_ADDRESS).getBondAmount(tokenId);
        uint256 stateTimestamp = ChickenBondsLike(CHICKEN_BONDS_ADDRESS).getBondEndTime(tokenId);
        bool isValid = stateAmount > amount && stateTimestamp >= timestamp;

        assertEq(conditions.checkStateConditions(tokenId), isValid);
    }

    function test_Uniswap_1() external {
        address UNISWAP_V3_POSITION_ADDRESS = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

        uint256 tokenId = 540426;

        uint256 liquidity = 0.05 ether;
        address token1 = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

        Condition[] memory conditions = new Condition[](2);
        // Position with liquidity > 0.05 ether
        conditions[0] = Condition({
            token: UNISWAP_V3_POSITION_ADDRESS,
            stateSelector: UniswapNonFungiblePositionManagerLike.positions.selector,
            dynamicInputIndex: 0,
            staticInputs: new uint256[](0),
            returnDataWordIndex: 7,
            operator: Operator.ge,
            value: liquidity
        });
        // Position token 1 == USDC
        conditions[1] = Condition({
            token: UNISWAP_V3_POSITION_ADDRESS,
            stateSelector: UniswapNonFungiblePositionManagerLike.positions.selector,
            dynamicInputIndex: 0,
            staticInputs: new uint256[](0),
            returnDataWordIndex: 3,
            operator: Operator.eq,
            value: uint256(uint160(token1))
        });

        (,,,address stateToken1,,,,uint128 stateLiquidity,,,,) = UniswapNonFungiblePositionManagerLike(UNISWAP_V3_POSITION_ADDRESS).positions(tokenId);
        bool isValid = stateLiquidity > liquidity && stateToken1 == token1;

        assertEq(conditions.checkStateConditions(tokenId), isValid);
    }

}