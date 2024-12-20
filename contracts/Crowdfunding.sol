// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Crowdfunding {

    // !! voting phase should start after goal is reached.
    // !! contributors should add some extra amount to their funds in case funds are returned. 
    // This return process costs some gas too.


    address public projectCreator;
    uint256 public goal;
    uint256 public raisedAmount;
    uint256 public deadline;
    string public purpose;
    string public request;

    uint256 public approvalVotes;
    mapping(address => uint256) public contributorsToAmount;
    mapping(address => bool) public contributorsToVote;
    address[] public contributors;
    
    bool public isRequestReady;
    bool public approved; 
    bool public isFundingEnded;
    bool public hasVotingStarted;

    error NotProjectCreator();

    constructor(address _creator, uint256 _goal, uint256 _deadline, string memory _purpose) {
        projectCreator = _creator;
        goal = _goal;
        deadline = _deadline;
        purpose = _purpose;
        isFundingEnded = false;
    }

    modifier onlyProjectCreator {
        if (msg.sender != projectCreator) revert NotProjectCreator();
        _;
    }

    modifier onlyWhenPayable() {
        require(!isFundingEnded || !hasVotingStarted, "Contract is no longer payable");
        _;
    }

    function donate() onlyWhenPayable public payable {
        require(msg.sender != projectCreator, "Creator cannot donate");
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value > 0, "Donation must be greater than 0");

        contributorsToAmount[msg.sender] += msg.value;
        raisedAmount += msg.value;

        if(raisedAmount >= goal){
            hasVotingStarted = true;
        }

        // TO-DO

        bool isContributor = false;
        for (uint256 i = 0; i < contributors.length; i++) 
        {
            if(contributors[i] == msg.sender){
                isContributor = true;
                break;   
            }
        }
        if(!isContributor){
            contributors.push(msg.sender);
        }

    }

    // Function for project creator to create a spending request
    function createSpendingRequest(string memory _details) onlyProjectCreator public {
        require(!isRequestReady, "Waiting for the voting results of the previous request");
        request = _details;
        isRequestReady = true;
    }

    // Function for contributors to vote on spending
    function voteOnSpending(bool _approve) public {
        require(hasVotingStarted && isRequestReady, "Voting hasn't started yet or there is no spending request yet");
        require(contributorsToAmount[msg.sender] > 0, "You must contribute to vote");
        require(!contributorsToVote[msg.sender], "You have already voted");

        contributorsToVote[msg.sender] = true;
        if (_approve) {
            approvalVotes++;
        }

        // be careful here, floating-point numbers
        if (approvalVotes > contributors.length / 2) {
            approved = true;
            sendFundsToCreator();
        }

        // TO-DO

    }

    function sendFundsToCreator() internal {
        // TO-DO
        isFundingEnded = true;
        (bool sent, ) = payable(projectCreator).call{value: raisedAmount}("");
        require(sent, "Failed to send Ether");
        raisedAmount = 0;
    }

    function returnFunds() internal {
        // TO-DO
        for (uint256 i = 0; i < contributors.length; i++) 
        {
            (bool sent, ) = payable(contributors[i]).call{value: contributorsToAmount[contributors[i]]}("");
            require(sent, "Failed to send Ether");
            // what do we do after funds are returned? contributors, contributorsToAmount...
        }
    }

    // TO-DO
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}