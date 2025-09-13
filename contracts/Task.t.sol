// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Task} from "./Task.sol";
import {Test} from "forge-std/Test.sol";

contract TaskTest is Test {
    Task task;

    string private taskTitle = "Test";

    function setUp() public {
        address[] memory rewardTokens = new address[](1);
        rewardTokens[0] = address(0x3cdb204f93b923e21380eD52049410835e941591);
        uint256[] memory rewardAmounts = new uint256[](1);
        rewardAmounts[0] = 10;

        task = new Task(
            "Test",
            0x3cdb204f93b923e21380eD52049410835e941591,
            rewardTokens,
            rewardAmounts
        );
    }

    function test_InitialValue() public view {
        assertEq(task.getTitle(), taskTitle);
    }
}
