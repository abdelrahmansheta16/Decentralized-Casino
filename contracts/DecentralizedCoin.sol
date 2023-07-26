// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {FixedPoint, fromFraction, mulFixedPoint, divFixedPoint} from "./FixedPoint.sol";

contract DecentralizedCasino {
    mapping(address => uint256) public gameWeiValues;
    mapping(address => uint256) public blockNumbersToBeUsed;

    address[] public lastThreeWinners;

    function playGame() public payable {
        uint256 blockNumberToBeUsed = blockNumbersToBeUsed[msg.sender];

        if (blockNumberToBeUsed == 0) {
            // first run, determine block number to be used
            blockNumbersToBeUsed[msg.sender] = block.number + 128;
            gameWeiValues[msg.sender] = msg.value;
            return;
        }

        require(block.number > blockNumbersToBeUsed[msg.sender], "Too early");
        require(block.number < blockNumbersToBeUsed[msg.sender], "Too late");

        uint256 randomNumber = block.prevrandao;

        if (randomNumber % 2 == 0) {
            uint256 randomWinner = randomNumber % 3;
            FixedPoint winningAmount = fromFraction(
                gameWeiValues[msg.sender] * 10,
                uint256(4)
            );
            FixedPoint bonusAmount = fromFraction(
                gameWeiValues[msg.sender] * 1,
                uint256(2)
            );
            (bool success, ) = msg.sender.call{
                value: mulFixedPoint(uint256(1), winningAmount)
            }("");
            (bool success1, ) = lastThreeWinners[randomWinner].call{
                value: mulFixedPoint(uint256(1), bonusAmount)
            }("");
            require(success1, "Transfer failed");
            require(success, "Transfer failed.");

            lastThreeWinners.push(msg.sender);

            if (lastThreeWinners.length > 3) {
                lastThreeWinners[0] = lastThreeWinners[1];
                lastThreeWinners[1] = lastThreeWinners[2];
                lastThreeWinners[2] = lastThreeWinners[3];
                lastThreeWinners.pop();
            }
        }

        blockNumbersToBeUsed[msg.sender] = 0;
        gameWeiValues[msg.sender] = 0;
    }

    receive() external payable {
        playGame();
    }
}
