import { expect } from "chai";
import { ethers } from "hardhat";

import { createInstances } from "../instance";
import { getSigners, initSigners } from "../signers";

describe("TestAsyncDecrypt", function () {
  before(async function () {
    await initSigners();
    this.signers = await getSigners();
  });

  beforeEach(async function () {
    const oracleFactory = await ethers.getContractFactory("Oracle");
    this.oracle = await oracleFactory.connect(this.signers.alice).deploy(); // Alice is the Oracle Admin
    await this.oracle.waitForDeployment();

    const tx1 = await this.oracle.addRelayer(this.signers.bob); // Bob is an Oracle Relayer
    await tx1.wait();

    const oracleAddress = await this.oracle.getAddress();
    const contractFactory = await ethers.getContractFactory("TestAsyncDecrypt");
    this.contract = await contractFactory.connect(this.signers.alice).deploy(oracleAddress);
  });

  it("test async decrypt", async function () {
    const tx2 = await this.contract.connect(this.signers.carol).request(5, 15);
    await tx2.wait();

    const filter = this.oracle.filters.EventDecryption;
    const events = await this.oracle.queryFilter(filter, -1);
    const event = events[0];

    const args = event.args;
    console.log(args);
  });
});
