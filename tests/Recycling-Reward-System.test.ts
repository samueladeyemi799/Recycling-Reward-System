
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const address1 = accounts.get("wallet_1")!;
const deployer = accounts.get("deployer")!;

const contractName = "Recycling-Reward-System";

describe("Recycling Reward System Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  describe("Community Impact Tracker Feature", () => {
    it("should have community impact tracking functionality", () => {
      // Test that the get-community-impact function exists and returns initial values
      const { result } = simnet.callReadOnlyFn(
        contractName,
        "get-community-impact",
        [],
        deployer
      );
      expect(result).toBeTuple();
    });

    it("should verify contract has new Community Impact Tracker functions", () => {
      // Verify the contract has our new read-only functions
      const impactResult = simnet.callReadOnlyFn(
        contractName,
        "get-community-impact",
        [],
        deployer
      );
      expect(impactResult.result).toBeTuple();
      
      // Test material impact factors query (should return none initially)
      const factorsResult = simnet.callReadOnlyFn(
        contractName,
        "get-material-impact-factors",
        ["u1"],
        deployer
      );
      expect(factorsResult.result).toBeNone();
      
      // Test community milestone query (should return none initially)
      const milestoneResult = simnet.callReadOnlyFn(
        contractName,
        "get-community-milestone",
        ["u1"],
        deployer
      );
      expect(milestoneResult.result).toBeNone();
      
      // Test user impact contribution query (should return none initially)
      const contributionResult = simnet.callReadOnlyFn(
        contractName,
        "get-user-impact-contribution",
        ["u1"],
        deployer
      );
      expect(contributionResult.result).toBeNone();
      
      // Test user badge query (should return none initially)
      const badgeResult = simnet.callReadOnlyFn(
        contractName,
        "get-user-badge",
        ["u1", "u1"],
        deployer
      );
      expect(badgeResult.result).toBeNone();
    });

    it("should allow contract owner to set material impact factors", () => {
      const { result } = simnet.callPublicFn(
        contractName,
        "set-material-impact-factors",
        ["u1", "u100", "u250", "u500", "u50"],
        deployer
      );
      expect(result).toBeOk(true);
    });

    it("should allow contract owner to create community milestones", () => {
      const { result } = simnet.callPublicFn(
        contractName,
        "create-community-milestone",
        ['"Save Our Planet"', '"Community milestone for CO2"', "u1", "u10000", "u500"],
        deployer
      );
      expect(result).toBeOk("u1");
    });

    it("should reject unauthorized access to admin functions", () => {
      // Non-owner trying to set material impact factors
      const { result } = simnet.callPublicFn(
        contractName,
        "set-material-impact-factors",
        ["u2", "u100", "u200", "u300", "u50"],
        address1
      );
      expect(result).toBeErr("u100"); // err-owner-only
    });

    it("should validate milestone category constraints", () => {
      // Try to create milestone with invalid category
      const { result } = simnet.callPublicFn(
        contractName,
        "create-community-milestone",
        ['"Invalid Category"', '"Should fail"', "u5", "u1000", "u100"],
        deployer
      );
      expect(result).toBeErr("u107"); // err-invalid-category
    });
  });
});
