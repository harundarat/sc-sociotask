// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {TaskFactory} from "./TaskFactory.sol";
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

contract TaskFactoryTest is Test {
    TaskFactory taskFactory;
    Task taskImplementation;
    MockERC20 mockToken;

    address private constant OPERATOR = address(0x1);
    address private constant TASK_OWNER = address(0x2);
    string private constant TASK_TITLE = "Test Task";
    uint256 private constant CAMPAIGN_TARGET = 100;
    uint256 private constant REWARD_AMOUNT = 5 ether;

    event TaskCreated(
        address indexed taskAddress,
        address indexed taskOwner,
        string title,
        uint256 campaignTarget,
        address rewardToken,
        uint256 rewardAmount
    );

    function setUp() public {
        // Deploy mock token
        mockToken = new MockERC20();

        // Deploy task implementation
        taskImplementation = new Task();

        // Deploy task factory
        taskFactory = new TaskFactory(OPERATOR, address(taskImplementation));
    }

    function test_CreateTask_Success() public {
        // Act
        address createdTaskAddress = taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        // Assert
        assertTrue(createdTaskAddress != address(0));

        // Verify the created task has correct values
        Task createdTask = Task(createdTaskAddress);
        assertEq(createdTask.getTitle(), TASK_TITLE);
        assertEq(createdTask.getRewardToken(), address(mockToken));
        assertEq(createdTask.getRewardAmount(), REWARD_AMOUNT);

        // Verify task info
        (
            string memory title,
            address operator,
            address taskOwner,
            uint256 campaignTarget,
            uint256 rewardClaimed,
            ,
            address rewardToken,
            uint256 rewardAmount
        ) = createdTask.getTaskInfo();

        assertEq(title, TASK_TITLE);
        assertEq(operator, OPERATOR);
        assertEq(taskOwner, TASK_OWNER);
        assertEq(campaignTarget, CAMPAIGN_TARGET);
        assertEq(rewardClaimed, 0);
        assertEq(rewardToken, address(mockToken));
        assertEq(rewardAmount, REWARD_AMOUNT);
    }

    function test_CreateTask_EmitsEvent() public {
        // Arrange & Act & Assert
        vm.expectEmit(false, true, false, true);
        emit TaskCreated(
            address(0), // We don't know the exact address beforehand
            TASK_OWNER,
            TASK_TITLE,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );
    }

    function test_CreateTask_ReturnsUniqueAddresses() public {
        // Act
        address task1 = taskFactory.createTask(
            "Task 1",
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        address task2 = taskFactory.createTask(
            "Task 2",
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        // Assert
        assertTrue(task1 != task2);
        assertTrue(task1 != address(0));
        assertTrue(task2 != address(0));
    }

    function test_CreateTask_WithDifferentParameters() public {
        // Arrange
        address differentOwner = address(0x4);
        uint256 differentTarget = 500;
        uint256 differentReward = 20 ether;
        string memory differentTitle = "Different Task";

        // Act
        address createdTaskAddress = taskFactory.createTask(
            differentTitle,
            differentOwner,
            differentTarget,
            address(mockToken),
            differentReward
        );

        // Assert
        Task createdTask = Task(createdTaskAddress);
        assertEq(createdTask.getTitle(), differentTitle);
        assertEq(createdTask.getRewardAmount(), differentReward);

        (, , address taskOwner, uint256 campaignTarget, , , , ) = createdTask
            .getTaskInfo();

        assertEq(taskOwner, differentOwner);
        assertEq(campaignTarget, differentTarget);
    }

    function test_CreateTask_TaskIsProperlyInitialized() public {
        // Act
        address createdTaskAddress = taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        // Assert - Try to initialize again should fail
        Task createdTask = Task(createdTaskAddress);
        vm.expectRevert(
            abi.encodeWithSelector(Task.Task__AlreadyInitialized.selector)
        );

        createdTask.initialize(
            "Another Title",
            OPERATOR,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );
    }

    function test_CreateTask_OperatorCanSendRewards() public {
        // Arrange
        address receiver = address(0x5);
        mockToken.mint(address(this), REWARD_AMOUNT * 10);

        address createdTaskAddress = taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        // Transfer tokens to the created task
        mockToken.transfer(createdTaskAddress, REWARD_AMOUNT);

        // Act
        vm.prank(OPERATOR);
        Task(createdTaskAddress).sendReward(receiver);

        // Assert
        assertEq(mockToken.balanceOf(receiver), REWARD_AMOUNT);
    }

    function test_CreateTask_WithZeroRewardAmount_ShouldRevert() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                TaskFactory.TaskFactory__InvalidRewardAmount.selector
            )
        );

        taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            0 // Invalid reward amount
        );
    }

    function test_CreateTask_WithZeroAddressToken_ShouldRevert() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                TaskFactory.TaskFactory__InvalidAddress.selector
            )
        );

        taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(0), // Invalid token address
            REWARD_AMOUNT
        );
    }

    function test_CreateTask_MultipleTasksWithSameParameters() public {
        // Act
        address task1 = taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        address task2 = taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        // Assert
        assertTrue(task1 != task2);

        // Both tasks should have the same configuration
        Task taskContract1 = Task(task1);
        Task taskContract2 = Task(task2);

        assertEq(taskContract1.getTitle(), taskContract2.getTitle());
        assertEq(
            taskContract1.getRewardToken(),
            taskContract2.getRewardToken()
        );
        assertEq(
            taskContract1.getRewardAmount(),
            taskContract2.getRewardAmount()
        );
    }

    function test_CreateTask_EmptyTitle_ShouldRevert() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                TaskFactory.TaskFactory__InvalidTitle.selector
            )
        );

        taskFactory.createTask(
            "", // Empty title
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );
    }

    function test_CreateTask_ZeroCampaignTarget_ShouldRevert() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                TaskFactory.TaskFactory__InvalidCampaignTarget.selector
            )
        );

        taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            0, // Zero campaign target
            address(mockToken),
            REWARD_AMOUNT
        );
    }

    function test_CreateTask_ZeroAddressTaskOwner_ShouldRevert() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                TaskFactory.TaskFactory__InvalidAddress.selector
            )
        );

        taskFactory.createTask(
            TASK_TITLE,
            address(0), // Invalid task owner
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );
    }

    function test_GetterFunctions() public {
        // Assert
        assertEq(taskFactory.getOperator(), OPERATOR);
        assertEq(taskFactory.getImplementation(), address(taskImplementation));
        assertEq(taskFactory.getCreatedTasksCount(), 0);

        // Create a task and check count
        taskFactory.createTask(
            TASK_TITLE,
            TASK_OWNER,
            CAMPAIGN_TARGET,
            address(mockToken),
            REWARD_AMOUNT
        );

        assertEq(taskFactory.getCreatedTasksCount(), 1);
    }

    function test_Constructor_InvalidOperator_ShouldRevert() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                TaskFactory.TaskFactory__InvalidAddress.selector
            )
        );

        new TaskFactory(address(0), address(taskImplementation));
    }

    function test_Constructor_InvalidImplementation_ShouldRevert() public {
        // Act & Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                TaskFactory.TaskFactory__InvalidAddress.selector
            )
        );

        new TaskFactory(OPERATOR, address(0));
    }
}
