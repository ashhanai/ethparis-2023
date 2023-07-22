// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Getter, Call} from "./Getter.sol";


/// Struct representing logical expression
/// A x B (A - state value, x - operator, B - provided value)
struct Condition {
    Call getter;
    Operator operator;
    uint256 value;
}

/// Enum representing logical operators
enum Operator { eq, ne, lt, gt, le, ge }

/// v1: all conditions have to be true for the check to pass
/// Current restrictions:
/// - support for only 1 dynamic input value
/// - cannot use the return value of a call in another getter call (cannot reuse return values)
library ConditionChecker {
    using Getter for Call;

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
        uint256 stateValue = condition.getter.execute(tokenId);

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
