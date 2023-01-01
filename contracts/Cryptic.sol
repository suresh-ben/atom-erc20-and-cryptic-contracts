// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Atom.sol";

error AllTicketsSold();
error ExceedingMaxTickets(uint maxTixkets, uint availableTickets, uint orderedTickets);
error NotAllowedToBuyTicketsPleaseAllowMeToUseAtoms(uint atomsNeededToBuy, uint AllowedAtoms);
error NotEnoughFunds(uint playerBalance, uint requiredElectrons);
error YouAreNotOwner();
error NotAllTicketsAreSold(uint totalTickets, uint ticketsSold);

/**
 * @title Cryptic Smart contract
 * @author Suresh Bennabatthula
 * @notice 
 * This contract provides users ability to buy tickets,
 * each ticket cost 1Atom (ERC20 token).
 * This contract can sell 100 tickets,
 * Once all tickets get sold, one of the ticket will be choosen at random and 
 * the owner of the winning ticket will rewarded with 95 atoms and
 * 5 atoms will be given to the owner of the contract as royality fee.
 * 
 * once the price is given to the winner the contract will gets reset
 * i.e. ready for another lottery, for players to buy another 100 tickets
 */

contract Cryptic {

    /**
     * @dev we need to interact with atom contract to buy tickets for user
     */

    //immutables
    Atom immutable atomContract;
    address immutable owner;
    uint immutable totalTicekts;
    uint immutable ticketPrice;

    //currentTicket keeps track of the cureent ticket number
    uint currentTicket;

    /**
     * @dev ticket price need to be set in atoms
     * 1 atom = 1000 electrons
     */
    constructor(address _contractAddress, uint _totalTicekts, uint _ticketPrice) {
        atomContract = Atom(_contractAddress);
        owner = msg.sender;
        totalTicekts = _totalTicekts;
        ticketPrice = _ticketPrice;

        currentTicket = 1;
    }

    //view functions -- returns the data about this contract
    function GetOwner() external view returns(address) { return owner; }
    function GetPrice() external view returns(uint) { return ticketPrice; }     //returns in atoms
    function GetTotalTickets() external view returns(uint) { return totalTicekts; }
    function TicketsSold() external view returns(uint) { return currentTicket- 1; }
    function GetAtom() external view returns(address) { return address(atomContract); }

    //contract variables

    //this structure tells wether the player is alreaady player or not while intersing a player into lottery and maintains tickets 
    struct PlayerDetails {
        bool isPlayer;
        uint[] tickets;
    }
    mapping( address => PlayerDetails ) ticketSheet;        //map of players and their detils

    address[] players;                                      //array to track all the player addresses and to iterate
    address[] winners;                                      //All the Winners of this lottery from the deployment

    function GetPlayersCount() public view returns(uint) { return players.length; }
    function GetWinners() public view returns(address[] memory) { return winners; }

    //Events
    event AllTicketsAreSold();
    event TicketSold(address player, uint ticketId);
    event NewWinnerAnnounced(address winner);

    function BuyTickets(uint16 _tickets) external {
        if(currentTicket > totalTicekts) revert AllTicketsSold();
        if((currentTicket-1) + _tickets > totalTicekts) revert ExceedingMaxTickets(totalTicekts, totalTicekts - currentTicket + 1, _tickets);

        uint allowedElectrons = atomContract.allowance(msg.sender, address(this));
        uint requiredElectrons = (_tickets * ticketPrice) * 1000;

        if( allowedElectrons < requiredElectrons ) 
            revert NotAllowedToBuyTicketsPleaseAllowMeToUseAtoms(_tickets*ticketPrice, (requiredElectrons / 1000));

        uint playerBalance = atomContract.balanceOf(msg.sender);

        if(playerBalance < requiredElectrons)
            revert NotEnoughFunds(playerBalance, requiredElectrons);

        //insert player
        if(!ticketSheet[msg.sender].isPlayer){
            players.push(msg.sender);
            ticketSheet[msg.sender].isPlayer = true;
        }

        for(uint8 i = 0; i < _tickets; i++)
            BuyTicket();
    }

    //This function buys a single ticket for player
    /**
     * @dev user can only buy tickets, if he approved this contract to use his atoms
     * this will be managed in front end
     * 
     * if a user wants to manually buy tickets
     * - He needs to approve cryptic by x atoms
     * - Then he needs call buyTickets method to buy x tickets
     */
    function BuyTicket() private {
        if(currentTicket > totalTicekts) revert AllTicketsSold();

        atomContract.transferFrom(msg.sender, address(this), ticketPrice * 1000 );    //1000 electrons = 1 atom -- doing this here will cost gas same amount for each tickect

        ticketSheet[msg.sender].tickets.push(currentTicket);
        emit TicketSold(msg.sender, currentTicket);

        currentTicket++;

        if( currentTicket > totalTicekts ) 
            emit AllTicketsAreSold();
    }

    modifier OwnerOnly() {
        if( msg.sender != owner ) revert YouAreNotOwner();
        _;
    }

    // award the winner
    /**
     * @dev Once all tickets are sold owner can cativate this function to randamly choose a winner and award him with 95
     */

    /**
     * @dev 
     * award Calculations
     * winnerAward : 
     *  toatlPrice = (totalTickets*ticketPrice) in atoms
     *  winnerPrice is 95% ==> (totalPrice*95)/100 
     *  conversion to electrons multiply by 1000
     *  ==> winnerAward = totalTickets*ticketPrice * 1000 * 95 /100
     *  ==> winnerAward = totalTickets * ticketPrice * 950
     * award winner will cost much gas => returns on this lottery are much than the gas, so owner will be happy (lol)
     */
    function AwardWinner() external OwnerOnly {
        if(currentTicket <= totalTicekts) revert NotAllTicketsAreSold(totalTicekts, currentTicket - 1);

        uint winningTicket = GetRandomNumber(totalTicekts);
        address winner = ChooseWinner(winningTicket);
        
        uint winnerAward = totalTicekts * ticketPrice * 950;
        uint ownerAward = totalTicekts * ticketPrice * 50;

        atomContract.transfer( winner, winnerAward );
        atomContract.transfer( owner, ownerAward );

        winners.push(winner);
        emit NewWinnerAnnounced(winner);
        ResetCryptic();
    }

    /**
     * @dev This function gives random number between [1, range]
     * including 1 and including range
     * i.e. 1 to range
     */
    function GetRandomNumber(uint range) view private returns(uint) {
        return ( uint256( keccak256( abi.encodePacked( block.timestamp, block.difficulty, msg.sender))) % range ) + 1;
    }

    function ChooseWinner(uint winningTicket) private view returns(address) {
        address winner = address(0);

        for(uint i = 0; i < players.length; i++)
        {
            address player = players[i];
            uint[] storage playerTickets = ticketSheet[player].tickets;
            
            for(uint j = 0; j < playerTickets.length; j++) 
            {
                if(playerTickets[j] == winningTicket) {
                    winner = player;
                    break;
                }
            }

            if(winner != address(0))
                break;
        }

        if(winner == address(0))
            return players[winningTicket / players.length];

        return winner;
    }

    //This function resets the lottery game
    function ResetCryptic() private {
        for(uint i = 0; i < players.length; i++)
        {
            address player = players[i];

            ticketSheet[player].isPlayer = false;
            delete ticketSheet[player].tickets;
        }

        delete players;
        currentTicket = 1;
    }

}