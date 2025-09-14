// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Task} from "./Task.sol";
import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockERC20 is IERC20 {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Minimal implementation for other IERC20 functions
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
    function allowance(address, address) external pure returns (uint256) {
        return 0;
    }
    function approve(address, uint256) external pure returns (bool) {
        return true;
    }
    function transferFrom(
        address,
        address,
        uint256
    ) external pure returns (bool) {
        return true;
    }
}

contract TaskTest is Test {
    Task task;
    MockERC20 mockToken;

    string private constant TASK_TITLE = "Test Task";
    address private constant OPERATOR = address(0x1);
    address private constant TASK_OWNER = address(0x2);
    address private constant RECEIVER = address(0x3);
    uint256 private constant CAMPAIGN_TARGET = 200;
    uint256 private constant REWARD_AMOUNT = 10 ether;

    function setUp() public {
        // Deploy mock token
        mockToken = new MockERC20();

        // Deploy task contract
        task = new Task(
            TASK_TITLE,
            OPERATOR,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        // Mint tokens to task contract for testing
        mockToken.mint(address(task), REWARD_AMOUNT * 10);
    }

    function test_InitialValues() public view {
        assertEq(task.getTitle(), TASK_TITLE);
    }

    function test_GetTaskInfo() public view {
        // Act
        (
            string memory title,
            address operator,
            address taskOwner,
            uint256 campaignTarget,
            uint256 rewardClaimed,
            uint256 timestamp,
            address rewardToken,
            uint256 rewardAmount
        ) = task.getTaskInfo();

        // Assert
        assertEq(title, TASK_TITLE);
        assertEq(operator, OPERATOR);
        assertEq(taskOwner, TASK_OWNER);
        assertEq(campaignTarget, CAMPAIGN_TARGET);
        assertEq(rewardClaimed, 0); // Initially no rewards claimed
        assertEq(timestamp, block.timestamp);
        assertEq(rewardToken, address(mockToken));
        assertEq(rewardAmount, REWARD_AMOUNT);
    }

    function test_SendReward_Success() public {
        // Arrange
        vm.startPrank(OPERATOR);
        uint256 initialBalance = mockToken.balanceOf(RECEIVER);

        // Act
        task.sendReward(RECEIVER);

        // Assert
        assertEq(mockToken.balanceOf(RECEIVER), initialBalance + REWARD_AMOUNT);
    }

    function test_SendReward_RevertWhen_NotOperator() public {
        // Arrange
        vm.prank(TASK_OWNER); // not operator

        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Task.Task__InvalidOperator.selector,
                TASK_OWNER
            )
        );
        task.sendReward(RECEIVER);
    }

    function test_Constructor_RevertWhen_InvalidRewardToken() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Task.Task__InvalidRewardToken.selector,
                address(0)
            )
        );
        new Task(
            TASK_TITLE,
            OPERATOR,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(0), // Invalid token address
            REWARD_AMOUNT
        );
    }

    function test_Constructor_RevertWhen_InvalidRewardAmount() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(Task.Task__InvalidRewardAmount.selector, 0)
        );
        new Task(
            TASK_TITLE,
            OPERATOR,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            0 // Invalid reward amount
        );
    }

    function test_SendReward_EmitsEvent() public {
        // Arrange
        vm.prank(OPERATOR);

        // Act & Assert
        vm.expectEmit(true, true, false, true);
        emit Task.RewardSent(
            RECEIVER,
            address(mockToken),
            REWARD_AMOUNT,
            block.timestamp
        );

        task.sendReward(RECEIVER);
    }

    function test_GetRewardToken() public view {
        assertEq(task.getRewardToken(), address(mockToken));
    }

    function test_GetRewardAmount() public view {
        assertEq(task.getRewardAmount(), REWARD_AMOUNT);
    }
}
