// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.20;

import "fhevm/lib/TFHE.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Oracle is Ownable2Step {
    struct DecryptionRequest {
        euint32 ct;
        address callbackAddress;
        bytes callbackdata;
        uint256 msgValue;
        uint256 maxTimestamp;
    }

    uint256 counter; // tracks the number of decryption requests

    mapping(address => bool) isRelayer;
    mapping(uint256 => DecryptionRequest) decryptionRequests;
    mapping(uint256 => bool) isFulfilled;

    constructor() Ownable(msg.sender) {}

    event EventDecryption(
        uint256 indexed requestID,
        euint32 ct,
        address callbackAddress,
        bytes callbackdata,
        uint256 msgValue,
        uint256 maxTimestamp
    );

    event AddedRelayer(address indexed realyer);

    event RemovedRelayer(address indexed realyer);

    event ResultCallback(uint256 indexed requestID, bool success, bytes result);

    function addRelayer(address relayerAddress) external onlyOwner {
        require(!isRelayer[relayerAddress], "Address is already relayer");
        isRelayer[relayerAddress] = true;
        emit AddedRelayer(relayerAddress);
    }

    function removeRelayer(address relayerAddress) external onlyOwner {
        require(isRelayer[relayerAddress], "Address is not a relayer");
        isRelayer[relayerAddress] = false;
        emit RemovedRelayer(relayerAddress);
    }

    // Requests the decryption of ciphertext `ct` with the result returned in a callback.
    // During callback, callbackAddress is called with [callbackdata,decrypt(ct)] as calldata.
    // Meant to be called in transactions.
    function requestDecryption(
        euint32 ct,
        address callbackAddress,
        bytes memory callbackdata,
        uint256 msgValue, // msg.value of callback tx, if callback is payable
        uint256 maxTimestamp
    ) external {
        require(TFHE.isInitialized(ct), "Ciphertext is not initialized");
        euint32 ct_r = TFHE.shl(ct, 0); // this is similar to no-op, except it would fail if ct is a "fake" handle, 
                                // not corresponding to a verified ciphertext in privileged memory
        DecryptionRequest memory decryptionReq = DecryptionRequest(
            ct_r,
            callbackAddress,
            callbackdata,
            msgValue,
            maxTimestamp
        );
        decryptionRequests[counter] = decryptionReq;
        emit EventDecryption(counter, ct_r, callbackAddress, callbackdata, msgValue, maxTimestamp);
        counter++;
    }

    function fulfillRequest(uint256 requestID, uint32 decryptedCt) external payable onlyRelayer {
        require(!isFulfilled[requestID], "Request is already fulfilled");
        DecryptionRequest memory decryptionReq = decryptionRequests[requestID];
        require(block.timestamp <= decryptionReq.maxTimestamp, "Too late");
        bytes memory calldataComplete = abi.encode(decryptionReq.callbackdata, decryptedCt);
        (bool success, bytes memory result) = (decryptionReq.callbackAddress).call{ value: decryptionReq.msgValue }(
            calldataComplete
        );
        emit ResultCallback(requestID, success, result);
        isFulfilled[requestID] = true;
    }

    modifier onlyRelayer() {
        require(isRelayer[msg.sender], "Not relayer");
        _;
    }
}
