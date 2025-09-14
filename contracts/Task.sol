// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Task {
    error Task__InvalidOperator(address invalidOperator);
    error Task__InvalidRewardToken(address rewardToken);
    error Task__InvalidRewardAmount(uint256 rewardAmount);

    event RewardSent(
        address indexed receiver,
        address indexed rewardToken,
        uint256 amount,
        uint256 timestamp
    );

    string private s_title;
    address private s_operator;
    address private s_taskOwner;
    uint256 private s_campaignTarget;
    uint256 private s_rewardClaimed;
    address private s_rewardToken;
    uint256 private s_rewardAmount;

    modifier onlyOperator() {
        if (msg.sender != s_operator) {
            revert Task__InvalidOperator(msg.sender);
        }
        _;
    }

    constructor(
        string memory _title,
        address _operator,
        address _taskOwner,
        uint256 _campaignTarget,
        address _rewardToken,
        uint256 _rewardAmount
    ) {
        if (_rewardToken == address(0)) {
            revert Task__InvalidRewardToken(_rewardToken);
        }
        if (_rewardAmount == 0) {
            revert Task__InvalidRewardAmount(_rewardAmount);
        }

        s_title = _title;
        s_operator = _operator;
        s_campaignTarget = _campaignTarget;
        s_taskOwner = _taskOwner;
        s_rewardToken = _rewardToken;
        s_rewardAmount = _rewardAmount;
    }

    function sendReward(address _receiver) public onlyOperator {
        s_rewardClaimed += 1;

        IERC20(s_rewardToken).transfer(_receiver, s_rewardAmount);

        emit RewardSent(
            _receiver,
            s_rewardToken,
            s_rewardAmount,
            block.timestamp
        );
    }

    function getTitle() external view returns (string memory) {
        return s_title;
    }

    function getRewardToken() external view returns (address) {
        return s_rewardToken;
    }

    function getRewardAmount() external view returns (uint256) {
        return s_rewardAmount;
    }

    function getTaskInfo()
        external
        view
        returns (
            string memory,
            address,
            address,
            uint256,
            uint256,
            uint256,
            address,
            uint256
        )
    {
        return (
            s_title,
            s_operator,
            s_taskOwner,
            s_campaignTarget,
            s_rewardClaimed,
            block.timestamp,
            s_rewardToken,
            s_rewardAmount
        );
    }
}
