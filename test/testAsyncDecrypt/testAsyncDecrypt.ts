import { ethers } from "hardhat";
import { getSigners, initSigners } from "../signers";

describe("Test", function () {
  before(async function () {
    await initSigners();
    this.signers = await getSigners();
  });

  beforeEach(async function () {
    const aFactory = await ethers.getContractFactory("A");
    this.a = await aFactory.connect(this.signers.alice).deploy(); // Alice is the Oracle Admin
    await this.a.waitForDeployment();

    const aAddress = await this.a.getAddress();
    const bFactory = await ethers.getContractFactory("B");
    this.b = await bFactory.connect(this.signers.alice).deploy(aAddress);
  });

  it("test b", async function () {
    const tx = await this.b.connect(this.signers.carol).request();
    await tx.wait();
  });
});