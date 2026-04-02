// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.18;
import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        uint256 lastKnownBalance = address(mostRecentlyDeployed).balance;
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Balance before funding: %s", lastKnownBalance);
        console.log("Balance after funding: %s", address(mostRecentlyDeployed).balance);
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        vm.startBroadcast();
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        vm.stopBroadcast();
        fundFundMe(mostRecentlyDeployed);
    }
}

contract WithdrawFundMe is Script {
    function withdrawFundMe(address mostRecentlyDeployed) public {
        uint256 lastKnownBalance = address(mostRecentlyDeployed).balance;
        address owner = FundMe(payable(mostRecentlyDeployed)).getOwner();
        uint256 ownerBalanceBefore = owner.balance;
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        console.log("Balance before withdrawal: %s", lastKnownBalance);
        console.log("Balance after withdrawal: %s", address(mostRecentlyDeployed).balance);
        console.log("Owner balance before: %s", ownerBalanceBefore);
        console.log("Owner balance after: %s", owner.balance);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        withdrawFundMe(mostRecentlyDeployed);
    }
}

