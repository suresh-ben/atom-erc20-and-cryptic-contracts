const { expect } = require('chai');
const my_ethers = require('ethers');

describe("Cryptic", () => {

    beforeEach(async() => {
        AtomContract = await ethers.getContractFactory("Atom");
        CrypticContract = await ethers.getContractFactory("Cryptic");

        [owner, user1, user2, user3, ...users] = await ethers.getSigners();

        atomInstance = await AtomContract.deploy(my_ethers.utils.parseEther("0.1"));

        //For testing -- using 10tickets 
        crypicInstance = await CrypticContract.deploy(atomInstance.address, 10, 1);
    });

    describe("Deploy tests", () => {
        it("contructor variables test", async() => {
            let myAtom = await crypicInstance.GetAtom();
            let totalTickets = await crypicInstance.GetTotalTickets();
            let ticketPrice = await crypicInstance.GetPrice();
            let ticketsSold = await crypicInstance.TicketsSold();

            expect(myAtom).to.equal(atomInstance.address);
            expect(totalTickets).to.equal(10);
            expect(ticketPrice).to.equal(1);
            expect(ticketsSold).to.equal(0);
        });

        it("Game variables test", async() => {
            let playerCount = await crypicInstance.GetPlayersCount();
            let winners = await crypicInstance.GetWinners();

            expect(playerCount).to.equal(0);
            expect(winners).to.eql([]);
        });
    });

    describe("Buy tests", () => {
        it("Approve test for Atom contract", async () => {
            await atomInstance.connect(user1).mintAtoms({ value : my_ethers.utils.parseEther("1") });
            await atomInstance.connect(user1).approve(crypicInstance.address, 5 * 1000);

            let user1Balance = await atomInstance.balanceOf(user1.address);
            let approvedElectrons = await atomInstance.allowance(user1.address, crypicInstance.address);

            expect(user1Balance).to.equal(10 * 1000);
            expect(approvedElectrons).to.equal(5 * 1000);
        });

        it("Buy test from crytic conract", async () => {
            await atomInstance.connect(user1).mintAtoms({ value : my_ethers.utils.parseEther("1") });
            await atomInstance.connect(user1).approve(crypicInstance.address, 5 * 1000);

            await crypicInstance.connect(user1).BuyTickets(5);

            let playersCount = await crypicInstance.GetPlayersCount();
            let ticketsSold = await crypicInstance.TicketsSold();

            expect(playersCount).to.equal(1);
            expect(ticketsSold).to.equal(5);
        });

        it("Buying error test from crytic conract", async () => {
            await atomInstance.connect(user1).approve(crypicInstance.address, 4 * 1000);
            await expect(crypicInstance.connect(user1).BuyTickets(5)).to.be.revertedWith('NotAllowedToBuyTicketsPleaseAllowMeToUseAtoms');

            await atomInstance.connect(user1).approve(crypicInstance.address, 1 * 1000);
            await expect(crypicInstance.connect(user1).BuyTickets(5)).to.be.revertedWith('NotEnoughFunds');

            await atomInstance.connect(user1).mintAtoms({ value : my_ethers.utils.parseEther("1") });
            await atomInstance.connect(user2).mintAtoms({ value : my_ethers.utils.parseEther("1") });
            await atomInstance.connect(user2).approve(crypicInstance.address, 6 * 1000);

            await crypicInstance.connect(user1).BuyTickets(5);
            await expect(crypicInstance.connect(user2).BuyTickets(6)).to.be.revertedWith('ExceedingMaxTickets');
            await expect(crypicInstance.connect(user2).BuyTickets(5)).to.emit(crypicInstance, 'AllTicketsAreSold');

            let ticketsSold = await crypicInstance.TicketsSold();
            expect(ticketsSold).to.equal(10);

            await expect(crypicInstance.connect(user2).BuyTickets(1)).to.be.revertedWith('AllTicketsSold');
        });

    });

    describe("winner tests", () => {
        it("awarding test", async () => {
            await atomInstance.connect(user1).mintAtoms({ value : my_ethers.utils.parseEther("0.3") });
            await atomInstance.connect(user2).mintAtoms({ value : my_ethers.utils.parseEther("0.3") });
            await atomInstance.connect(user3).mintAtoms({ value : my_ethers.utils.parseEther("0.4") });

            await atomInstance.connect(user1).approve(crypicInstance.address, 3 * 1000);
            await atomInstance.connect(user2).approve(crypicInstance.address, 3 * 1000);
            await atomInstance.connect(user3).approve(crypicInstance.address, 4 * 1000);

            await crypicInstance.connect(user1).BuyTickets(3);
            await crypicInstance.connect(user2).BuyTickets(3);
            await crypicInstance.connect(user3).BuyTickets(4);

            let user1Balance = await atomInstance.balanceOf(user1.address);
            let user2Balance = await atomInstance.balanceOf(user2.address);
            let user3Balance = await atomInstance.balanceOf(user3.address);
            expect(user1Balance).to.equal(0);
            expect(user2Balance).to.equal(0);
            expect(user3Balance).to.equal(0);

            await expect(crypicInstance.AwardWinner()).to.emit(crypicInstance, 'NewWinnerAnnounced');

            let winners = await crypicInstance.GetWinners();
            expect(winners).to.not.eql([]);

            let winnerBalance = await atomInstance.balanceOf(winners[0]);
            expect(winnerBalance).to.equal( 10 * 950 )
        });
    });

});