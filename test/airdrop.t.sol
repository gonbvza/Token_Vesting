// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {ImULL} from "../src/imull.sol";
import {PreSale} from "src/tokenPreSale.sol";
import {DeployPreSale} from "script/deploySale.s.sol";

contract AirdropTest is Test {
    PreSale private preSale;
    ImULL private token;
    address private USER;
    uint256 private userPrivKey;

    address private USER2 = makeAddr("user2");
    address private USER3 = makeAddr("user3");
    address private USER4 = makeAddr("user4");
    address private USER5 = makeAddr("user5");
    address private USER6 = makeAddr("user6");
    address private USER7 = makeAddr("user7");
    address private USER8 = makeAddr("user8");
    address private USER9 = makeAddr("user9");
    address private USER10 = makeAddr("user10");

    address[10] private users = [
        USER,
        USER2,
        USER3,
        USER4,
        USER5,
        USER6,
        USER7,
        USER8,
        USER9,
        USER10
    ];

    uint256 private constant TGE = 1735131559;
    uint256 private constant END_OF_WHITELIST = 1737809959;
    uint256 private constant COINS_ALLOCATED = 250000000 ether;
    uint256 private constant MONTH = 30 days;

    address[] private joinedUsers;
    modifier joinWhitelist() {
        hoax(USER2, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER3, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER4, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER5, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER6, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER7, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER8, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER9, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        hoax(USER10, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        _;
    }
    DeployPreSale deployer;

    function setUp() public {
        deployer = new DeployPreSale();
        token = new ImULL();
        preSale = deployer.run(token);

        token.transfer(address(preSale), COINS_ALLOCATED);
        (USER, userPrivKey) = makeAddrAndKey("user");
    }

    function testConstructor() public view {
        assert(preSale.s_token() == token);
    }

    function testIfUserJoinsWhiteList() public {
        hoax(USER, 1 ether);
        preSale.joinWhiteList{value: 0.5 ether}();

        assert(preSale.getUserJoined(USER));
    }

    function testClaimableAmount() public {
        hoax(USER, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        vm.warp(END_OF_WHITELIST + 1);
        assert(preSale.getClaimableAmount(USER) == 62777777777775000000000);
    }

    function testWhiteListJoiningTwice() public {
        vm.startPrank(USER);
        preSale.joinWhiteList();

        vm.expectRevert();
        preSale.joinWhiteList();
        vm.stopPrank();
    }

    function testJoinWhenEnds() public {
        vm.warp(END_OF_WHITELIST + 1);
        vm.prank(USER);
        vm.expectRevert();
        preSale.joinWhiteList();
    }

    function testpreSaleClaim() public {
        hoax(USER, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        vm.warp(END_OF_WHITELIST + 1);
        vm.prank(USER);
        preSale.claimAmount(500, false);
    }

    function testCantClaimMoreThanVesting() public {
        vm.prank(USER);
        preSale.joinWhiteList();

        vm.warp(END_OF_WHITELIST + 1);
        vm.prank(USER);

        vm.expectRevert();
        preSale.claimAmount(600, false);
    }

    function testVestingWorks() public {
        hoax(USER, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();

        vm.warp(END_OF_WHITELIST + 1);
        vm.prank(USER);

        preSale.claimAmount(0, true);

        assert(token.balanceOf(USER) == 62777777777775000000000);

        vm.warp(END_OF_WHITELIST + MONTH + 1);
        vm.prank(USER);

        preSale.claimAmount(0, true);

        assert(token.balanceOf(USER) == 62777777777775000000000 * 2);
    }

    function testCoinsBought() public {
        hoax(USER, 1 ether);
        preSale.joinWhiteList{value: 0.5 ether}();

        assert(preSale.getCoinsBought(USER) == 62777777777770000000000);

        vm.warp(END_OF_WHITELIST + 1);
        vm.prank(USER);

        preSale.claimAmount(0, true);

        assert(token.balanceOf(USER) == 31388888888885000000000);

        vm.warp(END_OF_WHITELIST + MONTH + 1);
        vm.prank(USER);

        preSale.claimAmount(0, true);

        assert(token.balanceOf(USER) == 62777777777770000000000);
    }

    // New test for random airdrop functionality
    function testRandomAirdrop() public joinWhitelist {
        // Select random users for the airdrop
        hoax(USER, 1 ether);
        preSale.joinWhiteList{value: 1 ether}();
        vm.prank(msg.sender);
        preSale.selectRandomUsers();

        for (uint256 i = 0; i < 10; i++) {
            address user = users[i];
            bool selected = preSale.s_randomSelected(user);
            console.log(selected, " ", user);
        }

        // Check how many users were selected

        // Distribute the rewards

        // Ensure that selected users received their rewards
        uint256 totalReward = 50000000 ether;
        uint256 rewardPerUser = totalReward / 1;
        console.log("function finished");
        for (uint256 i = 0; i < 10; i++) {
            address user = users[i];
            if (preSale.s_randomSelected(user)) {
                console.log("Userdsds: ");
                assert(token.balanceOf(user) == rewardPerUser);
            } else {
                assert(token.balanceOf(user) == 0);
            }
        }
    }
}
