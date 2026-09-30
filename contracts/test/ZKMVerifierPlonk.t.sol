// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {ZKMVerifier} from "../src/v2.0.0/ZKMVerifierPlonk.sol";

struct ZKMProofFixtureJson {
    uint32 a;
    uint32 b;
    uint32 n;
    bytes proof;
    bytes publicValues;
    bytes32 vkey;
}

/// @notice Verifies the Plonk proof in src/fixtures/plonk-fixture.json (written by
/// `cargo run --release --bin evm -- --system plonk`) against the v2.0.0 verifier, without mocks.
contract ZKMVerifierPlonkTest is Test {
    using stdJson for string;

    address internal verifier;

    function loadFixture() public view returns (ZKMProofFixtureJson memory) {
        string memory path = string.concat(vm.projectRoot(), "/src/fixtures/plonk-fixture.json");
        return abi.decode(vm.readFile(path).parseRaw("."), (ZKMProofFixtureJson));
    }

    function setUp() public virtual {
        verifier = address(new ZKMVerifier());
    }

    /// @notice Should succeed when the proof is valid.
    function test_VerifyProof_WhenPlonk() public view {
        ZKMProofFixtureJson memory fixture = loadFixture();
        ZKMVerifier(verifier).verifyProof(fixture.vkey, fixture.publicValues, fixture.proof);
    }

    /// @notice Should revert when a proof byte is changed.
    function test_RevertVerifyProof_WhenTamperedPlonk() public {
        ZKMProofFixtureJson memory fixture = loadFixture();
        bytes memory proof = fixture.proof;
        proof[proof.length - 1] = bytes1(uint8(proof[proof.length - 1]) ^ 1);
        vm.expectRevert();
        ZKMVerifier(verifier).verifyProof(fixture.vkey, fixture.publicValues, proof);
    }

    /// @notice Should revert when the public values do not match the proof.
    function test_RevertVerifyProof_WhenWrongPublicValuesPlonk() public {
        ZKMProofFixtureJson memory fixture = loadFixture();
        bytes memory publicValues = fixture.publicValues;
        publicValues[publicValues.length - 1] = bytes1(uint8(publicValues[publicValues.length - 1]) ^ 1);
        vm.expectRevert();
        ZKMVerifier(verifier).verifyProof(fixture.vkey, publicValues, fixture.proof);
    }
}
