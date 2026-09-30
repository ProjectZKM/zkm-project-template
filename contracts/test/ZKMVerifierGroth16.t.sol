// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {ZKMVerifier} from "../src/v2.0.0/ZKMVerifierGroth16.sol";

struct ZKMProofFixtureJson {
    uint32 a;
    uint32 b;
    uint32 n;
    bytes proof;
    bytes publicValues;
    bytes32 vkey;
}

/// @notice Verifies the Groth16 proof in src/fixtures/groth16-fixture.json (written by
/// `cargo run --release --bin evm -- --system groth16`) against the v2.0.0 verifier, without mocks.
contract ZKMVerifierGroth16Test is Test {
    using stdJson for string;

    address internal verifier;

    function loadFixture() public view returns (ZKMProofFixtureJson memory) {
        string memory path = string.concat(vm.projectRoot(), "/src/fixtures/groth16-fixture.json");
        return abi.decode(vm.readFile(path).parseRaw("."), (ZKMProofFixtureJson));
    }

    function setUp() public virtual {
        verifier = address(new ZKMVerifier());
    }

    /// @notice Should succeed when the proof is valid.
    function test_VerifyProof_WhenGroth16() public view {
        ZKMProofFixtureJson memory fixture = loadFixture();
        ZKMVerifier(verifier).verifyProof(fixture.vkey, fixture.publicValues, fixture.proof);
    }

    /// @notice Should revert when a proof byte is changed.
    function test_RevertVerifyProof_WhenTamperedGroth16() public {
        ZKMProofFixtureJson memory fixture = loadFixture();
        bytes memory proof = fixture.proof;
        proof[proof.length - 1] = bytes1(uint8(proof[proof.length - 1]) ^ 1);
        vm.expectRevert();
        ZKMVerifier(verifier).verifyProof(fixture.vkey, fixture.publicValues, proof);
    }

    /// @notice Should revert when the public values do not match the proof.
    function test_RevertVerifyProof_WhenWrongPublicValuesGroth16() public {
        ZKMProofFixtureJson memory fixture = loadFixture();
        bytes memory publicValues = fixture.publicValues;
        publicValues[publicValues.length - 1] = bytes1(uint8(publicValues[publicValues.length - 1]) ^ 1);
        vm.expectRevert();
        ZKMVerifier(verifier).verifyProof(fixture.vkey, publicValues, fixture.proof);
    }
}
