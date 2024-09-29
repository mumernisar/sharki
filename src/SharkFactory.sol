// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ReentrancyGuard} from "./ReentrancyGuard.sol";
import {Sharki} from "./Sharki.sol";

contract SharkFactory {
    address[] public deployedCampaigns;
    mapping(address => address[]) public managerContracts;
    mapping(address => address[]) public contributorContracts;

    event CampaignCreated(address campaignAddress);
    event ContributionRecorded(address contributor, address campaign);
    event ManagerRecorded(address manager, address campaign);

    function createCampaign(uint minimum) public {
        address newCampaign = address(
            new Sharki(minimum, msg.sender, address(this))
        );
        deployedCampaigns.push(newCampaign);
        managerContracts[msg.sender].push(newCampaign);
        emit CampaignCreated(newCampaign);
        emit ManagerRecorded(msg.sender, newCampaign);
    }

    function getDeployedCampaigns() public view returns (address[] memory) {
        return deployedCampaigns;
    }

    function recordContribution(
        address contributor,
        address campaign
    ) external {
        contributorContracts[contributor].push(campaign);
        emit ContributionRecorded(contributor, campaign);
    }

    function getContributorContracts(
        address contributor
    ) external view returns (address[] memory) {
        return contributorContracts[contributor];
    }

    function getManagerContracts(
        address manager
    ) external view returns (address[] memory) {
        return managerContracts[manager];
    }
}
