const my_ethers = require('ethers');

async function main() {

    // const [deployer] = await ethers.getSigners();
    const AtomAddress = "0x5fbdb2315678afecb367f032d93f642f64180aa3";
    const totalTickets = 100;
    const ticketPrice = 1;

    const CrypticContract = await ethers.getContractFactory("Cryptic");

    console.log("Deploying cryptic contract...!!!");
    const instance = await CrypticContract.deploy(AtomAddress, totalTickets, ticketPrice);

    return instance;
}

main()
    .then((contract) => {
        console.log("Contract deployed successfully...!!!");
        console.log("contract deployed at address : " + contract.address);

        process.exit(0);
    })
    .catch((err) => {
        console.error("error with deploying contract...!!!");
        console.log(err);

        process.exit(1);
    })