// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract PreSale is Ownable {
    /* ----------------------- ERRORS ----------------------- */
    error WhiteListEnded();
    error MaximumCapExceeded();
    error AlreadyJoined();
    error WhiteListHaveNotEnded();
    error AlreadyClaimed();
    error CantWithdrawThatMuch();
    error CantWithdrawZero();
    error NoUsersSelected();

    /* ----------------------- STATE VARIABLES ----------------------- */
    uint256 private constant TGE = 1735131559; // TGE set to 25 of December 2024
    uint256 private constant END_OF_WHITELIST = 1737809959; // One month after TGE cliff
    uint256 private constant COINS_ALLOCATED = 750000000 ether;
    uint256 private constant TOTAL_REWARD = 50000000 ether; // Total tokens to distribute

    IERC20 public s_token;
    uint256 private s_coinsSold;
    uint256 private s_pricePerCoinInUSD = 45; // Store as an integer (0.0045 * 10**4 = 45)
    uint256 private s_usersWithRewards = 0;

    mapping(address => uint256) private s_coinsBought;
    mapping(address => bool) private s_whiteList;
    mapping(address => uint256) private s_amountClaimed;
    mapping(address => bool) public s_randomSelected; // Track selected users
    address[] private s_whitelistedUsers; // Store all whitelisted users

    AggregatorV3Interface internal s_priceFeed;

    /* ----------------------- EVENTS ----------------------- */
    event JoinedWhiteList(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);
    event RewardsDistributed(uint256 totalUsers, uint256 selectedUsers);

    constructor(IERC20 token, address _priceFeed) Ownable(msg.sender) {
        // Initialize the Chainlink price feed contract
        s_token = token;
        s_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /* ----------------------- FUNCTIONS ----------------------- */
    /**
     * @notice Function to join the whitelist
     */
    function joinWhiteList() public payable {
        uint256 tokenAmount = calculateTokens(msg.value);
        if (block.timestamp > END_OF_WHITELIST) {
            revert WhiteListEnded();
        }

        if (s_whiteList[msg.sender]) {
            revert AlreadyJoined();
        }

        if (s_coinsSold + tokenAmount > COINS_ALLOCATED) {
            revert MaximumCapExceeded();
        }

        s_whiteList[msg.sender] = true;
        s_coinsBought[msg.sender] = tokenAmount;
        s_amountClaimed[msg.sender] = 0;
        s_coinsSold += tokenAmount;
        s_whitelistedUsers.push(msg.sender); // Store whitelisted user

        emit JoinedWhiteList(msg.sender, tokenAmount);
    }

    /**
     * @notice Claim tokens
     * @param amount The anout of tokens to claim
     */
    function claimAmount(uint256 amount, bool all) public {
        if (block.timestamp < END_OF_WHITELIST) {
            revert WhiteListHaveNotEnded();
        }
        if (getClaimableAmount(msg.sender) == 0) {
            revert AlreadyClaimed();
        }

        if (amount > getClaimableAmount(msg.sender)) {
            revert CantWithdrawThatMuch();
        }
        if (amount == 0 && !all) {
            revert CantWithdrawZero();
        }
        if (amount == 0 && all) {
            amount = getClaimableAmount(msg.sender);
        }

        s_amountClaimed[msg.sender] += amount;
        s_token.transfer(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    /**
     * @notice Distribute tokens
     */

    function distributeRewards() public onlyOwner {
        uint256 totalUsers = s_whitelistedUsers.length;

        require(s_usersWithRewards > 0, "No users selected for distribution");

        uint256 rewardPerUser = TOTAL_REWARD / s_usersWithRewards; // Equal distribution

        for (uint256 i = 0; i < totalUsers; i++) {
            if (s_randomSelected[s_whitelistedUsers[i]]) {
                s_token.transfer(s_whitelistedUsers[i], rewardPerUser); // Transfer tokens
            }
        }
    }

    /* ----------------------- HELPER FUNCTIONS ----------------------- */
    function calculateTokens(uint256 bnbAmount) public view returns (uint256) {
        (, int256 price, , , ) = s_priceFeed.latestRoundData();
        uint256 bnbPriceInUSD = uint256(price);

        uint256 dollarValue = (bnbAmount * bnbPriceInUSD) / 1e18;

        return ((dollarValue * 10000) / s_pricePerCoinInUSD) * 1e10;
    }

    function getClaimableAmount(address _user) public view returns (uint256) {
        uint256 userClaimedAmount = s_amountClaimed[_user];
        uint256 userCoinsBought = s_coinsBought[_user];
        uint256 elapsedTime = block.timestamp - END_OF_WHITELIST;

        if (elapsedTime < 0) {
            return 0;
        }

        uint256 initialClaim = (userCoinsBought * 50) / 100; // 50% at TGE
        uint256 remainingAllocation = 0;

        // Calculate additional vested tokens
        if (elapsedTime >= 30 days) {
            remainingAllocation = userCoinsBought - initialClaim;
        }

        uint256 totalClaimable = initialClaim + remainingAllocation;
        return totalClaimable - userClaimedAmount;
    }

    function selectRandomUsers() public onlyOwner {
        uint256 totalUsers = s_whitelistedUsers.length;
        uint256 selectedCount = totalUsers / 10; // 10% of users

        // Reset previous selection
        for (uint256 i = 0; i < totalUsers; i++) {
            s_randomSelected[s_whitelistedUsers[i]] = false;
        }

        // Randomly select users
        for (uint256 i = 0; i < selectedCount; i++) {
            uint256 randomIndex = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.prevrandao, i)
                )
            ) % totalUsers;

            address selectedUser = s_whitelistedUsers[randomIndex];

            // Ensure the user hasn't been selected already
            if (!s_randomSelected[selectedUser]) {
                s_randomSelected[selectedUser] = true;
                s_usersWithRewards++;
            }
        }

        distributeRewards();
        emit RewardsDistributed(totalUsers, selectedCount);
    }

    /* ----------------------- GETTER ----------------------- */

    function getUserJoined(address _user) public view returns (bool) {
        return s_whiteList[_user];
    }

    function getCoinsBought(address _user) public view returns (uint256) {
        return s_coinsBought[_user];
    }

    function getAmountClaimed(address _user) public view returns (uint256) {
        return s_amountClaimed[_user];
    }
}
