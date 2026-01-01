// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */
pragma solidity ^0.8.0;

library ABDKMath64x64 {
    function fromUInt (uint256 x) internal pure returns (int128) {
        require (x <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (x << 64));
    }

    function toUInt (int128 x) internal pure returns (uint256) {
        require (x >= 0);
        return uint256 (int256 (x >> 64));
    }

    function mul (int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) * y;
        return int128 (result >> 64);
    }

    function divu (uint256 x, uint256 y) internal pure returns (int128) {
        require (y != 0);
        uint256 result = (x << 64) / y;
        require (result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (int256 (result));
    }
    
    function sub (int128 x, int128 y) internal pure returns (int128) {
        int256 result = int256(x) - y;
        require (result >= -0x80000000000000000000000000000000 && result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (result);
    }
}