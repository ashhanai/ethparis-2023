// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

enum Operator { eq, ne, lt, gt, le, ge }

// Struct representing logical expression
// A x B (A - state value, x - operator, B - provided value)
// Works with 1 dynamic input value and allow to set any number of static input values as `uint256`s
struct Condition {
    address token;
    bytes4 stateSelector;

    uint256 dynamicInputIndex; // dynamic input will be appended before this index in the `staticInputs` array
    uint256[] staticInputs;

    uint256 returnDataWordIndex; // in case more than one word is returned, this is the index of the word to use

    Operator operator;
    uint256 value;
}

/// v1: all conditions have to be true for the check to pass
library ConditionChecker {

    function checkStateConditions(Condition[] calldata conditions, uint256 tokenId) external view returns (bool) {
        uint256 length = conditions.length;
        for (uint256 i; i < length;) {
            if (!checkStateCondition(conditions[i], tokenId))
                return false;

            unchecked { ++i; }
        }

        return true;
    }

    function checkStateCondition(Condition memory condition, uint256 tokenId) public view returns (bool) {
        // Encode input data
        bytes memory inputData;
        uint256 inputs = condition.staticInputs.length;
        for (uint256 i; i <= inputs; ) {
            // Append dynamic input
            if (i == condition.dynamicInputIndex)
                inputData = abi.encodePacked(inputData, tokenId);

            // Append static input (and to not overflow)
            if (i < inputs)
                inputData = abi.encodePacked(inputData, condition.staticInputs[i]);

            unchecked { ++i; }
        }

        // Make a static call to the state getter address
        (bool success, bytes memory returnData) = condition.token.staticcall(
            // encode packet to not include input data length
            abi.encodePacked(condition.stateSelector, inputData)
        );

        require(success, "Low level staticcall failed");
        require(returnData.length > 0 && returnData.length % 32 == 0, "Incorrect return data length");
        require(condition.returnDataWordIndex < returnData.length / 32, "Return data word index out of bounds");

        // Get state value
        uint256 returnDataMemoryOffset = condition.returnDataWordIndex * 32;
        uint256 stateValue;
        assembly {
            // 1. add 0x20 to the `returnData` pointer to skip the length field
            // 2. add `returnDataMemoryOffset` to get the correct word
            stateValue := mload(add(add(returnData, 0x20), returnDataMemoryOffset))
        }

        // Evaluate condition
        if (condition.operator == Operator.eq) return stateValue == condition.value;
        if (condition.operator == Operator.ne) return stateValue != condition.value;
        if (condition.operator == Operator.lt) return stateValue <  condition.value;
        if (condition.operator == Operator.le) return stateValue <= condition.value;
        if (condition.operator == Operator.gt) return stateValue >  condition.value;
        if (condition.operator == Operator.ge) return stateValue >= condition.value;
        revert("Invalid operator");
    }

}
