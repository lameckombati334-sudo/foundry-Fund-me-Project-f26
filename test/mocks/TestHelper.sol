// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/FundMe.sol";

contract TestHelper is FundMe {
    constructor(address priceFeed) FundMe(priceFeed) {}
    modifier onlyTest() {
        require(block.chainid == 31337, "Only for local testing");
        _;
    }

    function loopStorage() public view onlyTest returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            sum += uint160(funder);
        }
        return sum;
    }

    function loopMemory() public view onlyTest returns (uint256) {
        uint256 sum = 0;
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            sum += uint160(funder);
        }
        return sum;
    }
}
