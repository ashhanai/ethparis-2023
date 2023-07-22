// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ExpressionEvaluator, ComparisonExpression, ComparisonOperator, LogicalExpression, LogicalOperator} from "../../src/ExpressionEvaluator.sol";
import {Call} from "../../src/Getter.sol";


abstract contract ExpressionEvaluatorTest is Test {

    uint256 tokenId = 420;
    address token = makeAddr("token");
    bytes4 stateSelector = 0x12345678;
    uint256 returnValue = 101;

    function setUp() public virtual {}

}

contract ExpressionEvaluator_EevaluateExpressionsTrue_Test is ExpressionEvaluatorTest {
    using ExpressionEvaluator for ComparisonExpression;

    ComparisonExpression comparison;

    function setUp() public override {
        super.setUp();

        comparison = ComparisonExpression({
            getter: Call({
                token: token,
                selector: stateSelector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 0
            }),
            operator: ComparisonOperator.gt,
            value: 1
        });

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encode(returnValue)
        );
    }


    // Equal

    function testFuzz_shouldReturnTrue_whenCorrectCondition_Equal(uint256 value) external {
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = value;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.eq;
        comparison.value = value;

        assertTrue(comparison.evaluateComparisonExpression(tokenId));
    }

    function testFuzz_shouldReturnFalse_whenIncorrectCondition_Equal(uint256 value) external {
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = ~value;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.eq;
        comparison.value = value;

        assertFalse(comparison.evaluateComparisonExpression(tokenId));
    }

    // Unequal

    function testFuzz_shouldReturnTrue_whenCorrectCondition_Unequal(uint256 value) external {
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = ~value;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.ne;
        comparison.value = value;

        assertTrue(comparison.evaluateComparisonExpression(tokenId));
    }

    function testFuzz_shouldReturnFalse_whenInorrectCondition_Unequal(uint256 value) external {
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = value;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.ne;
        comparison.value = value;

        assertFalse(comparison.evaluateComparisonExpression(tokenId));
    }

    // Less than

    function testFuzz_shouldReturnTrue_whenCorrectCondition_LessThan(uint256 value) external {
        value = bound(value, 1, type(uint256).max);
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, 0, value - 1);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.lt;
        comparison.value = value;

        assertTrue(comparison.evaluateComparisonExpression(tokenId));
    }

    function testFuzz_shouldReturnFalse_whenIncorrectCondition_LessThan(uint256 value) external {
        value = bound(value, 1, type(uint256).max);
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, value, type(uint256).max);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.lt;
        comparison.value = value;

        assertFalse(comparison.evaluateComparisonExpression(tokenId));
    }

    // Less than or equal

    function testFuzz_shouldReturnTrue_whenCorrectCondition_LessThanOrEqual(uint256 value) external {
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, 0, value);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.le;
        comparison.value = value;

        assertTrue(comparison.evaluateComparisonExpression(tokenId));
    }

    function testFuzz_shouldReturnFalse_whenIncorrectCondition_LessThanOrEqual(uint256 value) external {
        value = bound(value, 0, type(uint256).max - 1);
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, value + 1, type(uint256).max);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.le;
        comparison.value = value;

        assertFalse(comparison.evaluateComparisonExpression(tokenId));
    }

    // Greater than

    function testFuzz_shouldReturnTrue_whenCorrectCondition_GreaterThan(uint256 value) external {
        value = bound(value, 0, type(uint256).max - 1);
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, value + 1, type(uint256).max);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.gt;
        comparison.value = value;

        assertTrue(comparison.evaluateComparisonExpression(tokenId));
    }

    function testFuzz_shouldReturnFalse_whenIncorrectCondition_GreaterThan(uint256 value) external {
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, 0, value);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.gt;
        comparison.value = value;

        assertFalse(comparison.evaluateComparisonExpression(tokenId));
    }

    // Greater than or equal

    function testFuzz_shouldReturnTrue_whenCorrectCondition_GreaterThanOrEqual(uint256 value) external {
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, value, type(uint256).max);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.ge;
        comparison.value = value;

        assertTrue(comparison.evaluateComparisonExpression(tokenId));
    }

    function testFuzz_shouldReturnFalse_whenIncorrectCondition_GreaterThanOrEqual(uint256 value) external {
        value = bound(value, 1, type(uint256).max);
        uint256 returnDataCount = bound(value, 1, 100);
        uint256 returnDataWordIndex = bound(value, 0, returnDataCount - 1);
        uint256 stateValue = bound(value, 0, value - 1);

        uint256[] memory returnData = new uint256[](returnDataCount);
        returnData[returnDataWordIndex] = stateValue;

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(returnData)
        );

        comparison.getter.returnDataWordIndex = returnDataWordIndex;
        comparison.operator = ComparisonOperator.ge;
        comparison.value = value;

        assertFalse(comparison.evaluateComparisonExpression(tokenId));
    }

}

contract ExpressionEvaluator_EvaluateExpression_Test is ExpressionEvaluatorTest {
    using ExpressionEvaluator for LogicalOperator;

    function test_rarr() external {
        assertTrue(LogicalOperator.rarr.evaluateLogicalOperator(false, false));
        assertTrue(LogicalOperator.rarr.evaluateLogicalOperator(false, true));
        assertFalse(LogicalOperator.rarr.evaluateLogicalOperator(true, false));
        assertTrue(LogicalOperator.rarr.evaluateLogicalOperator(true, true));
    }

    function test_equiv() external {
        assertTrue(LogicalOperator.equiv.evaluateLogicalOperator(false, false));
        assertFalse(LogicalOperator.equiv.evaluateLogicalOperator(false, true));
        assertFalse(LogicalOperator.equiv.evaluateLogicalOperator(true, false));
        assertTrue(LogicalOperator.equiv.evaluateLogicalOperator(true, true));
    }

    function test_not() external {
        assertTrue(LogicalOperator.not.evaluateLogicalOperator(false, false));
        assertTrue(LogicalOperator.not.evaluateLogicalOperator(false, true));
        assertFalse(LogicalOperator.not.evaluateLogicalOperator(true, false));
        assertFalse(LogicalOperator.not.evaluateLogicalOperator(true, true));
    }

    function test_and() external {
        assertFalse(LogicalOperator.and.evaluateLogicalOperator(false, false));
        assertFalse(LogicalOperator.and.evaluateLogicalOperator(false, true));
        assertFalse(LogicalOperator.and.evaluateLogicalOperator(true, false));
        assertTrue(LogicalOperator.and.evaluateLogicalOperator(true, true));
    }

    function test_or() external {
        assertFalse(LogicalOperator.or.evaluateLogicalOperator(false, false));
        assertTrue(LogicalOperator.or.evaluateLogicalOperator(false, true));
        assertTrue(LogicalOperator.or.evaluateLogicalOperator(true, false));
        assertTrue(LogicalOperator.or.evaluateLogicalOperator(true, true));
    }

    function test_xor() external {
        assertFalse(LogicalOperator.xor.evaluateLogicalOperator(false, false));
        assertTrue(LogicalOperator.xor.evaluateLogicalOperator(false, true));
        assertTrue(LogicalOperator.xor.evaluateLogicalOperator(true, false));
        assertFalse(LogicalOperator.xor.evaluateLogicalOperator(true, true));
    }

}

contract ExpressionEvaluator_EvaluateExpressions_Test is ExpressionEvaluatorTest {
    using ExpressionEvaluator for ComparisonExpression[];

    // Ideally generate random logical expressions and use third party library to evaluate them

    ComparisonExpression trueComparison;
    ComparisonExpression falseComparison;

    function setUp() public override {
        super.setUp();

        trueComparison = ComparisonExpression({
            getter: Call({
                token: token,
                selector: stateSelector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 0
            }),
            operator: ComparisonOperator.eq,
            value: returnValue
        });
        falseComparison = ComparisonExpression({
            getter: Call({
                token: token,
                selector: stateSelector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 0
            }),
            operator: ComparisonOperator.ne,
            value: returnValue
        });

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encode(returnValue)
        );
    }


    function test_1() external {
        // (F && T) || (F && T): false

        ComparisonExpression[] memory comparisons = new ComparisonExpression[](4);
        comparisons[0] = falseComparison;
        comparisons[1] = trueComparison;
        comparisons[2] = falseComparison;
        comparisons[3] = trueComparison;

        LogicalExpression[] memory logicals = new LogicalExpression[](3);
        logicals[0] = LogicalExpression({ operator: LogicalOperator.and, left: 0, right: 1 });
        logicals[1] = LogicalExpression({ operator: LogicalOperator.and, left: 2, right: 3 });
        logicals[2] = LogicalExpression({ operator: LogicalOperator.or, left: 0, right: 2 });

        assertFalse(comparisons.evaluateExpressions(logicals, tokenId));
    }

    function test_2() external {
        // (F && T) => (F && T): true

        ComparisonExpression[] memory comparisons = new ComparisonExpression[](4);
        comparisons[0] = falseComparison;
        comparisons[1] = trueComparison;
        comparisons[2] = falseComparison;
        comparisons[3] = trueComparison;

        LogicalExpression[] memory logicals = new LogicalExpression[](3);
        logicals[0] = LogicalExpression({ operator: LogicalOperator.and, left: 0, right: 1 });
        logicals[1] = LogicalExpression({ operator: LogicalOperator.and, left: 2, right: 3 });
        logicals[2] = LogicalExpression({ operator: LogicalOperator.rarr, left: 0, right: 2 });

        assertTrue(comparisons.evaluateExpressions(logicals, tokenId));
    }

    function test_3() external {
        // not(F || T) <=> (F && (T || F)): true

        ComparisonExpression[] memory comparisons = new ComparisonExpression[](5);
        comparisons[0] = falseComparison;
        comparisons[1] = trueComparison;
        comparisons[2] = falseComparison;
        comparisons[3] = trueComparison;
        comparisons[4] = falseComparison;

        LogicalExpression[] memory logicals = new LogicalExpression[](5);
        logicals[0] = LogicalExpression({ operator: LogicalOperator.or, left: 0, right: 1 });
        logicals[1] = LogicalExpression({ operator: LogicalOperator.not, left: 0, right: 0 });
        logicals[2] = LogicalExpression({ operator: LogicalOperator.or, left: 3, right: 4 });
        logicals[3] = LogicalExpression({ operator: LogicalOperator.and, left: 2, right: 3 });
        logicals[4] = LogicalExpression({ operator: LogicalOperator.equiv, left: 0, right: 2 });

        assertTrue(comparisons.evaluateExpressions(logicals, tokenId));
    }

}
