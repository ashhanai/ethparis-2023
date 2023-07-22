// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct Call {
    address token;
    bytes4 selector;
    // dynamic input will be appended before this index in the `staticInputs` array
    uint256 dynamicInputIndex;
    uint256[] staticInputs;
    // in case more than one word is returned, this is the index of the word to use
    uint256 returnDataWordIndex;
}

library Getter {

    function execute(Call calldata call, uint256 dynamicInput) external view returns (uint256) {
        // Encode input data
        bytes memory inputData;
        uint256 inputs = call.staticInputs.length;
        for (uint256 i; i <= inputs; ) {
            // Append dynamic input
            if (i == call.dynamicInputIndex)
                inputData = abi.encodePacked(inputData, dynamicInput);

            // Append static input (and to not overflow)
            if (i < inputs)
                inputData = abi.encodePacked(inputData, call.staticInputs[i]);

            unchecked { ++i; }
        }

        // Make a static call to the state getter address
        (bool success, bytes memory returnData) = call.token.staticcall(
            // encode packet to not include input data length
            abi.encodePacked(call.selector, inputData)
        );

        require(success, "Low level staticcall failed");
        require(returnData.length > 0 && returnData.length % 32 == 0, "Incorrect return data length");
        require(call.returnDataWordIndex < returnData.length / 32, "Return data word index out of bounds");

        // Get return value
        uint256 returnDataMemoryOffset = call.returnDataWordIndex * 32;
        uint256 returnValue;
        assembly {
            // 1. add 0x20 to the `returnData` pointer to skip the length field
            // 2. add `returnDataMemoryOffset` to get the correct word
            returnValue := mload(add(add(returnData, 0x20), returnDataMemoryOffset))
        }

        return returnValue;
    }

}
