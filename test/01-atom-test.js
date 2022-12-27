const { expect } = require('chai');
const my_ethers = require('ethers');

describe("Atom", () => {

    beforeEach(async () => {
        AtomContract = await ethers.getContractFactory("Atom");
        [owner, user1, user2, ...users] = await ethers.getSigners();
        instance = await AtomContract.deploy(my_ethers.utils.parseEther("0.1"));
    });

    describe("Deployment test for atom contract", () => {
        it("testing electron Balance", async () =>{

            console.log("contract address : " + instance.address);

            let electronPrice = await instance.electronPrice();
            let atomPrice = await instance.atomPrice();

            expect(electronPrice).to.equal(my_ethers.utils.parseEther("0.1")/1000);
            expect(atomPrice).to.equal(my_ethers.utils.parseEther("0.1"));

        });

        it("checking total supply" , async () => {
            let supply = await instance.totalSupply(); 
            let conv = await instance.decimals();

            supply = supply / Math.pow(10, conv); //converting to atoms

            expect(conv).to.equal(3);
            expect(supply).to.equal(10000);
        });

        it("cheching name and symbol", async () => {
            let name = await instance.name();
            let symbol = await instance.symbol();

            expect(name).to.equal("Atom");
            expect(symbol).to.equal("AM");
        })
    });

    describe("Running tests for Minting", () => {
        it("checking balance befor minting", async () => {
            let balance = await instance.balanceOf(owner.address);
            expect(balance).to.equal(0);
            balance = await instance.balanceOf(user1.address);
            expect(balance).to.equal(0);
        });

        it("Checking mined atoms befor minting", async () => {
            let electrons = await  instance.MinedElectrons();
            let conv = await instance.decimals();

            let atom = electrons / Math.pow(10, conv);
            expect(atom).to.equal(0);
        });

        it("Mining test", async () => {
            await instance.mintAtoms({value : my_ethers.utils.parseEther("5.0123")});
            
            let electrons = await  instance.MinedElectrons();
            let conv = await instance.decimals();
            let atom = electrons / Math.pow(10, conv);

            expect(atom).to.equal(50.123);
            expect(electrons).to.equal(50.123 * 1000);
        });
    });

    describe("working of contract", () => {
        it("checking transfer of atoms", async () => {
            await instance.mintAtoms({value : my_ethers.utils.parseEther("1")});

            let balance = await instance.balanceOf(owner.address);
            expect(balance).to.equal(10*1000);

            await instance.transfer(user1.address, 2500);

            balance = await instance.balanceOf(owner.address);
            expect(balance).to.equal(10*1000 - 2500);

            balance = await instance.balanceOf(user1.address);
            expect(balance).to.equal(2500);
        })
    });

    describe("testing for allowance", () => {
        it("testing approve", async () => {
            await instance.approve(user1.address, 5000);

            let approvedAmount = await instance.allowance(owner.address, user1.address);
            expect(approvedAmount).to.equal(5000);
        });

        it("testing allowed transactions", async () => {
            await instance.mintAtoms({value : my_ethers.utils.parseEther("5")});

            await instance.approve(user1.address, 5000);
            await instance.connect(user1).transferFrom(owner.address, user2.address, 2500);

            let balance = await instance.balanceOf(owner.address);
            expect(balance).to.equal(50*1000 - 2500);

            balance = await instance.balanceOf(user1.address);
            expect(balance).to.equal(0);

            balance = await instance.balanceOf(user2.address);
            expect(balance).to.equal(2500);


            let allowedElectrons = await instance.allowance(owner.address, user1.address);
            expect(allowedElectrons).to.equal(2500);
        });
    });

    describe("Buring test", () => {
        it("burning atoms", async () => {
            await instance.mintAtoms({value : my_ethers.utils.parseEther("5")});
            await instance.burnElectrons(20 * 1000);

            let balance = await instance.balanceOf(owner.address);
            expect(balance).to.equal(30 * 1000);
        });

        it("buring atoms for ETH", async () => {

            let balance = await user2.getBalance();
            balance = my_ethers.utils.formatEther(balance);
            console.log("Befor transaction : " + balance);

            await instance.connect(user2).mintAtoms({value : my_ethers.utils.parseEther("5")});

            balance = await user2.getBalance();
            balance = my_ethers.utils.formatEther(balance);
            console.log("After transaction : " + balance);

            await instance.connect(user2).burnElectrons(25 * 1000);

            balance = await user2.getBalance();
            balance = my_ethers.utils.formatEther(balance);
            console.log("After Burning atoms : " + balance);
        });
    });

});
