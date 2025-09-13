# Counter.sol

```sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract Counter {
  uint public x;

  event Increment(uint by);

  function inc() public {
    x++;
    emit Increment(1);
  }

  function incBy(uint by) public {
    require(by > 0, "incBy: increment should be positive");
    x += by;
    emit Increment(by);
  }
}

```

# Counter.t.sol

```sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Counter} from "./Counter.sol";
import {Test} from "forge-std/Test.sol";

contract CounterTest is Test {
  Counter counter;

  function setUp() public {
    counter = new Counter();
  }

  function test_InitialValue() public view {
    require(counter.x() == 0, "Initial value should be 0");
  }

  function testFuzz_Inc(uint8 x) public {
    for (uint8 i = 0; i < x; i++) {
      counter.inc();
    }
    require(counter.x() == x, "Value after calling inc x times should be x");
  }

  function test_IncByZero() public {
    vm.expectRevert();
    counter.incBy(0);
  }
}

```

# Task.sol

```sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Task {
    error Task__RewardArrayLengthMismatch(
        uint256 addressesLength,
        uint256 rewardsLength
    );

    string private s_title;
    address private s_taskOwner;
    mapping(address token => uint amount) private rewards;

    constructor(
        string memory _title,
        address _taskOwner,
        address[] memory _rewardTokenAddresses,
        uint256[] memory _rewardTokenAmount
    ) {
        s_title = _title;
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

    function getTitle() external view returns (string memory) {
        return s_title;
    }
}

```

# Task.t.sol

```sol
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

```

# TaskFactory.sol

```sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract TaskFactory {
    constructor() {}
}

```

