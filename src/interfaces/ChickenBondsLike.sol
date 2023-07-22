// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ChickenBondsLike {
    function getBondStatus(uint256 tokenId) external view returns (uint8);
    function getBondAmount(uint256 tokenId) external view returns (uint256);
    function getBondClaimedBLUSD(uint256 tokenId) external view returns (uint256);
    function getBondStartTime(uint256 tokenId) external view returns (uint256);
    function getBondEndTime(uint256 tokenId) external view returns (uint256);
}
