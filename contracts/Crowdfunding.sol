// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract Crowdfunding {

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

    uint256 public votingDuration;  // Duration for voting period
    uint256 public startVotingTime; // Start time of the voting
    uint256 public maxVotingTime = 2;   // Max voting time

    //error NotProjectCreator();
    //error DirectTransferNotAllowed();

   /*  event DonationReceived(address contributor, uint256 amount);
    event RequestCreated(string details);
    event VotingResult(bool approved);
    event FundsTransferredToCreator(address recipient, uint256 amount);
    event FundsReturned(address contributor, uint256 amount); */

    constructor(uint256 _goal, uint256 _deadline, string memory _purpose, uint256 _votingDuration) {
        //require(_deadline > block.timestamp + 1 days, "Deadline must be at least 24 hours from now.");
        //require(_votingDuration >= 120, "Voting duration must be at least 2 minutes.");
        projectCreator = msg.sender;
        goal = _goal;
        deadline = _deadline;
        purpose = _purpose;
        isFundingEnded = false;
        votingDuration = _votingDuration;
    }

    modifier onlyProjectCreator {
        require(msg.sender == projectCreator, "NotProjectCreator");
        _;
    }

    modifier onlyWhenPayable() {
        require(!isFundingEnded && !hasVotingStarted, "Contract is no longer payable");
        _;
    }

    function donate() onlyWhenPayable public payable {
        require(msg.sender != projectCreator, "Creator cannot donate");
        require(block.timestamp < deadline, "Deadline has passed");
        require(msg.value > 0, "Donation must be greater than 0");

        if (contributorsToAmount[msg.sender] == 0) {
            contributors.push(msg.sender);
        }

        contributorsToAmount[msg.sender] += msg.value;
        raisedAmount += msg.value;


        if (raisedAmount >= goal) {
            hasVotingStarted = true;
            startVotingTime = block.timestamp;
        }
    }

    function createSpendingRequest(string memory _details) onlyProjectCreator public {
        require(!isRequestReady, "Waiting for the voting results of the previous request");
        request = _details;
        isRequestReady = true;

        
    }

    function voteOnSpending(bool _approve) public {
        require(!isFundingEnded, "Fundraising has ended");
        require(hasVotingStarted && isRequestReady, "Voting hasn't started yet or there is no spending request yet");
        require(contributorsToAmount[msg.sender] > 0, "You must contribute to vote");
        require(!contributorsToVote[msg.sender], "You have already voted");

        contributorsToVote[msg.sender] = true;
        if (_approve) {
            approvalVotes++;
        }

        // Check if majority approves or voting time has passed
        if (approvalVotes > contributors.length / 2) {
            approved = true;
            sendFundsToCreator();
            
        } else if (block.timestamp >= startVotingTime + votingDuration) {
            // If voting period has passed without approval, reset for new voting
            if(maxVotingTime == 0){
                returnFunds();
            } else {
                maxVotingTime--;
                resetVoting();
                
            }
        }

    }

    function sendFundsToCreator() internal {
        isFundingEnded = true;
        isRequestReady = false;

        (bool sent, ) = payable(projectCreator).call{value: raisedAmount}("");
        require(sent, "Failed to send Ether");


        raisedAmount = 0;
    }

    function resetVoting() internal {
        isRequestReady = false;
        approvalVotes = 0;
        for (uint256 i = 0; i < contributors.length; i++) {
            contributorsToVote[contributors[i]] = false;
        }
    }

    function returnFunds() internal {
        isFundingEnded = true;
        for (uint256 i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint256 amount = contributorsToAmount[contributor];

            if (amount > 0) {
                contributorsToAmount[contributor] = 0;
                (bool sent, ) = payable(contributor).call{value: amount}("");
                require(sent, "Failed to send Ether");
                
            }
        }

        delete contributors;
        delete approvalVotes;
        delete isRequestReady;
        delete approved;
    }

    receive() external payable {
        revert("DirectTransferNotAllowed");
    }

     fallback() external payable {
        revert("DirectTransferNotAllowed");
    }
}
