// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Atom.sol";

error AllTicketsSold();
error ExceedingMaxTickets(uint16 maxTixkets, uint16 availableTickets, uint16 orderedTickets);
error NotAllowedToBuyTicketsPleaseAllowMeToUseAtoms(uint16 orderdTickets, uint AllowedAtoms);
error YouAreNotOwner();
error NotAllTicketsAreSold(uint16 totalTickets, uint16 ticketsSold);

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
    uint16 immutable totalTicekts;
    uint8 immutable ticketPrice;

    //currentTicket keeps track of the cureent ticket number
    uint16 currentTicket;

    /**
     * @dev ticket price need to be set in electrons
     * 1 atom = 1000 electrons
     */
    constructor(address _contractAddress, uint16 _totalTicekts, uint8 _ticketPrice) {
        atomContract = Atom(_contractAddress);
        owner = msg.sender;
        totalTicekts = _totalTicekts;
        ticketPrice = _ticketPrice;

        currentTicket = 1;
    }

    //view functions -- returns the data about this contract
    function GetOwner() external view returns(address) { return owner; }
    function GetPrice() external view returns(uint) { return ticketPrice; }
    function GetTotalTickets() external view returns(uint) { return totalTicekts; }
    function TicketsSold() external view returns(uint) {return currentTicket- 1; }


    //contract variables

    //this structure tells wether the player is alreaady player or not while intersing a player into lottery and maintains tickets 
    struct PlayerDetails {
        bool isPlayer;
        uint[] tickets;
    }
    mapping( address => PlayerDetails ) ticketSheet;        //map of players and their detils

    address[] players;                                      //array to track all the player addresses and to iterate
    address[] winners;                                      //All the Winners of this lottery from the deployment


    //Events
    event AllTicketsAreSold();

    function BuyTickets(uint16 _tickets) external {
        if(currentTicket > totalTicekts) revert AllTicketsSold();
        if(currentTicket + _tickets > totalTicekts) revert ExceedingMaxTickets(totalTicekts, totalTicekts - currentTicket + 1, _tickets);

        uint allowedAtoms = atomContract.allowance(msg.sender, address(this));
        if( allowedAtoms < _tickets) 
            revert NotAllowedToBuyTicketsPleaseAllowMeToUseAtoms(_tickets, allowedAtoms);

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

        atomContract.transferFrom(msg.sender, address(this), 1000 );    //1000 electrons = 1 atom -- doing this here will cost gas same amount for each tickect
        ticketSheet[msg.sender].tickets.push(currentTicket);
        currentTicket++;

        if( currentTicket > totalTicekts ) 
            emit AllTicketsAreSold();
    }

    modifier OwnerOnly() {
        if( msg.sender != owner ) revert YouAreNotOwner();
        _;
    }

    // award the winner
    function AwardWinner() external OwnerOnly {
        if(currentTicket <= totalTicekts) revert NotAllTicketsAreSold(totalTicekts, currentTicket - 1);

        uint winningTicket = GetRandomNumber(totalTicekts);
        address winner = ChooseWinner(winningTicket);
        
        atomContract.transfer( winner, 95*1000 );
        atomContract.transfer( owner, 5*1000 );

        winners.push(winner);
        ResetCryptic();
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

    /**
     * @dev This function gives random number between [1, range]
     * including 1 and including range
     * i.e. 1 to range
     */
    function GetRandomNumber(uint16 range) view private returns(uint) {
        return ( uint256( keccak256( abi.encodePacked( block.timestamp, block.difficulty, msg.sender))) % range ) + 1;
    }

}