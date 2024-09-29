// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {SharkFactory} from "./SharkFactory.sol";

contract Sharki is ReentrancyGuard {
    address public immutable i_manager;
    uint public immutable i_minContr;
    uint8 public stockLeft = 100;
    SharkFactory public factory;

    struct Request {
        string description;
        uint amount;
        address recipient;
        bool complete;
        uint approvalCount;
        mapping(address => bool) approvals;
    }

    struct ContributionRequest {
        address contributer;
        uint8 stockRequested;
        uint value;
    }

    mapping(address => uint8) public contributers;
    uint public contributerCount;
    Request[] public requests;
    ContributionRequest[] public contributerRequests;

    event RequestCreated(string description, uint amount, address recipient);
    event ContributionMade(address contributer, uint8 stockRequested, uint value);
    event ContributionApproved(address contributer, uint8 stockRequested);
    event ContributionDeclined(address contributer, uint value);
    event RequestApproved(uint reqIndex, address approver);
    event RequestFinalized(uint reqIndex, address recipient, uint amount);

    constructor(uint minContribution, address sender, address factoryAddress) {
        i_minContr = minContribution;
        i_manager = sender;
        factory = SharkFactory(factoryAddress);
    }

    // External functions
    function createRequest(string calldata description, uint amount, address recipient) external onlyManager {
        Request storage req = requests.push();
        req.description = description;
        req.amount = amount;
        req.recipient = recipient;
        req.complete = false;
        req.approvalCount = 0;
        emit RequestCreated(description, amount, recipient);
    }

    function getContributionRequestLength() external view returns (uint) {
        return contributerRequests.length;
    }

    function contribute(uint8 shareReq) external payable {
        require(msg.value > i_minContr, "Not enough contribution");
        require(shareReq <= stockLeft, "Not enough stock left");
        contributerRequests.push(ContributionRequest({
            contributer: msg.sender,
            stockRequested: shareReq,
            value: msg.value
        }));
        factory.recordContribution(msg.sender, address(this));
        emit ContributionMade(msg.sender, shareReq, msg.value);
    }

    function approveContribution(uint index, address contributer) external onlyManager {
        ContributionRequest storage request = contributerRequests[index];
        require(request.contributer == contributer, "Invalid contributor");
        require(request.stockRequested <= stockLeft, "Not enough stock left");

        contributers[contributer] += request.stockRequested;
        stockLeft -= request.stockRequested;

        contributerRequests[index] = contributerRequests[contributerRequests.length - 1];
        contributerRequests.pop();
        contributerCount++;
        emit ContributionApproved(contributer, request.stockRequested);
    }

    function declineRequest(uint index, address contributer) external onlyManager nonReentrant {
        ContributionRequest storage request = contributerRequests[index];
        require(request.contributer == contributer, "Invalid contributor");

        (bool success, ) = contributer.call{value: request.value}("");
        require(success, "Transfer failed");

        contributerRequests[index] = contributerRequests[contributerRequests.length - 1];
        contributerRequests.pop();
        emit ContributionDeclined(contributer, request.value);
    }

    function approve(uint reqIndex) external {
        Request storage req = requests[reqIndex];
        require(contributers[msg.sender] > 0, "Not a contributor");
        require(!req.approvals[msg.sender], "Already approved");

        req.approvals[msg.sender] = true;
        req.approvalCount++;
        emit RequestApproved(reqIndex, msg.sender);
    }

    function finalize(uint reqIndex) external onlyManager nonReentrant {
        Request storage req = requests[reqIndex];
        require(req.approvalCount > contributerCount / 2, "Not enough approvals");
        require(address(this).balance >= req.amount, "Insufficient balance");

        (bool success, ) = req.recipient.call{value: req.amount}("");
        require(success, "Transfer failed");

        req.complete = true;
        emit RequestFinalized(reqIndex, req.recipient, req.amount);
    }

    // Modifiers
    modifier onlyManager() {
        require(msg.sender == i_manager, "Unauthorized");
        _;
    }
}