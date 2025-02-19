const  { ethers } = require("hardhat");

async function main() {
    const Voting = await ethers.getContractFactory("Voting");
    const voting = await Voting.deploy();

    await voting.waitForDeployment();
    const address = await voting.getAddress();
    console.log("Voting contract deployed to: ", address);
    // 0x5FbDB2315678afecb367f032d93F642f64180aa3
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});