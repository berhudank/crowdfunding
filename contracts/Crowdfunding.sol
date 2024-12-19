// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Crowdfunding {

    // !! voting phase should start after goal is reached.

    address public projectCreator;
    uint256 public goal;
    uint256 public raisedAmount;
    uint256 public deadline;
    mapping(address => uint256) public contributions;
    mapping(address => bool) public hasVoted;
    address[] public contributors;
    uint256 public approvalVotes;
    string purpose;

    // Events
    event FundReceived(address contributor, uint256 amount);
    event SpendingRequestCreated(string details);
    event SpendingApproved(uint256 approvalVotes);
    event SpendingDenied();

    error NotProjectCreator();

    constructor(address _creator, uint256 _goal, uint256 _deadline) {
        projectCreator = _creator;
        goal = _goal;
        deadline = _deadline;
    }

    modifier onlyProjectCreator {
        if (msg.sender != projectCreator) revert NotProjectCreator();
        _;
    }

    function donate() public payable {
        require(msg.sender != projectCreator, "Creator cannot donate");
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value > 0, "Donation must be greater than 0");

        contributions[msg.sender] += msg.value;
        raisedAmount += msg.value;
        contributors.push(msg.sender);

        emit FundReceived(msg.sender, msg.value);
    }

    // Function for project creator to create a spending request
    function createSpendingRequest(string memory _details) onlyProjectCreator public {
        emit SpendingRequestCreated(_details);
    }

    // Function for contributors to vote on spending
    function voteOnSpending(bool _approve) public {
        require(contributions[msg.sender] > 0, "You must contribute to vote");
        require(!hasVoted[msg.sender], "You have already voted");

        hasVoted[msg.sender] = true;
        if (_approve) {
            approvalVotes += contributions[msg.sender];
        }

        // be careful here, floating-point numbers
        if (approvalVotes > contributors.length / 2) {
            emit SpendingApproved(approvalVotes);
        }
        // SpendingDenied() should be emmited when timestamp reached and there aren't enough approvals, 
        //or all backers don't approve 
    }

    function withdrawFunds() onlyProjectCreator public payable {
        // TO-DO

        // only can return if creator has the approval 
    }

    function returnFunds() internal {
        // TO-DO
    }

    // TO-DO
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}