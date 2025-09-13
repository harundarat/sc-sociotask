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
