const { ethers, upgrades } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Donation = await ethers.getContractFactory("CampaignFactory");
    const donor = await Donation.deploy("0x287d7FaA9Da37CB3E8F5B26B2F4318bAB0346060");
    
    console.log("Donation address:", donor.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });