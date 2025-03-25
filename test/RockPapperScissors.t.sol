// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {RockPapperScissors} from "../src/RockPapperScissors.sol";
import {DeployRockPapperScissors} from "../script/RockPapperScissors.s.sol";

contract TestRockPapperScissors is Test {
    RockPapperScissors public game;
    DeployRockPapperScissors public DeployGame;
    uint256 public constant BET_SIZE = 100;
    uint256 public constant PLAYERS_ETH = 1000;

    function setUp() public {
        DeployGame = new DeployRockPapperScissors();
        game = DeployGame.run();
    }

    function testInit() public {
        vm.prank(address(1));
        game.chooseYourAction(RockPapperScissors.Action.Scissors, "123");
        assertEq(game.lastWinner(), address(0));
        (
            address playerAddress,
            uint256 numberOfVictories,
            uint256 numberOfDefeats,
            uint256 numberOfEqualities,
            int256 score,
            uint256 ratio,
            RockPapperScissors.Action choice,
            bytes32 commit
        ) = game.listOfPlayers(0);
        assertEq(playerAddress, address(1));
        assertEq(numberOfVictories, 0);
        assertEq(numberOfDefeats, 0);
        assertEq(numberOfEqualities, 0);
        console.log("score = ", score);
        assertEq(ratio, 0);
    }

    function testDoubleInit() public {
        vm.prank(address(1));
        game.chooseYourAction(RockPapperScissors.Action.Papper, "123");
        vm.prank(address(2));
        game.chooseYourAction(RockPapperScissors.Action.Papper, "123");
        vm.prank(address(1));
        game.chooseYourAction(RockPapperScissors.Action.Papper, "123");
        assertEq(game.lastWinner(), address(0));
        (
            address player1Address,
            uint256 player1NumberOfVictories,
            uint256 player1NumberOfDefeats,
            uint256 player1NumberOfEqualities,
            int256 player1Score,
            uint256 player1Ratio,
            RockPapperScissors.Action choice,
            bytes32 player1commit
        ) = game.listOfPlayers(0);
        assertEq(player1Address, address(1));
        assertEq(player1NumberOfVictories, 0);
        assertEq(player1NumberOfDefeats, 0);
        assertEq(player1NumberOfEqualities, 1);
        console.log("player1Score score = ", player1Score);
        assertEq(player1Ratio, 0);
        (
            address player2Address,
            uint256 player2NumberOfVictories,
            uint256 player2NumberOfDefeats,
            uint256 player2NumberOfEqualities,
            int256 player2Score,
            uint256 player2Ratio,
            RockPapperScissors.Action player2Choice,
            bytes32 player2commit
        ) = game.listOfPlayers(1);
        assertEq(player2Address, address(2));
        assertEq(player2NumberOfVictories, 0);
        assertEq(player2NumberOfDefeats, 0);
        assertEq(player2NumberOfEqualities, 1);
        console.log("player2Score score = ", player2Score);
        assertEq(player2Ratio, 0);
    }

    function test2Matches() public {
        DetermineLastWinner(
            RockPapperScissors.Action.Papper,
            RockPapperScissors.Action.Rock
        );
        assertEq(game.lastWinner(), address(1));

        DetermineLastWinner(
            RockPapperScissors.Action.Scissors,
            RockPapperScissors.Action.Rock
        );
        assertEq(game.lastWinner(), address(2));
    }

    function DetermineLastWinner(
        RockPapperScissors.Action player1Action,
        RockPapperScissors.Action player2Action
    ) public {
        vm.prank(address(1));
        vm.deal(address(1), PLAYERS_ETH);
        game.chooseYourAction{value: BET_SIZE}(player1Action, "123");
        vm.prank(address(2));
        vm.deal(address(2), PLAYERS_ETH);
        game.chooseYourAction{value: BET_SIZE}(player2Action, "123");
        vm.prank(address(1));
        game.chooseYourAction(player1Action, "123");
        console.log("house balance :");
        console.log(game.houseBalance());
    }

    function testRevertIfSameAddress() public {
        vm.prank(address(1));
        game.chooseYourAction(RockPapperScissors.Action.Papper, "123");
        vm.prank(address(1));
        vm.expectRevert();
        game.chooseYourAction(RockPapperScissors.Action.Papper, "123");
    }

    function testNoWinner() public {
        console.log(game.lastWinner());
        assertEq(game.lastWinner(), address(0));
    }

    function testWithdrawFees() public {
        DetermineLastWinner(
            RockPapperScissors.Action.Rock,
            RockPapperScissors.Action.Rock
        );
        assertEq(game.houseBalance(), 10);
    }

    function testResetPhase1() public {
        vm.prank(address(1));
        vm.deal(address(1), PLAYERS_ETH);
        game.chooseYourAction{value: BET_SIZE}(
            RockPapperScissors.Action.Papper,
            "123"
        );
        game.reset();
        assertEq(
            uint8(game.actualState()),
            uint8(RockPapperScissors.State.FIRST)
        );
        assertEq(game.player1Address(), address(0));
        assertEq(game.player2Address(), address(0));
        assertEq(game.bet1(), 0);
        assertEq(game.bet2(), 0);
    }

    function testResetPhase2() public {
        vm.prank(address(1));
        vm.deal(address(1), PLAYERS_ETH);
        game.chooseYourAction{value: BET_SIZE}(
            RockPapperScissors.Action.Papper,
            "123"
        );
        vm.prank(address(2));
        vm.deal(address(2), PLAYERS_ETH);
        game.chooseYourAction{value: BET_SIZE}(
            RockPapperScissors.Action.Papper,
            "123"
        );
        game.reset();
        assertEq(
            uint8(game.actualState()),
            uint8(RockPapperScissors.State.FIRST)
        );
        assertEq(game.player1Address(), address(0));
        assertEq(game.player2Address(), address(0));
        assertEq(game.bet1(), 0);
        assertEq(game.bet2(), 0);
    }
}
