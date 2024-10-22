// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {ImULL} from "src/imull.sol";
import {VestingContract} from "src/tokenVesting.sol";
import {PreSale} from "src/tokenPreSale.sol";
import {DeployPreSale} from "script/deploySale.s.sol";
import {ImullStaking} from "src/imullStaking.sol";

contract StakingTest is Test {
    ImULL private token;
    ImullStaking private stakerContract;

    address private USER = makeAddr("User");

    function setUp() public {
        token = new ImULL();
        stakerContract = new ImullStaking(token);
        token.transfer(address(stakerContract), 1000 ether);
        token.transfer(USER, 2620000000 ether);
    }

    function testConstructor() public view {
        assert(stakerContract.owner() == address(this));
        assertEq(address(stakerContract.token()), address(token));
    }

    function testStake() public {
        vm.startPrank(USER);
        token.approve(address(stakerContract), 1000 ether);

        vm.expectRevert();
        stakerContract.stake(0, ImullStaking.TimeChoosen.one);

        stakerContract.stake(1000 ether, ImullStaking.TimeChoosen.one);

        vm.expectRevert();
        stakerContract.stake(1000 ether, ImullStaking.TimeChoosen.one);

        vm.stopPrank();
    }

    function testUnstake() public {
        uint256 stakedTime;

        vm.startPrank(USER);
        vm.expectRevert();
        stakerContract.unStake();

        token.approve(address(stakerContract), 1000 ether);
        stakerContract.stake(1000 ether, ImullStaking.TimeChoosen.one);
        stakedTime = block.timestamp;

        vm.expectRevert();
        stakerContract.unStake();

        vm.warp(stakedTime + 30 days);
        stakerContract.unStake();

        assert(token.balanceOf(USER) == 2620000010 ether);

        token.approve(address(stakerContract), 1000 ether);
        stakerContract.stake(1000 ether, ImullStaking.TimeChoosen.twentyfour);
        stakedTime = block.timestamp;

        vm.warp(stakedTime + 730 days);
        stakerContract.unStake();

        assert(token.balanceOf(USER) == 2620000210 ether);
        vm.stopPrank();
    }

    function testIfRewardIsTooHigh() public {
        vm.startPrank(USER);
        token.approve(address(stakerContract), 2620000000 ether);
        stakerContract.stake(
            2620000000 ether,
            ImullStaking.TimeChoosen.twentyfour
        );

        vm.warp(block.timestamp + 730 days);
        vm.expectRevert();
        stakerContract.unStake();

        vm.stopPrank();
    }
}
