// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Getter, Call} from "./Getter.sol";


/// Struct representing comparison expression
/// A x B (A - state value, x - operator, B - provided value)
struct ComparisonExpression {
    Call getter;
    ComparisonOperator operator;
    uint256 value;
}

/// Enum representing comparison operators
enum ComparisonOperator { eq, ne, lt, gt, le, ge }

/// Struct representing logical expression
struct LogicalExpression {
    LogicalOperator operator;
    uint256 left;
    uint256 right;
}

/// Enum representing logical operators
enum LogicalOperator { rarr, equiv, not, and, or, xor }

/// Current restrictions:
/// - support for only 1 dynamic input value
/// - cannot use the return value of a call in another getter call (cannot reuse return values)
library ExpressionEvaluator {
    using Getter for Call;

    /// all conditions have to be true for the check to pass (will return on first false condition)
    function evaluateExpressionsTrue(ComparisonExpression[] memory conditions, uint256 tokenId) external view returns (bool) {
        for (uint256 i; i < conditions.length; ++i)
            if (!evaluateComparisonExpression(conditions[i], tokenId))
                return false;

        return true;
    }

    /// evaluate logical expressions (will evaluate all conditions)
    function evaluateExpressions(
        ComparisonExpression[] memory conditions,
        LogicalExpression[] memory expressions,
        uint256 tokenId
    ) external view returns (bool) {
        bool[] memory results = new bool[](conditions.length);

        // evaluate all conditions
        for (uint256 i; i < conditions.length; ++i)
            results[i] = evaluateComparisonExpression(conditions[i], tokenId);

        // evaluate all expressions
        uint256 resultIndex;
        for (uint256 i; i < expressions.length; ++i)
            results[resultIndex = expressions[i].left] = evaluateLogicalOperator({
                operator: expressions[i].operator,
                left: results[expressions[i].left],
                right: results[expressions[i].right]
            });

        return results[resultIndex];
    }

    function evaluateComparisonExpression(ComparisonExpression memory condition, uint256 tokenId) public view returns (bool) {
        uint256 stateValue = condition.getter.execute(tokenId);

        if (condition.operator == ComparisonOperator.eq) return stateValue == condition.value;
        else if (condition.operator == ComparisonOperator.ne) return stateValue != condition.value;
        else if (condition.operator == ComparisonOperator.lt) return stateValue <  condition.value;
        else if (condition.operator == ComparisonOperator.le) return stateValue <= condition.value;
        else if (condition.operator == ComparisonOperator.gt) return stateValue >  condition.value;
        else if (condition.operator == ComparisonOperator.ge) return stateValue >= condition.value;
        else revert("Invalid comparison operator");
    }

    function evaluateLogicalOperator(LogicalOperator operator, bool left, bool right) public pure returns (bool) {
        if (operator == LogicalOperator.rarr) return !left || right;
        else if (operator == LogicalOperator.equiv) return left == right;
        else if (operator == LogicalOperator.not) return !left;
        else if (operator == LogicalOperator.and) return left && right;
        else if (operator == LogicalOperator.or) return left || right;
        else if (operator == LogicalOperator.xor) return left != right;
        else revert("Invalid logical operator");
    }

}
