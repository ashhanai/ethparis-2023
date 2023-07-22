// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ChickenBondsLike} from "../../src/interfaces/ChickenBondsLike.sol";
import {UniswapNonFungiblePositionManagerLike} from "../../src/interfaces/UniswapNonFungiblePositionManagerLike.sol";
import {ExpressionEvaluator, ComparisonExpression, ComparisonOperator, LogicalExpression, LogicalOperator} from "../../src/ExpressionEvaluator.sol";
import {Call} from "../../src/Getter.sol";


contract ExpressionEvaluatorForkTest is Test {
    using ExpressionEvaluator for ComparisonExpression;
    using ExpressionEvaluator for ComparisonExpression[];

    function setUp() external {
        vm.createSelectFork("mainnet");
    }

    // ChickenBond with amount > 1000 and end time after 26th May 2023
    function test_ChickenBonds_1() external {
        address CHICKEN_BONDS_ADDRESS = 0xa8384862219188a8f03c144953Cf21fc124029Ee;

        uint256 tokenId = 2510;

        uint256 amount = 1000e18;
        uint256 timestamp = 1685078207;

        ComparisonExpression[] memory comparisons = new ComparisonExpression[](2);
        comparisons[0] = ComparisonExpression({
            getter: Call({
                token: CHICKEN_BONDS_ADDRESS,
                selector: ChickenBondsLike.getBondAmount.selector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 0
            }),
            operator: ComparisonOperator.gt,
            value: amount
        });
        comparisons[1] = ComparisonExpression({
            getter: Call({
                token: CHICKEN_BONDS_ADDRESS,
                selector: ChickenBondsLike.getBondEndTime.selector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 0
            }),
            operator: ComparisonOperator.ge,
            value: timestamp
        });

        uint256 stateAmount = ChickenBondsLike(CHICKEN_BONDS_ADDRESS).getBondAmount(tokenId);
        uint256 stateTimestamp = ChickenBondsLike(CHICKEN_BONDS_ADDRESS).getBondEndTime(tokenId);
        bool isValid = stateAmount > amount && stateTimestamp >= timestamp;

        assertEq(comparisons.evaluateExpressionsTrue(tokenId), isValid);
    }

    // Position with liquidity > 0.05 ether and USDC as token0 or token1
    function test_Uniswap_1() external {
        address UNISWAP_V3_POSITION_ADDRESS = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

        uint256 tokenId = 540426;

        uint256 liquidity = 0.05 ether;
        address token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC

        ComparisonExpression[] memory comparisons = new ComparisonExpression[](2);
        comparisons[0] = ComparisonExpression({
            getter: Call({
                token: UNISWAP_V3_POSITION_ADDRESS,
                selector: UniswapNonFungiblePositionManagerLike.positions.selector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 7
            }),
            operator: ComparisonOperator.ge,
            value: liquidity
        });
        comparisons[1] = ComparisonExpression({
            getter: Call({
                token: UNISWAP_V3_POSITION_ADDRESS,
                selector: UniswapNonFungiblePositionManagerLike.positions.selector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 2
            }),
            operator: ComparisonOperator.eq,
            value: uint256(uint160(token))
        });
        comparisons[2] = ComparisonExpression({
            getter: Call({
                token: UNISWAP_V3_POSITION_ADDRESS,
                selector: UniswapNonFungiblePositionManagerLike.positions.selector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 3
            }),
            operator: ComparisonOperator.eq,
            value: uint256(uint160(token))
        });

        LogicalExpression[] memory expressions = new LogicalExpression[](2);
        expressions[0] = LogicalExpression({ operator: LogicalOperator.or, left: 1, right: 2 });
        expressions[1] = LogicalExpression({ operator: LogicalOperator.and, left: 0, right: 1 });

        (,, address stateToken0, address stateToken1,,,, uint128 stateLiquidity,,,,) =
            UniswapNonFungiblePositionManagerLike(UNISWAP_V3_POSITION_ADDRESS).positions(tokenId);
        bool isValid = stateLiquidity > liquidity && (stateToken0 == token || stateToken1 == token);

        assertEq(comparisons.evaluateExpressions(expressions, tokenId), isValid);
    }

    function test_AddressOwnsSetOfAssets() external {
        address SOME_ERC1155_ASSET = 0x5c761C0597a6cd3005F765B22E552a7B0E223AF5;

        uint256 tokenId = 481;

        uint256[] memory staticInputs = new uint256[](1);
        staticInputs[0] = uint256(uint160(0x4270DC94f53B4cA770cFAF250170C873a6551892));

        ComparisonExpression[] memory comparisons = new ComparisonExpression[](1);
        comparisons[0] = ComparisonExpression({
            getter: Call({
                token: SOME_ERC1155_ASSET,
                selector: 0x00fdd58e, // balanceOf(address,uint256)
                dynamicInputIndex: 0,
                staticInputs: staticInputs,
                returnDataWordIndex: 0
            }),
            operator: ComparisonOperator.ge,
            value: 1
        });

        assertTrue(comparisons.evaluateExpressionsTrue(tokenId));
    }

}
