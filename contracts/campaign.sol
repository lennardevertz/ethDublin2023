// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./erc1155.sol";


/**
 * @title Campaign
 * @author levertz <levertz@idriss.xyz>
 * @notice This is a contract for funding different kinds of initiatives
 * @notice This contract was built by project <Turtleneck> at ethDublin 2023.
 */
contract Campaign {

    MyERC1155 private erc1155Contract;

    struct Funder {
        uint256 donatedAmount;
        uint256 percentage;
    }

    struct CampaignInfo {
        uint256 fundingGoal;
        uint256 sharedReturnPercentage;
        string campaignName;
        uint256 startTime;
        uint256 fundingPeriodEndTime;
        uint256 campaignEndTime;
        uint256 campaignId;
        string nftMetadataIPFSHash;
        bool distributionLocked;
        bool nftMinted;
    }

    address public admin;
    CampaignInfo public campaign;
    mapping(address => Funder) public funders;
    address[] public fundersIndex;
    uint256 public fundersCount;
    uint256 public totalFundedAmount;
    uint256 public campaignCounter;

    constructor(
        uint256 _fundingGoal,
        uint256 _sharedReturnPercentage,
        string memory _campaignName,
        uint256 _fundingPeriodInSeconds,
        uint256 _campaignDurationInSeconds,
        uint256 _campaignId,
        string memory _nftMetadataIPFSHash,
        address campaignOwner
    ) {
        admin = campaignOwner;

        campaign = CampaignInfo({
            fundingGoal: _fundingGoal,
            sharedReturnPercentage: _sharedReturnPercentage,
            campaignName: _campaignName,
            startTime: block.timestamp,
            fundingPeriodEndTime: block.timestamp + _fundingPeriodInSeconds,
            campaignEndTime: block.timestamp + _campaignDurationInSeconds,
            campaignId: _campaignId,
            nftMetadataIPFSHash: _nftMetadataIPFSHash,
            distributionLocked: false,
            nftMinted: false
        });

        erc1155Contract = new MyERC1155(campaign.nftMetadataIPFSHash);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can perform this action.");
        _;
    }

    /**
     * @notice Fund the campaign by sending native currency
     * @notice fundingPercentage is set in units of %
     * @notice sharedReturn is set in units of %
     */
    function fund() public payable {
        require(msg.value > 0, "Funding amount must be greater than zero.");
        require(block.timestamp >= campaign.startTime && block.timestamp <= campaign.fundingPeriodEndTime, "Funding period has ended.");
        require(!campaign.distributionLocked, "Campaign distribution is locked. Cannot accept new funds.");

        uint256 currentDonationAmount = funders[msg.sender].donatedAmount;
        uint256 newDonationAmount = currentDonationAmount + msg.value;
        totalFundedAmount += msg.value;

        if (newDonationAmount > campaign.fundingGoal) {
            uint256 exceedingAmount = campaign.fundingGoal + msg.value - totalFundedAmount;
            newDonationAmount = newDonationAmount - exceedingAmount;
            totalFundedAmount -= exceedingAmount;
            (bool sent, ) = payable(msg.sender).call{value: exceedingAmount}("");
            require(sent, "Failed to send exceeding amount.");
        }

        uint256 fundingPercentage = (newDonationAmount * 100) / campaign.fundingGoal;

        funders[msg.sender].donatedAmount = newDonationAmount;
        funders[msg.sender].percentage = fundingPercentage;

        if (totalFundedAmount >= campaign.fundingGoal) {
            campaign.distributionLocked = true;
        }

        addFunder(msg.sender);

    }


    /**
     * @notice Function to add a new funder address to fundersIndex
     */
    function addFunder(address funderAddress) internal {
        if (funders[funderAddress].donatedAmount == 0) {
            fundersIndex.push(funderAddress);
            fundersCount++;
        }
    }


    /**
     * @notice Distribute the funds to the funders based on their percentages
     */
    function distribute() public {
        require(
            (!campaign.distributionLocked && block.timestamp > campaign.fundingPeriodEndTime) || block.timestamp > campaign.campaignEndTime,
            "Distribution is not yet available."
        );

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero.");

        if (!campaign.distributionLocked) {
            // Funding goal not reached, revert funded amounts
            for (uint256 i = 0; i < fundersCount; i++) {
                address funderAddress = fundersIndex[i];
                Funder storage funder = funders[funderAddress];
                (bool sent, ) = payable(funderAddress).call{value: funder.donatedAmount}("");
                require(sent, "Failed to send donated amount.");
                funder.donatedAmount = 0;
                funder.percentage = 0;
            }
        } else {
            if (campaign.sharedReturnPercentage != 0) {
                // Funding goal reached, distribute funds based on percentages
                for (uint256 i = 0; i < fundersCount; i++) {
                    address funderAddress = fundersIndex[i];
                    Funder storage funder = funders[funderAddress];
                    uint256 funderShare = (contractBalance * campaign.sharedReturnPercentage * funder.percentage) / 10000;
                    (bool sent, ) = payable(funderAddress).call{value: funderShare}("");
                    require(sent, "Failed to send funder share.");

                    if (!campaign.nftMinted) {
                        _mintNFT(funderAddress, campaign.campaignId, funder.donatedAmount);
                    }

                    funder.percentage = 0;
                    funder.donatedAmount = 0;
                }
            }
            campaign.nftMinted = true;
            (bool sentAdmin, ) = payable(admin).call{value: address(this).balance}("");
            require(sentAdmin, "Failed to send admin share.");
        }
    }


    function _mintNFT(address _recipient, uint256 _campaignId, uint256 _donatedAmount) internal {
        erc1155Contract.mint(_recipient, _campaignId, _donatedAmount);
    }


    function getNFTAddress() public view virtual returns (address) {
        return address(erc1155Contract);
    }


    /**
     * @notice Admin can claim the total funded amount
     */
    function claim() public onlyAdmin {
        require(campaign.distributionLocked && block.timestamp > campaign.fundingPeriodEndTime, "Funding goal not reached yet.");

        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Balance is zero.");

        (bool sent, ) = payable(msg.sender).call{value: contractBalance}("");
        require(sent, "Failed to send balance.");
    }
}
