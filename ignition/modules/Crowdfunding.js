// ignition/modules/CrowdfundingModule.js
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("CrowdfundingModule", (m) => {
  // Deploy the Crowdfunding contract
  const crowdfunding = m.contract("Crowdfunding", [
    1000,             // _goal
    1736946000,       // _deadline (example: Unix timestamp)
    "Project X",      // _purpose
    120             // _votingDuration (1 day)
  ]);

  // Perform any post-deployment actions here (e.g., interact with contract)
  // Example: Creating a spending request (optional)
  //m.call(crowdfunding, "createSpendingRequest", ["Funds for Project X"]);

  return { crowdfunding };
});
