
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;

describe("Recycling Reward System Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("verifies Recycling-Reward-System contract is deployed", () => {
    const contract = simnet.getContractAST("Recycling-Reward-System");
    expect(contract).toBeDefined();
  });

  it("verifies config-registry contract is deployed", () => {
    const contract = simnet.getContractAST("config-registry");
    expect(contract).toBeDefined();
  });
});
