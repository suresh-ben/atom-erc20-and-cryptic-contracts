const { ethers } = require("hardhat");
const my_ethers = require('ethers');

async function main() {

    // const [deployer] = await ethers.getSigners();
    const AtomContract = await ethers.getContractFactory("Atom");

    console.log("Deploying Atom contract...!!!");
    const instance = await AtomContract.deploy(my_ethers.utils.parseEther("0.1"));

    return instance;
}

main()
    .then((contract) => {
        console.log("Contract deployed successfully...!!!");
        console.log("contract deployed at address : " + contract.address);

        process.exit(0);
    })
    .catch((err) => {
        console.error("error with dploying contract...!!!");
        console.log(err);

        process.exit(1);
    })