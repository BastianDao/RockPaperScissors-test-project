// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract RockPaperScissors is ERC20 {
    address public blackHoleAddress = 0x0000000000000000000000000000000000000000;

    enum GameOption { Rock, Paper, Scissors, Invalid } 
    GameOption public choice;

    event gameResult(address _player, string _message);
    event gameInitiated(address _player, string _message);

    struct PlayerGame {
        address player;
        address opponent;
        GameOption playerGuess;
        uint wagerAmount;
        bool started;
        bool finished;
        bool victorious;
    }

    mapping(address => PlayerGame[]) public games;
    PlayerGame[] public playerGames;

    constructor() ERC20("Rochambeau", "RPS") {
        _mint(address(this), 10000);
    }
 
    function faucet() external {
      _mint(msg.sender, 100);
    }

    function initiateGame(uint _bet, uint _playerSelection, address _opponent) public payable {
        uint numberOfGames = games[msg.sender].length;
        uint indexOfArray = numberOfGames > 0 ? games[msg.sender].length - 1 : 0;

        require(numberOfGames == 0 || games[msg.sender][indexOfArray].started == false && games[msg.sender][indexOfArray].finished == false, "user is already playing a game");
        require(_playerSelection <= 2, "Invalid game move selection");

        _transfer(msg.sender, address(this), _bet);
        PlayerGame memory playerGame = PlayerGame(msg.sender, _opponent, playerSelection(_playerSelection), _bet, true, false, false);
        games[msg.sender].push(playerGame);
        playerGames.push(playerGame);
    }

    function playerSelection(uint _playerSelection) private pure returns (GameOption selectedOption_) {
        if (_playerSelection == 0) {
            selectedOption_ = GameOption.Rock;
        } else if ( _playerSelection == 1) {
            selectedOption_ = GameOption.Paper;
        } else if (_playerSelection == 2) {
            selectedOption_ = GameOption.Scissors;
        }
    }

    function joinAvailableGame(uint _gameToJoinIndex, uint _playerSelection) public payable {
        require(msg.value == playerGames[_gameToJoinIndex].wagerAmount, "Betting amounts do not match!");
        require(playerGames[_gameToJoinIndex].finished == false, "Game has already been played!");

        playerGames[_gameToJoinIndex].opponent = msg.sender;

        initiateGame(msg.value, _playerSelection, playerGames[_gameToJoinIndex].player);
        address winner = decideWinner(playerGames[_gameToJoinIndex].player, msg.sender);

        if (winner == blackHoleAddress) {
            emit gameResult(blackHoleAddress, "Game ended in a tie!");
            _transfer(address(this), playerGames[_gameToJoinIndex].player, playerGames[_gameToJoinIndex].wagerAmount);
            _transfer(address(this), playerGames[_gameToJoinIndex].opponent, playerGames[_gameToJoinIndex].wagerAmount);
        } else {
            _transfer(address(this), winner, playerGames[_gameToJoinIndex].wagerAmount*2);
            emit gameResult(winner, "Winner was decided!");
        }
    }

    function getAvailableGames() public view returns(PlayerGame[] memory playerGames_){
        return playerGames;
    }

    function decideWinner(address _player1, address _player2) private returns (address winner_) {
        require(games[_player1].length > 0 && games[_player2].length > 0, "One of the players isn't in a game");

        uint numberOfGamesForPlayer1 = games[_player1].length - 1;
        uint numberOfGamesForPlayer2 = games[_player2].length - 1;

        GameOption player1Guess = games[_player1][numberOfGamesForPlayer1].playerGuess;
        GameOption player2Guess = games[_player2][numberOfGamesForPlayer2].playerGuess;
        games[_player1][numberOfGamesForPlayer1].finished = true;
        games[_player2][numberOfGamesForPlayer2].finished = true;

        if (player1Guess == games[_player2][numberOfGamesForPlayer2].playerGuess) {
            winner_ = 0x0000000000000000000000000000000000000000;
        } else {
            if (player1Guess == GameOption.Rock ) {
                if (player2Guess == GameOption.Scissors) {
                    winner_ = _player1;
                } else {
                    winner_ = _player2;
                }
                
            } else if (player1Guess == GameOption.Scissors) {
                if (player2Guess == GameOption.Paper) {
                    winner_ = _player1;
                } else {
                    winner_ = _player2;
                }
            } else {
                if (player2Guess == GameOption.Rock) {
                    winner_ = _player1;
                } else {
                    winner_ = _player2;
                }
            }
        }
    }
}
