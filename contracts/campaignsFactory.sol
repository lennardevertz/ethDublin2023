// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./campaign.sol";
import "./erc1155.sol";

/**
 * @title CampaignFactory
 * @author levertz <levertz@idriss.xyz>
 * @notice This is a contract for creating different campaign contracts
 * @notice This contract was built by project <Turtleneck> at ethDublin 2023.
 */
contract CampaignFactory {

    Campaign private campaign;
    MyERC1155 public customERC1155;

    mapping(uint256 => address) public campaigns;
    uint256 public campaignCounter;

    constructor(address _erc1155Address) {
        customERC1155 = MyERC1155(_erc1155Address);
    }

    error Factory_GoalMustBeBiggerThanZero();
    error Factory_SharedReturnSmaller100();
    error Factory_PeriodError();

    function setupCampaign(
        uint256 _fundingGoal,
        uint256 _sharedReturnPercentage,
        string memory _campaignName,
        uint256 _fundingPeriodInSeconds,
        uint256 _campaignDurationInSeconds,
        string memory _nftMetadataIPFSHash
    ) public {
        if (_fundingGoal <= 0){
            revert Factory_GoalMustBeBiggerThanZero();
        }
        if ( _sharedReturnPercentage > 100) {
            revert Factory_SharedReturnSmaller100();
        }
        if ( !(_fundingPeriodInSeconds > 0 && _campaignDurationInSeconds > _fundingPeriodInSeconds)) {
            revert Factory_PeriodError();
        }

        campaign = new Campaign(
            _fundingGoal,
            _sharedReturnPercentage,
            _campaignName,
            _fundingPeriodInSeconds,
            _campaignDurationInSeconds,
            campaignCounter+1,
            _nftMetadataIPFSHash,
            msg.sender,
            address(customERC1155)
        );

        customERC1155.addAdmin(address(campaign));

        // make campaign new admin of nft contract

        campaigns[campaignCounter + 1] = address(campaign);

        campaignCounter += 1;

    }

    function getNFTAddress() public view virtual returns (address) {
        return address(customERC1155);
    }
}
