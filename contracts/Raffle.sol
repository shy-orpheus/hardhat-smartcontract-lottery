//SPDX-Licence-Identifier: MIT

//Raffle/Lottery
//enter the lottery
//pick a random winner
//winner to be selected every x minutes -> completely automated
//chainlink oracle -> randomness, automated exectution (chainlink keeper)

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

/**@title A sample Raffle Contract
 * @author Yash Mittal
 * @notice This contract is for creating a sample raffle contract
 * @dev This implements the Chainlink VRF Version 2 and Chainlink keepers
 */

contract Raffle is VRFConsumerBaseV2,AutomationCompatibleInterface {
    /*Type Declarations*/
    enum RaffleState {
        OPEN,
        CALCULATING
    } // ACTUALLY creating a uint256 where 0 => open, 1 => calculating
    /* State variables */
    uint256 private immutable i_entranceFee;
    address payable[] private s_players; //if one of them wins we'll need to pay them  //its in storage ofc bc we'll need to modify the array a lot
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator; // cause we are only setting this value once in constructor
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    // Lottery Variables
    address private s_recentWinner;
    //uint256 private s_isOpen; // to create states like: is pending, open, closed, calulating but can be tricky to implement so we use enum
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    /* Functions */
    constructor(
        address vrfCoordinatorV2,   // this is a contract, will need to make some mocks for this later
        uint64 subscriptionId,
        bytes32 gasLane,
        uint256 interval,
        uint256 entranceFee,
        uint32 callbackGasLimit
        
    ) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN; //LOTTERY is in open state
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        // require (msg.value > i_entrancdFee, "Not enough ETH!")   // not gass efficient   WE ARE STORING THE WHOLE STRING
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETHEntered();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }

        s_players.push(payable(msg.sender)); //msg.msg.sender is not payable so typecast it
        //name events with the  function name reversed
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev This is the function that the chainlink keeper nodes call
     * they look fo rth e`upkeepNeeded` toreturn true
     * the following shld be true to return true
     * 1. our time interval shld have passed
     * 2. lottery shld have atleast one player and some eth
     * 3. our subscription needs to be funded with link
     * 4. the lottery shld be in "open" state.
     */
    function checkUpkeep(
        bytes memory /*checkData*/ /* we are keeping it simple and not using this for now */
    ) public view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        //block.timestamp --> to add a time interval to our code
        // we need (block.timestamp - last block.timestamp) > interval (in seconds)
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(
        /*requestRandomWinner*/ bytes calldata /*performData*/
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        //updating state when we are calculating so other ppl cant jump in the raffle
        s_raffleState = RaffleState.CALCULATING;

        //request the random number
        //once we get it, do smthng with it
        //2 transaction process
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //gaslane or keyHash
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/, // because we were getting a yellow wavy line here, it was unused anyway, so we commented it out
        uint256[] memory randomWords
    ) internal override {
        // the requestId will return a 256 bit absolutley massive random number
        // in our example we will only get one random number bec we have only equested one
        // we use the modulo function to use this random number to select
        // random player from the s_players array
        // random number (modulo) size of players array => returns a random player from the array

        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        //UPDATING raffle state after we have picked our randim winner
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp; //resetting timestamp
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        // require(success)
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }

    /* view / pure functions */
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner; // returning our last recent winner of the lottery
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return 1;
    }
    function getNumberOfPlayers() public view  returns (uint256) {
        return s_players.length;
    }
    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;

    }
    function getRequestConfirmations() public pure returns(uint256){
        return  REQUEST_CONFIRMATIONS;
    }
    function getInterval() public view returns (uint256) {
        return i_interval;
    }
}
