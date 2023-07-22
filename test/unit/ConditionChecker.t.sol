// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {ConditionChecker, Operator, Condition} from "../../src/ConditionChecker.sol";


contract ConditionCheckerTest is Test {
    using ConditionChecker for Condition;

    Condition condition;

    uint256 tokenId = 420;
    address token = makeAddr("token");
    bytes4 stateSelector = 0x12345678;
    uint256 returnValue = 101;

    function setUp() external {
        condition = Condition({
            token: token,
            stateSelector: stateSelector,
            dynamicInputIndex: 0,
            staticInputs: new uint256[](0),
            returnDataWordIndex: 0,
            operator: Operator.gt,
            value: 1
        });

        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encode(returnValue)
        );
    }


    function test_shouldMakeStaticcall() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(stateSelector, tokenId)
        );
        condition.checkStateCondition(tokenId);
    }

    function test_shouldFail_whenStaticcallFails() external {
        vm.mockCallRevert(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encode("any revert data")
        );

        vm.expectRevert("Low level staticcall failed");
        condition.checkStateCondition(tokenId);
    }

    function test_shouldFail_whenReturnDataZero() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encode()
        );

        vm.expectRevert("Incorrect return data length");
        condition.checkStateCondition(tokenId);
    }

    function test_shouldFail_whenReturnDataIncorrectLength() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(stateSelector),
            abi.encodePacked(uint64(2))
        );

        vm.expectRevert("Incorrect return data length");
        condition.checkStateCondition(tokenId);
    }

    function test_shouldFail_whenReturnDataWordIndexOutOfBounds() external {
        condition.returnDataWordIndex = 1;

        vm.expectRevert("Return data word index out of bounds");
        condition.checkStateCondition(tokenId);
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

        condition.operator = Operator.eq;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.eq;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.ne;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.ne;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.lt;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.lt;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.le;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.le;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.gt;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.gt;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.ge;
        condition.returnDataWordIndex = returnDataWordIndex;
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

        condition.operator = Operator.ge;
        condition.returnDataWordIndex = returnDataWordIndex;
        condition.value = value;

        assertFalse(condition.checkStateCondition(tokenId));
    }

}
