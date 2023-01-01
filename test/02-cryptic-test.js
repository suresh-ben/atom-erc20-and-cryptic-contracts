const { expect } = require('chai');
const my_ethers = require('ethers');

describe("Atom", () => {

    beforeEach(async() => {
        AtomContract = await ethers.getContractFactory("Atom");
        CrypticContract = await ethers.getContractFactory("Cryptic");

        [owner, user1, user2, ...users] = await ethers.getSigners();

        atomInstance = await AtomContract.deploy(my_ethers.utils.parseEther("0.1"));
        crypicInstance = await CrypticContract.deploy(atomInstance.address, 100, 1);
    });

    describe("Deploy test", () => {
        it("tests for deployment", async() => {
            console.log("Atom address : " + atomInstance.address);
            console.log("Cryptic address : " + crypicInstance.address);
        });
    });

});