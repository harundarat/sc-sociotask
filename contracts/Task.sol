// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Task {
    error Task__RewardArrayLengthMismatch(
        uint256 addressesLength,
        uint256 rewardsLength
    );
    error Task__InvalidOperator(address invalidOperator);
    error Task__RewardNotAvailable(address rewardToken);

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
    mapping(address token => uint amount) private rewards;

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
        address[] memory _rewardTokenAddresses,
        uint256[] memory _rewardTokenAmount
    ) {
        s_title = _title;
        s_operator = _operator;
        s_campaignTarget = _campaignTarget;
        s_taskOwner = _taskOwner;

        if (_rewardTokenAddresses.length != _rewardTokenAmount.length) {
            revert Task__RewardArrayLengthMismatch(
                _rewardTokenAddresses.length,
                _rewardTokenAmount.length
            );
        }

        for (uint256 i = 0; i < _rewardTokenAddresses.length; i++) {
            rewards[_rewardTokenAddresses[i]] = _rewardTokenAmount[i];
        }
    }

    function sendReward(
        address _receiver,
        address _rewardToken
    ) public onlyOperator {
        if (rewards[_rewardToken] == 0) {
            revert Task__RewardNotAvailable(_rewardToken);
        }

        s_rewardClaimed += 1;

        IERC20(_rewardToken).transfer(_receiver, rewards[_rewardToken]);

        emit RewardSent(
            _receiver,
            _rewardToken,
            rewards[_rewardToken],
            block.timestamp
        );
    }

    function getTitle() external view returns (string memory) {
        return s_title;
    }

    function getTaskInfo()
        external
        view
        returns (string memory, address, address, uint256, uint256, uint256)
    {
        return (
            s_title,
            s_operator,
            s_taskOwner,
            s_campaignTarget,
            s_rewardClaimed,
            block.timestamp
        );
    }
}
