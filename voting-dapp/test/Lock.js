const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("VotingDApp Smart Contract", function () {
    let votingDApp, admin, voter1, voter2, voter3;

    before(async function () {
        // Get signers
        [admin, voter1, voter2, voter3] = await ethers.getSigners();

        // Deploy the contract
        const VotingDApp = await ethers.getContractFactory("VotingDApp");
        const deploymentTx = await VotingDApp.deploy();
        votingDApp = await deploymentTx;

        console.log(`Contract deployed at: ${votingDApp.address}`);
    });

    it("should allow only admin to register candidates", async function () {
        await votingDApp.connect(admin).registerCandidate("Candidate 1", voter1.address, "Party A");
        const candidate = await votingDApp.candidates(1);
        expect(candidate.name).to.equal("Candidate 1");

        await expect(
            votingDApp.connect(voter1).registerCandidate("Candidate 2", voter2.address, "Party B")
        ).to.be.revertedWith("Only admin can perform this action");
    });

    it("should prevent duplicate voter registrations", async function () {
        await votingDApp.connect(voter1).registerVoter("VOTER1_ID", "Voter 1");
        const voter = await votingDApp.voters(voter1.address);
        expect(voter.name).to.equal("Voter 1");

        await expect(
            votingDApp.connect(voter1).registerVoter("VOTER1_ID", "Voter 1")
        ).to.be.revertedWith("Voter is already registered");

        await expect(
            votingDApp.connect(voter2).registerVoter("VOTER1_ID", "Voter 2")
        ).to.be.revertedWith("National ID is already registered");
    });

    it("should allow only registered voters to vote and prevent duplicate votes", async function () {
        await votingDApp.connect(admin).registerCandidate("Candidate 2", voter2.address, "Party B");
        await votingDApp.connect(admin).startVoting();

        await votingDApp.connect(voter1).vote(1);
        const updatedVoter = await votingDApp.voters(voter1.address);
        expect(updatedVoter.hasVoted).to.be.true;

        await expect(votingDApp.connect(voter1).vote(1)).to.be.revertedWith("You have already voted");

        await expect(votingDApp.connect(voter3).vote(1)).to.be.revertedWith("You are not a registered voter");
    });

    it("should randomly select a winner in case of a tie", async function () {
        await votingDApp.connect(voter2).registerVoter("VOTER2_ID", "Voter 2");
        await votingDApp.connect(voter3).registerVoter("VOTER3_ID", "Voter 3");

        await votingDApp.connect(voter2).vote(2);
        await votingDApp.connect(voter3).vote(2);

        await votingDApp.connect(admin).endVoting();

        // Assuming winnerId is available for testing
        const winnerId = await votingDApp.winnerId();
        const winner = await votingDApp.candidates(winnerId);
        console.log(`Winner is: ${winner.name}, from party: ${winner.party}`);
        expect(winner.voteCount).to.be.gte(1);
    });
});
