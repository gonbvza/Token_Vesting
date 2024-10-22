// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ImullStaking is Ownable {
    /* ----------------------- ERRORS ----------------------- */
    error ZeroAmount();
    error AlreadyStaked();
    error NotStaking();
    error NotEnoughTimeHasPassed();
    error NotEnoughBalance();
    error ErrorInTransaction();

    /* ----------------------- STATE VARIABLES ----------------------- */
    IERC20 public token;

    constructor(IERC20 _token) Ownable(msg.sender) {
        token = _token;
    }

    /* ----------------------- TYPE DEFINITIONS ----------------------- */
    mapping(address => Staker) public stakers;

    struct Staker {
        uint256 stakedTime;
        uint256 amountStaked;
        TimeChoosen timeChoosen;
    }

    enum TimeChoosen {
        one,
        six,
        tweelve,
        twentyfour
    }

    event Staked(address indexed user, uint256 amount);
    event unStaked(address indexed user, uint256 amount);

    /* ----------------------- FUNCTIONS ----------------------- */
    /**
     * @notice Stakes the amount of tokens
     * @param _amount The anout of tokens to stake
     */
    function stake(uint256 _amount, TimeChoosen _timeChoosen) public {
        if (_amount <= 0) {
            revert ZeroAmount();
        }
        if (stakers[msg.sender].amountStaked > 0) {
            revert AlreadyStaked();
        }

        bool transfer = token.transferFrom(msg.sender, address(this), _amount);

        if (!transfer) {
            revert ErrorInTransaction();
        }

        stakers[msg.sender] = Staker({
            stakedTime: block.timestamp,
            amountStaked: _amount,
            timeChoosen: _timeChoosen
        });

        emit Staked(msg.sender, _amount);
    }

    /**
     * @notice Unstakes the tokens
     */
    function unStake() public {
        uint256 amountStake = stakers[msg.sender].amountStaked;
        if (stakers[msg.sender].amountStaked == 0) {
            revert NotStaking();
        }

        uint256 locktime;
        uint256 percentageReward;
        if (stakers[msg.sender].timeChoosen == TimeChoosen.one) {
            locktime = 30 days;
            percentageReward = 1;
        } else if (stakers[msg.sender].timeChoosen == TimeChoosen.six) {
            locktime = 180 days;
            percentageReward = 7;
        } else if (stakers[msg.sender].timeChoosen == TimeChoosen.tweelve) {
            locktime = 365 days;
            percentageReward = 14;
        } else if (stakers[msg.sender].timeChoosen == TimeChoosen.twentyfour) {
            locktime = 730 days;
            percentageReward = 20;
        }

        if (block.timestamp < stakers[msg.sender].stakedTime + locktime) {
            revert NotEnoughTimeHasPassed();
        }
        uint256 reward = (amountStake * percentageReward) / 100;

        if (amountStake + reward > token.balanceOf(address(this))) {
            revert NotEnoughBalance();
        }

        bool transfer = token.transfer(
            msg.sender,
            stakers[msg.sender].amountStaked + reward
        );

        if (!transfer) {
            revert ErrorInTransaction();
        }

        delete stakers[msg.sender];

        emit unStaked(msg.sender, amountStake + reward);
    }
}
