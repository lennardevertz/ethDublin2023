// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./campaign.sol";

/**
 * @title CampaignFactory
 * @author levertz <levertz@idriss.xyz>
 * @notice This is a contract for creating different campaign contracts
 * @notice This contract was built by project <Turtleneck> at ethDublin 2023.
 */
contract CampaignFactory {

    Campaign private campaign;

    mapping(uint256 => address) public campaigns;
    uint256 public campaignCounter;

    constructor() {
    }

    function setupCampaign(
        uint256 _fundingGoal,
        uint256 _sharedReturnPercentage,
        string memory _campaignName,
        uint256 _fundingPeriodInDays,
        uint256 _campaignDurationInDays,
        string memory _nftMetadataIPFSHash
    ) public {
        require(_fundingGoal > 0, "Funding goal must be greater than zero.");
        require(
            _sharedReturnPercentage <= 100,
            "Shared return percentage must be <=100."
        );
        require(_fundingPeriodInDays > 0 && _campaignDurationInDays > _fundingPeriodInDays, "Funding period must be greater than zero and difference must be positive.");

        campaign = new Campaign(
            _fundingGoal,
            _sharedReturnPercentage,
            _campaignName,
            _fundingPeriodInDays,
            _campaignDurationInDays,
            campaignCounter+1,
            _nftMetadataIPFSHash,
            msg.sender
        );

        campaigns[campaignCounter + 1] = address(campaign);

        campaignCounter += 1;

    }
}
