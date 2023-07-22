// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {Getter, Call} from "../../src/Getter.sol";


contract GetterTest is Test {
    using Getter for Call;

    Call call;

    uint256 dynamicInput = 420;
    address token = makeAddr("token");
    bytes4 selector = 0x12345678;
    uint256 returnValue = 101;

    function setUp() external {
        call = Call({
            token: token,
            selector: selector,
            dynamicInputIndex: 0,
            staticInputs: new uint256[](0),
            returnDataWordIndex: 0
        });

        vm.mockCall(
            token,
            abi.encodeWithSelector(selector),
            abi.encode(returnValue)
        );
    }


    function test_shouldMakeStaticcall() external {
        vm.expectCall(
            token,
            abi.encodeWithSelector(selector, dynamicInput)
        );
        call.execute(dynamicInput);
    }

    function test_shouldFail_whenStaticcallFails() external {
        vm.mockCallRevert(
            token,
            abi.encodeWithSelector(selector),
            abi.encode("any revert data")
        );

        vm.expectRevert("Low level staticcall failed");
        call.execute(dynamicInput);
    }

    function test_shouldFail_whenReturnDataZero() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(selector),
            abi.encode()
        );

        vm.expectRevert("Incorrect return data length");
        call.execute(dynamicInput);
    }

    function test_shouldFail_whenReturnDataIncorrectLength() external {
        vm.mockCall(
            token,
            abi.encodeWithSelector(selector),
            abi.encodePacked(uint64(2))
        );

        vm.expectRevert("Incorrect return data length");
        call.execute(dynamicInput);
    }

    function test_shouldFail_whenReturnDataWordIndexOutOfBounds() external {
        call.returnDataWordIndex = 1;

        vm.expectRevert("Return data word index out of bounds");
        call.execute(dynamicInput);
    }

}
