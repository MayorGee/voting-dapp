// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Voting {
    struct Proposal {
        address target;
        bytes data;
        uint yesCount;
        uint noCount;
        bool executed;
    }

    enum Vote { None, Yes, No }
    mapping(address => bool) public isMember;

    Proposal[] public proposals;
    mapping(address => mapping(uint => bool)) hasVoted;
    mapping(address => mapping(uint => Vote)) choice;

    uint public constant MIN_YES_VOTES = 3;

    event ProposalCreated(uint);
    event VoteCast(uint, address);
    event MemberAdded(address);
    event MemberRemoved(address);
    event ProposalExecuted(uint);

    constructor() {
        isMember[msg.sender] = true;
        emit MemberAdded(msg.sender);
    }

    function addMember(address newMember) external {
        require(isMember[msg.sender], "Authorized access only");
        require(!isMember[newMember], "Address is already a member");
        require(newMember != address(0), "Invalid member address");

        isMember[newMember] = true;
        emit MemberAdded(newMember);
    }

    function removeMember(address memberToRemove) external {
        require(isMember[msg.sender], "Authorized access only");
        require(isMember[memberToRemove], "Address is not a member");

        isMember[memberToRemove] = false;
        emit MemberRemoved(memberToRemove);
    }

    function newProposal(address _target, bytes calldata _calldata) external {
        require(isMember[msg.sender], "Authorized access only");
        require(_target != address(0), "Invalid target address");

        proposals.push(Proposal(_target, _calldata, 0, 0, false));
        emit ProposalCreated(proposals.length - 1);
    }

    function castVote(uint proposalId, bool support) external {
        require(isMember[msg.sender], "Authorized access only");
        require(!proposals[proposalId].executed, "Proposal already executed");

        Vote currentVote = choice[msg.sender][proposalId];

        if (hasVoted[msg.sender][proposalId]) {
            if (currentVote == Vote.Yes && !support) {
                decrementProposalYescount(proposalId);
                incrementProposalNocount(proposalId);
            } else if (currentVote == Vote.No && support) {
                decrementProposalNocount(proposalId);
                incrementProposalYescount(proposalId);
            } else {
                revert("You can't vote the same thing twice");
            }
        } else {
            if (support) {
                incrementProposalYescount(proposalId);
            } else {
                incrementProposalNocount(proposalId);
            }
        }

        hasVoted[msg.sender][proposalId] = true;
        choice[msg.sender][proposalId] = support ? Vote.Yes : Vote.No;

        if (proposals[proposalId].yesCount == MIN_YES_VOTES && !proposals[proposalId].executed) {
            proposals[proposalId].executed = true;

            (bool success, ) = proposals[proposalId].target.call(proposals[proposalId].data);
            require(success, "Proposal execution failed");
            
            emit ProposalExecuted(proposalId);
        }

        emit VoteCast(proposalId, msg.sender);
    }

    function incrementProposalYescount(uint proposalId) internal {
        proposals[proposalId].yesCount++;
    }

    function incrementProposalNocount(uint proposalId) internal {
        proposals[proposalId].noCount++;
    }

    function decrementProposalYescount(uint proposalId) internal {
        proposals[proposalId].yesCount--;
    }

    function decrementProposalNocount(uint proposalId) internal {
        proposals[proposalId].noCount--;
    }
}