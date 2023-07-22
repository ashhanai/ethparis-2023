// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ConditionChecker, Operator, Condition} from "../../src/ConditionChecker.sol";
import {Call} from "../../src/Getter.sol";


contract ConditionCheckerTest is Test {
    using ConditionChecker for Condition;

    Condition condition;

    uint256 tokenId = 420;
    address token = makeAddr("token");
    bytes4 stateSelector = 0x12345678;
    uint256 returnValue = 101;

    function setUp() external {
        condition = Condition({
            getter: Call({
                token: token,
                selector: stateSelector,
                dynamicInputIndex: 0,
                staticInputs: new uint256[](0),
                returnDataWordIndex: 0
            }),
            operator: Operator.gt,
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.eq;
        condition.value = value;

        assertTrue(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.eq;
        condition.value = value;

        assertFalse(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.ne;
        condition.value = value;

        assertTrue(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.ne;
        condition.value = value;

        assertFalse(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.lt;
        condition.value = value;

        assertTrue(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.lt;
        condition.value = value;

        assertFalse(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.le;
        condition.value = value;

        assertTrue(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.le;
        condition.value = value;

        assertFalse(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.gt;
        condition.value = value;

        assertTrue(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.gt;
        condition.value = value;

        assertFalse(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.ge;
        condition.value = value;

        assertTrue(condition.checkStateCondition(tokenId));
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

        condition.getter.returnDataWordIndex = returnDataWordIndex;
        condition.operator = Operator.ge;
        condition.value = value;

        assertFalse(condition.checkStateCondition(tokenId));
    }

}
