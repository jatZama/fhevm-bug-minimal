// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";
import "./Oracle.sol";

contract TestAsyncDecrypt {
    euint32 x;
    uint32 y;
    Oracle oracle;

    modifier onlyOracle() {
        require(msg.sender == address(oracle));
        _;
    }

    constructor(address _oracle) {
        oracle = Oracle(_oracle);
        x = TFHE.asEuint32(32);
    }

    function request(uint32 input1, uint32 input2) public {
        bytes memory callbackdata = abi.encodeWithSignature("callback(uint32,uint32)", input1, input2);
        oracle.requestDecryption(x, address(this), callbackdata, 0, block.timestamp + 100);
    }

    // Transfers an encrypted amount from the message sender address to the `to` address.
    function callback(uint32 userInput1, uint32 userInput2, uint32 decryptedResult) public onlyOracle returns (uint32) {
        unchecked {
            uint32 result = userInput1 + userInput2 + decryptedResult;
            return result;
        }
    }
}
