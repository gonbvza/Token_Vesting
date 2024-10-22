// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {ImULL} from "src/imull.sol";
import {VestingContract} from "src/tokenVesting.sol";
import {PreSale} from "src/tokenPreSale.sol";
import {DeployPreSale} from "script/deploySale.s.sol";

contract TokenTest is Test {
    PreSale private preSale;
    ImULL private token;
    address private USER;
    uint256 private userPrivKey;

    address private PRESALE = makeAddr("Presale");
    address private CEX = makeAddr("CEX");
    address private LP = makeAddr("LP");
    address private RESERVE = makeAddr("Reserve");
    address private ECOSYSTEM = makeAddr("ECOSYSTEM");
    address private MARKETING = makeAddr("Marketing");
    address private ADVISORS = makeAddr("Advisors");
    address private FOUNDERS = makeAddr("Founders");
    address private MM = makeAddr("MM");

    uint256 private constant TGE = 1735113600;
    uint256 private constant COINS_ALLOCATED = 750000000 ether;
    uint256 private constant MONTH = 30 days;
    uint256 private constant TOTAL_SUPPLY = 9750000000 ether;

    address[] private joinedUsers;

    address[] private vestingContracts = [
        PRESALE,
        CEX,
        LP,
        RESERVE,
        ECOSYSTEM,
        MARKETING,
        ADVISORS,
        FOUNDERS,
        MM
    ];

    VestingContract private vestingContract;

    function setUp() public {
        token = new ImULL();
        vestingContract = new VestingContract(token, TOTAL_SUPPLY);
        token.approve(address(vestingContract), TOTAL_SUPPLY);
    }

    modifier setVestings() {
        vestingContract.createVestingSchedule(
            address(PRESALE),
            1,
            3,
            VestingContract.DurationUnits.Months,
            750000000 ether
        );

        vestingContract.createVestingSchedule(
            address(CEX),
            5,
            8,
            VestingContract.DurationUnits.Months,
            3000000000 ether
        );

        vestingContract.createVestingSchedule(
            address(LP),
            6,
            8,
            VestingContract.DurationUnits.Months,
            2620000000 ether
        );

        vestingContract.createVestingSchedule(
            address(RESERVE),
            24,
            12,
            VestingContract.DurationUnits.Months,
            200000000 ether
        );

        vestingContract.createVestingSchedule(
            address(ECOSYSTEM),
            8,
            12,
            VestingContract.DurationUnits.Months,
            100000000 ether
        );

        vestingContract.createVestingSchedule(
            address(MARKETING),
            4,
            24,
            VestingContract.DurationUnits.Months,
            1500000000 ether
        );

        vestingContract.createVestingSchedule(
            address(ADVISORS),
            18,
            6,
            VestingContract.DurationUnits.Months,
            500000000 ether
        );

        vestingContract.createVestingSchedule(
            address(FOUNDERS),
            6,
            36,
            VestingContract.DurationUnits.Months,
            1000000000 ether
        );

        vestingContract.createVestingSchedule(
            address(MM),
            4,
            24,
            VestingContract.DurationUnits.Months,
            80000000 ether
        );
        _;
    }

    function testIfAmountZero() public {
        vm.expectRevert();
        vestingContract.createVestingSchedule(
            address(MM),
            4,
            24,
            VestingContract.DurationUnits.Months,
            0
        );
    }

    function testTotalAllocationExceeded() public {
        vm.expectRevert();
        vestingContract.createVestingSchedule(
            address(MM),
            4,
            24,
            VestingContract.DurationUnits.Months,
            75000000000000000000 ether
        );
    }

    function testPreSale() public setVestings {
        uint256 totalReleased = 0;
        uint256 monthlyRelease;
        for (uint256 i = 0; i < vestingContracts.length; i++) {
            address addr = vestingContracts[i];
            (address beneficiary, , , , , , ) = vestingContract
                .vestingSchedules(addr, 0);
            assert(addr == beneficiary);

            uint256 timeElapsed = 0;
            (
                address contractAddr,
                uint256 startTimestamp,
                uint256 vestingDuration,
                uint256 cliffDuration,
                ,
                uint256 totalAmount,
                uint256 releasedAmount
            ) = vestingContract.vestingSchedules(addr, 0);

            monthlyRelease = totalAmount / vestingDuration;
            vm.warp(TGE);
            assert(!vestingContract.release(addr));
            assertEq(startTimestamp, (TGE + cliffDuration * MONTH));

            for (uint256 j = 0; j < vestingDuration; j++) {
                timeElapsed = MONTH * j;
                uint256 expected;
                vm.warp(TGE + (cliffDuration * MONTH) + timeElapsed + 1);
                vestingContract.release(addr);

                uint256 balance = token.balanceOf(contractAddr);
                if (j == vestingDuration - 1) {
                    expected = totalAmount;
                } else {
                    expected = (totalAmount * (j + 1)) / vestingDuration;
                }

                assert(balance == expected);
            }

            (, , , , , , releasedAmount) = vestingContract.vestingSchedules(
                addr,
                0
            );

            assert(releasedAmount == totalAmount);
            totalReleased += releasedAmount;

            vm.warp(TGE + (cliffDuration * MONTH) + (timeElapsed + MONTH) + 1);

            assert(!vestingContract.release(addr));
        }
    }

    function testIfAumationWorks() public setVestings {
        uint256 actualDate = TGE;
        for (uint256 i = 0; i < 42; i++) {
            actualDate += (MONTH);

            for (uint256 j = 0; j < vestingContracts.length; j++) {
                address addr = vestingContracts[j];
                vm.warp(actualDate);
                vestingContract.release(addr);
            }
        }
        uint256 totalBalances = addTotalBalances();
        assert(totalBalances == (TOTAL_SUPPLY));
    }

    function addTotalBalances() public view returns (uint256) {
        uint256 totalBalances = 0;
        for (uint i = 0; i < vestingContracts.length; i++) {
            address addr = vestingContracts[i];
            uint256 sent = token.balanceOf(addr);
            totalBalances += sent;
        }

        return totalBalances;
    }

    function testIfWithdrawalTwice() public setVestings {
        vm.warp(TGE + MONTH + MONTH);
        vestingContract.release(PRESALE);

        assert(token.balanceOf(PRESALE) == 500000000 ether);

        vm.warp(TGE + MONTH + MONTH);
        vestingContract.release(PRESALE);

        assert(token.balanceOf(PRESALE) == 500000000 ether);
    }

    function testReleaseAll() public setVestings {
        vm.startPrank(USER);
        vestingContract.releaseAll();

        assertEq(token.balanceOf(PRESALE), 0 ether);
        assertEq(token.balanceOf(CEX), 0 ether);
        assertEq(token.balanceOf(LP), 0 ether);
        assertEq(token.balanceOf(RESERVE), 0 ether);
        assertEq(token.balanceOf(ECOSYSTEM), 0 ether);
        assertEq(token.balanceOf(MARKETING), 0 ether);
        assertEq(token.balanceOf(ADVISORS), 0 ether);
        assertEq(token.balanceOf(FOUNDERS), 0 ether);
        assertEq(token.balanceOf(MM), 0 ether);

        vm.warp(TGE + MONTH);
        vestingContract.releaseAll();
        assertEq(token.balanceOf(PRESALE), 250000000 ether);
        assertEq(token.balanceOf(CEX), 0 ether);
        assertEq(token.balanceOf(LP), 0 ether);
        assertEq(token.balanceOf(RESERVE), 0 ether);
        assertEq(token.balanceOf(ECOSYSTEM), 0 ether);
        assertEq(token.balanceOf(MARKETING), 0 ether);
        assertEq(token.balanceOf(ADVISORS), 0 ether);
        assertEq(token.balanceOf(FOUNDERS), 0 ether);
        assertEq(token.balanceOf(MM), 0 ether);

        vm.warp(TGE + (4 * MONTH));
        vestingContract.releaseAll();
        assertEq(token.balanceOf(PRESALE), 750000000 ether);
        assertEq(token.balanceOf(CEX), 0 ether);
        assertEq(token.balanceOf(LP), 0 ether);
        assertEq(token.balanceOf(RESERVE), 0 ether);
        assertEq(token.balanceOf(ECOSYSTEM), 0 ether);
        assertEq(token.balanceOf(MARKETING), 62500000 ether);
        assertEq(token.balanceOf(ADVISORS), 0 ether);
        assertEq(token.balanceOf(FOUNDERS), 0 ether);
        assertEq(token.balanceOf(MM), 3333333333333333333333333);

        vm.warp(TGE + (45 * MONTH));
        vestingContract.releaseAll();
        assertEq(token.balanceOf(PRESALE), 750000000 ether);
        assertEq(token.balanceOf(CEX), 3000000000 ether);
        assertEq(token.balanceOf(LP), 2620000000 ether);
        assertEq(token.balanceOf(RESERVE), 200000000 ether);
        assertEq(token.balanceOf(ECOSYSTEM), 100000000 ether);
        assertEq(token.balanceOf(MARKETING), 1500000000 ether);
        assertEq(token.balanceOf(ADVISORS), 500000000 ether);
        assertEq(token.balanceOf(FOUNDERS), 1000000000 ether);
        assertEq(token.balanceOf(MM), 80000000 ether);

        vm.stopPrank();
    }
}
