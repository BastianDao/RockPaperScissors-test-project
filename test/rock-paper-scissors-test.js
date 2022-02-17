const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("RockPaperScissors", function () {
  let gasContract;
  let owner, addr1, addr2, addr3;

  beforeEach(async function() {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
  
    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");

    rockPaperScissorsContract = await RockPaperScissors.deploy();
    await rockPaperScissorsContract.deployed();
  });

  describe('initial contract state', () => {
    it('minted 10000 tokens to the contract', async function() {
      let contractTokens = await rockPaperScissorsContract.balanceOf(rockPaperScissorsContract.address);
      expect(contractTokens).to.equal(10000);
    })
  });

  describe('faucet', () => {
    it('allows a user to add tokens to their balances', async function() {
      let addToBalance = await rockPaperScissorsContract.connect(addr1).faucet()

      let acc1Balance = await rockPaperScissorsContract.balanceOf(addr1.address);
      expect(acc1Balance).to.equal(100);
    });
  });

  describe('initiateGame', () => {
    it("succeeds when given correct variables", async function() {
      let addToBalance = await rockPaperScissorsContract.connect(addr1).faucet()

      let createGame = await rockPaperScissorsContract.connect(addr1).initiateGame(1,1,addr1.address);

      let initiateGames = await rockPaperScissorsContract.getAvailableGames();
      expect(await rockPaperScissorsContract.balanceOf(addr1.address)).to.equal(99)
      expect(initiateGames.length).to.equal(1)
    });

    it('fails when an invalid game move is made', async function() {
      await expect(rockPaperScissorsContract.initiateGame(1, 4, owner.address)).to.be.revertedWith("Invalid game move selection")
    });

    it('fails when a player has an active game', async function() {
      let addToBalance = await rockPaperScissorsContract.connect(addr1).faucet()

      let createGame = await rockPaperScissorsContract.connect(addr1).initiateGame(1,1,"0x0000000000000000000000000000000000000000");


      await expect(rockPaperScissorsContract.connect(addr1).initiateGame(1,2,"0x0000000000000000000000000000000000000000")).to.be.revertedWith("user is already playing a game");      
    });
  });

  describe("joinAvailableGame", () => {
    it('emits an event declaring a tie', async function() {
      const addToBalance = await rockPaperScissorsContract.connect(addr1).faucet()
      const addToBalance2 = await rockPaperScissorsContract.connect(owner).faucet()

      const createGame = await rockPaperScissorsContract.initiateGame(1,1,owner.address);

      const joinGame = await rockPaperScissorsContract.connect(addr1).joinAvailableGame(0, 1, { value: 1 });

      expect(joinGame)
      .to.emit(rockPaperScissorsContract, "gameResult")
      .withArgs("0x0000000000000000000000000000000000000000", "Game ended in a tie!");
      
      const player1Balance = await rockPaperScissorsContract.balanceOf(addr1.address);
      const player2Balance = await rockPaperScissorsContract.balanceOf(owner.address);

      expect(player1Balance).to.equal(100);
      expect(player2Balance).to.equal(100);
    });

    it('emits an event declaring a winner', async function() {
      const addToBalance = await rockPaperScissorsContract.connect(addr1).faucet()
      const addToBalance2 = await rockPaperScissorsContract.connect(owner).faucet()

      let createGame = await rockPaperScissorsContract.initiateGame(1,1,owner.address);

      let joinGame = await rockPaperScissorsContract.connect(addr1).joinAvailableGame(0, 0, { value: 1 });

      expect(joinGame)
      .to.emit(rockPaperScissorsContract, "gameResult")
      .withArgs(owner.address, "Winner was decided!");

      const winnerBalance = await rockPaperScissorsContract.balanceOf(owner.address);
      expect(winnerBalance).to.equal(101);
    });
  });
});
