// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Note: The AggregatorV3Interface might be at a different location than what was in the video!
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private saddressToAmountFunded;
    address[] internal sfunders;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable I_OWNER;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private spriceFeed;

    constructor(address priceFeed) {
        I_OWNER = msg.sender;

        spriceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(spriceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        saddressToAmountFunded[msg.sender] += msg.value;
        sfunders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return spriceFeed.version();
    }

    function getPriceFeed() public view returns (address) {
        return address(spriceFeed);
    }
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != I_OWNER) revert FundMe__NotOwner();
    }
    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = sfunders;
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = sfunders[funderIndex];
            saddressToAmountFunded[funder] = 0;
        }
        sfunders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < sfunders.length; funderIndex++) {
            address funder = sfunders[funderIndex];
            saddressToAmountFunded[funder] = 0;
        }
        sfunders = new address[](0);

        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \
    //         yes  no
    //         /     \
    //    receive()?  fallback()
    //     /   \
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
    // Mapping assumed to exist:
    // mapping(address => uint256) private s_addressToAmountFunded;
    // address[] private s_funders;

    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return saddressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return sfunders[index];
    }

    function getOwner() external view returns (address) {
        return I_OWNER;
    }
}

