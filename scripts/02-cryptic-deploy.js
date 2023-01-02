const my_ethers = require('ethers');

async function main() {

    // const [deployer] = await ethers.getSigners();
    const AtomAddress = "0x2eBD9a4E16b7dE2Af9cAC774D1E08087091093D2";
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