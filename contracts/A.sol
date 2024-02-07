// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";

contract A {

    constructor() {}

    function requestDecryption(euint32 ct) external {
        require(TFHE.isInitialized(ct), "Ciphertext is not initialized");
        euint32 ct_r = TFHE.shl(ct, 0);
    }

}
