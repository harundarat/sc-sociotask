// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Task} from "./Task.sol";

contract TaskFactory {
    address private immutable i_operator;
    address private immutable i_implementation;
    uint256 private s_createdTasks;

    error TaskFactory__InvalidAddress();
    error TaskFactory__InvalidTitle();
    error TaskFactory__InvalidCampaignTarget();
    error TaskFactory__InvalidRewardAmount();

    event TaskCreated(
        address indexed taskAddress,
        address indexed taskOwner,
        string title,
        uint256 campaignTarget,
        address rewardToken,
        uint256 rewardAmount
    );

    constructor(address _operator, address _implementation) {
        if (_operator == address(0)) revert TaskFactory__InvalidAddress();
        if (_implementation == address(0)) revert TaskFactory__InvalidAddress();

        i_operator = _operator;
        i_implementation = _implementation;
    }

    function createTask(
        string memory _title,
        address _taskOwner,
        uint256 _campaignTarget,
        address _rewardToken,
        uint256 _rewardAmount
    ) public returns (address createdTask) {
        // Input validation
        if (bytes(_title).length == 0) revert TaskFactory__InvalidTitle();
        if (_taskOwner == address(0)) revert TaskFactory__InvalidAddress();
        if (_campaignTarget == 0) revert TaskFactory__InvalidCampaignTarget();
        if (_rewardToken == address(0)) revert TaskFactory__InvalidAddress();
        if (_rewardAmount == 0) revert TaskFactory__InvalidRewardAmount();

        s_createdTasks += 1;

        address newTask = Clones.clone(i_implementation);

        Task(newTask).initialize(
            _title,
            i_operator,
            _taskOwner,
            _campaignTarget,
            _rewardToken,
            _rewardAmount
        );

        emit TaskCreated(
            newTask,
            _taskOwner,
            _title,
            _campaignTarget,
            _rewardToken,
            _rewardAmount
        );

        return newTask;
    }

    // Getter functions
    function getOperator() external view returns (address) {
        return i_operator;
    }

    function getImplementation() external view returns (address) {
        return i_implementation;
    }

    function getCreatedTasksCount() external view returns (uint256) {
        return s_createdTasks;
    }
}
