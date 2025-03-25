// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {console} from "../lib/forge-std/src/Test.sol";

error RockPapperScissors__InvalidChoice();
error RockPapperScissors__InvalidUser();
error RockPapperScissors__InsuficientFund();
error RockPapperScissors__EthTransferFailed();
error RockPapperScissors__OnlyOwner();
error RockPapperScissors__DebugError();
error RockPapperScissors__InvalidHash();

contract RockPapperScissors {
    enum Action {
        Rock,
        Papper,
        Scissors
    }
    enum State {
        FIRST,
        SECOND,
        THIRD
    }
    struct Player {
        address playerAddress;
        uint256 numberOfVictories;
        uint256 numberOfDefeats;
        uint256 numberOfEqualities;
        int256 score;
        uint256 ratio;
        Action choice;
        bytes32 commit;
    }
    Player[] public listOfPlayers;
    address public player1Address;
    address public player2Address;
    address public owner;
    address public lastWinner;
    State public actualState = State.FIRST;
    uint256 public houseBalance;
    uint256 public bet1;
    uint256 public bet2;
    mapping(address => bool) isInListOfPlayers;
    mapping(address => uint) placeOfPlayer;

    /*
    uint bet;
    struct player {
        Action public playerMove;
        uint public bet;
        address public playerAddress;
    }
    */
    constructor() {
        owner = msg.sender;
    }

    function determineLastWinner(
        Player storage player1,
        Player storage player2,
        uint256 bet
    ) private returns (address) {
        uint256 totalPot = bet * 2;
        console.log(totalPot);
        uint256 fee = (totalPot * 5) / 100;
        console.log(fee);
        uint payout = totalPot - fee;
        console.log(payout);
        if (player1.choice == player2.choice) {
            player1.numberOfEqualities += 1;
            player2.numberOfEqualities += 1;
            uint256 drawnRefund = (bet * 95) / 100;
            houseBalance += (bet * 2) - (drawnRefund * 2);
            payDay(player1Address, drawnRefund);
            payDay(player2Address, drawnRefund);
            lastWinner = address(0);
        } else if (
            (player1.choice == Action.Rock &&
                player2.choice == Action.Scissors) ||
            (player1.choice == Action.Papper &&
                player2.choice == Action.Rock) ||
            (player1.choice == Action.Scissors &&
                player2.choice == Action.Papper)
        ) {
            player1.numberOfVictories += 1;
            player2.numberOfDefeats += 1;
            player1.score += int256(payout);
            player2.score -= int256(payout);
            payDay(player1Address, payout);
            houseBalance += fee;
            lastWinner = (player1Address);
        } else {
            player1.numberOfDefeats += 1;
            player2.numberOfVictories += 1;
            player1.score -= int256(payout);
            player2.score += int256(payout);
            payDay(player2Address, payout);
            houseBalance += fee;
            lastWinner = (player2Address);
        }

        player1.ratio =
            (player1.numberOfVictories * 100) /
            (player1.numberOfVictories +
                player1.numberOfDefeats +
                player1.numberOfEqualities);
        player2.ratio =
            (player2.numberOfVictories * 100) /
            (player2.numberOfVictories +
                player2.numberOfDefeats +
                player2.numberOfEqualities);
        bet1 = 0;
        bet2 = 0;
        return (lastWinner);
    }

    function reset() public {
        actualState = State.FIRST;
        payDay(player1Address, bet1);
        payDay(player2Address, bet2);
        player1Address = address(0);
        player2Address = address(0);
        bet1 = 0;
        bet2 = 0;
    }
    function chooseYourAction(
        Action _choice,
        string memory _secret
    ) public payable checkChoiceValidity(_choice) addPlayer(_choice, _secret) {
        if (actualState == State.FIRST) {
            actualState = State.SECOND;
            player1Address = msg.sender;
            Player storage player1 = listOfPlayers[
                placeOfPlayer[player1Address]
            ];
            player1.commit = getCommitHash(_choice, _secret);
            bet1 = msg.value;
        } else if (actualState == State.SECOND) {
            if (msg.sender == player1Address) {
                revert RockPapperScissors__InvalidUser();
            }
            player2Address = msg.sender;
            Player storage player2 = listOfPlayers[
                placeOfPlayer[player2Address]
            ];
            player2.choice = _choice;
            bet2 = msg.value;
            actualState = State.THIRD;
        } else if (actualState == State.THIRD) {
            if (msg.sender != player1Address) {
                revert RockPapperScissors__InvalidUser();
            }
            Player storage player1 = listOfPlayers[
                placeOfPlayer[player1Address]
            ];
            Player storage player2 = listOfPlayers[
                placeOfPlayer[player2Address]
            ];
            if (!reveal(_choice, _secret, player1.commit)) {
                revert RockPapperScissors__InvalidHash();
            }
            player1.choice = _choice;
            uint256 bet = handleBet(bet1, bet2);
            actualState = State.FIRST;
            determineLastWinner(player1, player2, bet);
        } else {
            revert RockPapperScissors__DebugError();
        }
    }

    function reveal(
        Action choice,
        string memory secret,
        bytes32 _commit
    ) public returns (bool) {
        return (keccak256(abi.encodePacked(choice, secret)) == _commit);
    }

    function payDay(address playerToPay, uint256 value) public {
        (bool sent, ) = payable(playerToPay).call{value: value}("");
        if (!sent) {
            revert RockPapperScissors__EthTransferFailed();
        }
    }

    function handleBet(uint256 _bet1, uint256 _bet2) public returns (uint) {
        if (_bet1 > _bet2) {
            payDay(player1Address, _bet1 - _bet2);
            return (_bet2);
        } else {
            payDay(player2Address, _bet2 - _bet1);
            return (_bet1);
        }
    }

    /*
    modifier checkBetSize(uint256 _bet) {
        if (msg.sender.balance < _bet) {
            revert RockPapperScissors__InsuficientFund();
        }
        _;
    }
    */
    modifier addPlayer(Action _choice, string memory _secret) {
        if (!isInListOfPlayers[msg.sender]) {
            listOfPlayers.push(
                Player(
                    msg.sender,
                    0,
                    0,
                    0,
                    0,
                    0,
                    RockPapperScissors.Action.Rock,
                    getCommitHash(_choice, _secret)
                )
            );
            isInListOfPlayers[msg.sender] = true;
            placeOfPlayer[msg.sender] = listOfPlayers.length - 1;
        }
        _;
    }

    modifier checkChoiceValidity(Action choice) {
        if (uint256(choice) > 2) {
            revert RockPapperScissors__InvalidChoice();
        }
        _;
    }

    function getPlayerStats(
        address player
    )
        external
        view
        returns (
            address playerAddress,
            uint256 wins,
            uint256 defeats,
            uint256 draws,
            int256 score,
            uint256 ratio,
            uint8 choice
        )
    {
        if (!isInListOfPlayers[player]) {
            revert RockPapperScissors__InvalidUser();
        }
        uint index = placeOfPlayer[player];
        Player memory p = listOfPlayers[index];
        return (
            p.playerAddress,
            p.numberOfVictories,
            p.numberOfDefeats,
            p.numberOfEqualities,
            p.score,
            p.ratio,
            uint8(p.choice)
        );
    }

    function getCommitHash(
        Action choice,
        string memory secret
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(choice, secret));
    }

    function withdrawFees() external {
        if (msg.sender != owner) {
            revert RockPapperScissors__OnlyOwner();
        }
        uint amount = houseBalance;
        houseBalance = 0;
        payDay(owner, amount);
    }
    receive() external payable {}
    fallback() external payable {}
}
