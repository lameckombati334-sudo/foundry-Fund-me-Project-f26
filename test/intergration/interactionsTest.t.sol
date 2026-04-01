// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;
import "forge-std/Test.sol";
import "forge-std/console.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";    
import {TestHelper} from "../mocks/TestHelper.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {FundFundMe, WithdrawFundMe} from "script/Interactions.s.sol";

contract FundMeTest is Test {
     address USER= makeAddr("user");
  uint256 constant SEND_VALUE = 0.1 ether;
  uint256 constant STARTING_BALANCE = 10 ether;
  uint256 constant GAS_PRICE = 1;
    FundMe fundMe;
    address deployer;
    function setUp() external {
      DeployFundMe deployfundMe = new DeployFundMe();
      fundMe = deployfundMe.run();
      vm.deal(USER, STARTING_BALANCE);
    }
   function testUserCanFundInteractions() public {
    FundFundMe fundFundMe = new FundFundMe();
    fundFundMe.fundFundMe(address(fundMe));

    WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
    withdrawFundMe.withdrawFundMe(address(fundMe));
    assert(address(fundMe).balance == 0);
   }
   
}