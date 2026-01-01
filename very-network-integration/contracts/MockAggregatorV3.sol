// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title MockOracle
 * @dev Simulates a Chainlink Price Feed for the Very Hackathon.
 * Returns a fixed price for VERY/USD (e.g., $1.00).
 */
contract MockAggregatorV3 is AggregatorV3Interface {
    int256 private _price;
    uint8 private _decimals;

    constructor(int256 initialPrice, uint8 decimalsArg) {
        _price = initialPrice;
        _decimals = decimalsArg;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function description() external pure override returns (string memory) {
        return "Mock VERY/USD Oracle";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80) external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }

    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (1, _price, block.timestamp, block.timestamp, 1);
    }
    
    // Allow admin to change price for testing "Crash Protection"
    function setPrice(int256 newPrice) external {
        _price = newPrice;
    }
}