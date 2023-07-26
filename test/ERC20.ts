import { ethers, network } from "hardhat"
import { ERC20__factory } from "../typechain-types";
import { smock } from "@defi-wonderland/smock";
import { expect } from "chai";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
describe("ERC20", function () {
    async function deployAndMockERC20() {
        const [alice, bob] = await ethers.getSigners();
        const ERC20 = await smock.mock<ERC20__factory>("ERC20");
        const erc20Token = await ERC20.deploy("Name", "SYM", 18);
        await erc20Token.setVariable("balanceOf", {
            [alice.address]: 100
        })
        await network.provider.send("evm_mine");

        return { alice, bob, erc20Token };
    }
    it("transfers token correctly", async function () {
        const { alice, bob, erc20Token } = await loadFixture(deployAndMockERC20);
        await expect(await erc20Token.transfer(bob.address, 50)).to.changeTokenBalances(erc20Token, [alice, bob], [-50, 50]);
        await expect(await erc20Token.connect(bob).transfer(alice.address, 50)).to.changeTokenBalances(erc20Token, [alice, bob], [50, -50]);
    });
    it("transferFrom token correctly", async function () {
        const { alice, bob, erc20Token } = await loadFixture(deployAndMockERC20);
        await expect(await erc20Token.transferFrom(alice.address,bob.address, 50)).to.changeTokenBalances(erc20Token, [alice, bob], [-50, 50]);
    });
    it("should revert if sender has insufficient balance", async function () {
        const { bob, erc20Token } = await loadFixture(deployAndMockERC20);
        await expect(erc20Token.transfer(bob.address, 200)).to.be.revertedWith("insufficient balance");

    })
    it("should emit Transfer event on transfer", async function () {
        const { alice, bob, erc20Token } = await loadFixture(deployAndMockERC20);
        await expect(erc20Token.transfer(bob.address, 50)).to.be.emit(erc20Token, "Transfer").withArgs(alice.address, bob.address, 50)

    })
})