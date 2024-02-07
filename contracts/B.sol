// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";
import "./A.sol";

contract B {
    euint32 x;
    A a;

    constructor(address _a) {
        a = A(_a);
        x = TFHE.asEuint32(32);
    }

    function request() public {
        a.requestDecryption(x);
    }

}
