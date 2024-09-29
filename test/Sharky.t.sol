// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Sharky.sol";

contract SharkyTest is Test {
    SharkFactory factory;
    Sharky campaign;
    address manager;
    address contributor1;
    address contributor2;

    function setUp() public {
        manager = address(this);
        contributor1 = address(0x123);
        contributor2 = address(0x456);

        factory = new SharkFactory();
        factory.createCampaign(100);

        address campaignAddress = factory.getDeployedCampaigns()[0];
        campaign = Sharky(campaignAddress);
    }

    function testCreateCampaign() public view {
        assertEq(factory.getDeployedCampaigns().length, 1);
    }

    function testManagerIsCorrect() public view {
        assertEq(campaign.manager(), manager);
    }

    function testContribute() public {
        vm.deal(contributor1, 1 ether);
        vm.prank(contributor1);
        campaign.contribute{value: 200}(10);

        (address contributer, uint8 stockRequested, uint value) = campaign
            .contributerRequests(0);
        assertEq(contributer, contributor1);
        assertEq(stockRequested, 10);
        assertEq(value, 200);
    }

    function testApproveContribution() public {
        _contribute(contributor1, 200, 10);

        vm.prank(manager);
        campaign.approveContribution(0, contributor1);
        uint8 approvedContributer = campaign.contributers(contributor1);
        assertEq(approvedContributer, uint8(10));
        assertEq(campaign.contributerCount(), 1);
    }

    function testDeclineRequest() public {
        _contribute(contributor1, 200, 10);

        vm.prank(manager);
        campaign.declineRequest(0, contributor1);

        assertEq(campaign.getContributionRequestLength(), 0);
    }

    function testCreateRequest() public {
        vm.prank(manager);
        campaign.createRequest("Buy batteries", 100, contributor1);

        (
            string memory description,
            uint amount,
            address recipient,
            bool complete,
            uint approvalCount
        ) = campaign.requests(0);
        assertEq(description, "Buy batteries");
        assertEq(amount, 100);
        assertEq(recipient, contributor1);
        assertEq(complete, false);
        assertEq(approvalCount, 0);
    }

    function testApproveRequest() public {
        _createRequest("Buy batteries", 100, contributor1);
        _contribute(contributor1, 200, 10);

        vm.prank(manager);
        campaign.approveContribution(0, contributor1);
        vm.prank(contributor1);
        campaign.approve(0);

        (, , , , uint approvalCount) = campaign.requests(0);
        assertEq(approvalCount, 1);
    }

    function testFinalizeRequest() public {
        _createRequest("Buy batteries", 100, contributor1);
        _contribute(contributor1, 200, 10);

        vm.prank(manager);
        campaign.approveContribution(0, contributor1);
        vm.prank(contributor1);
        campaign.approve(0);

        vm.prank(manager);
        campaign.finalize(0);

        (, , , bool complete, ) = campaign.requests(0);
        assertEq(complete, true);
    }

    function testContributeFailsIfNotEnoughContribution() public {
        vm.deal(contributor1, 1 ether);
        vm.prank(contributor1);
        vm.expectRevert("Not enough contribution");
        campaign.contribute{value: 50}(10);
    }

    function testContributeFailsIfNotEnoughStock() public {
        vm.deal(contributor1, 1 ether);
        vm.prank(contributor1);
        vm.expectRevert("Not enough stock left");
        campaign.contribute{value: 200}(101);
    }

    function testApproveContributionFailsIfNotManager() public {
        _contribute(contributor1, 200, 10);

        vm.prank(contributor1);
        vm.expectRevert("Unauthorized");
        campaign.approveContribution(0, contributor1);
    }

    function testDeclineRequestFailsIfNotManager() public {
        _contribute(contributor1, 200, 10);

        vm.prank(contributor1);
        vm.expectRevert("Unauthorized");
        campaign.declineRequest(0, contributor1);
    }

    function testApproveFailsIfNotContributor() public {
        _createRequest("Buy batteries", 100, contributor1);

        vm.prank(contributor2);
        vm.expectRevert();
        campaign.approve(0);
    }

    function testFinalizeFailsIfNotEnoughApprovals() public {
        _createRequest("Buy batteries", 100, contributor1);
        _contribute(contributor1, 200, 10);

        vm.prank(manager);
        campaign.approveContribution(0, contributor1);

        vm.deal(manager, 1 ether);
        vm.prank(manager);
        campaign.contribute{value: 200}(10);

        vm.prank(manager);
        campaign.approveContribution(0, manager);

        vm.prank(contributor1);
        campaign.approve(0);

        vm.prank(manager);
        vm.expectRevert();
        campaign.finalize(0);
    }

    // Helper functions
    function _contribute(
        address contributor,
        uint value,
        uint8 stockRequested
    ) internal {
        vm.deal(contributor, 1 ether);
        vm.prank(contributor);
        campaign.contribute{value: value}(stockRequested);
    }

    function _createRequest(
        string memory description,
        uint amount,
        address recipient
    ) internal {
        vm.prank(manager);
        campaign.createRequest(description, amount, recipient);
    }
}
