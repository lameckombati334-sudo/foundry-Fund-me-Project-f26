// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {FundMe} from "src/FundMe.sol";
import {DeployFundMe} from "script/DeployFundMe.s.sol";
import {TestHelper} from "../mocks/TestHelper.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";

contract FundMeTest is Test {
    address user = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;
    FundMe fundMe;
    address deployer;

    function setUp() external {
        DeployFundMe deployfundMe = new DeployFundMe();
        fundMe = deployfundMe.run();
        vm.deal(user, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            assertEq(fundMe.getVersion(), 4);
        } else if (block.chainid == 1) {
            uint256 version = fundMe.getVersion();
            assertEq(version, 4);
        } // closes the else-if block
        else {
            // Local test chain fallback
            assertTrue(true, "Skipping version check on local chain");
        }
    } // closes the function

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(user);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(user);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(user);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, user);
    }
    modifier funded() {
        vm.prank(user);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(user);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        //commented out some  of it coz of storage and gas cost issues, but it works fine without it as well
        // uint256 gasStart = gasleft();
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //uint256 gasEnd = gasleft();
        // uint256 gasUsed = gasStart - gasEnd * tx.gasprice;
        //  console.log(gasUsed);
        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        //assert
        assertTrue(address(fundMe).balance == 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        //assert
        assertTrue(address(fundMe).balance == 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

    function testWithdrawFromManyFundersCheaper() public {
        //arrange
        uint160 numberOfFunders = 100;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();
        //assert
        assertTrue(address(fundMe).balance == 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }
}

contract FundMeGasComparisonTest is Test {
    TestHelper fundMe;
    MockV3Aggregator mockFeed;

    function setUp() public {
        mockFeed = new MockV3Aggregator(8, 2000e8);
        fundMe = new TestHelper(address(mockFeed));
    }

    function testLoopStorageVsMemory() public {
        for (uint160 i = 1; i <= 100; i++) {
            hoax(address(i), 0.1 ether);
            fundMe.fund{value: 0.1 ether}();
        }
        uint256 gasStorage = gasleft();
        fundMe.loopStorage();
        gasStorage = gasStorage - gasleft();

        uint256 gasMemory = gasleft();
        fundMe.loopMemory();
        gasMemory = gasMemory - gasleft();

        assertLt(gasMemory, gasStorage, "Memory should be cheaper with many funders");
    }
}
