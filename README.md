# ZKM Project Template

The Project Template creates an end-to-end [Ziren](https://github.com/ProjectZKM/Ziren) project:
a guest program proved by the Ziren zkVM, a host that executes it and generates proofs, and the
on-chain Solidity verifier for the proofs.

It targets Ziren V2.0: the Ziren crates are pinned to the V2.0 release commit in
`host/Cargo.toml` and `guest/Cargo.toml`, and the verifier contracts are the `v2.0.0` ones in
`contracts/src/v2.0.0`.

Two provers are available:

- Local prover: generate proofs on your own machine.
- Network prover: generate proofs on the ZKM proof network.

## Running diagram

![image](assets/temp-run-diagram.png)

## Getting Started

Install the Ziren toolchain (release `20260917` or later) and follow the instructions:

```sh
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/ProjectZKM/toolchain/refs/heads/main/setup.sh | sh
source ~/.zkm-toolchain/env
```

After `source ~/.zkm-toolchain/env` the host builds with the Ziren toolchain's `cargo`; without it,
`rustup` builds the host with the nightly pinned in `rust-toolchain.toml`, the one Ziren itself is
built with. The guest is always built with the Ziren toolchain.

## Requirements

- Local proving: x86_64 Linux. Core and compressed proofs of this example need a few GB of memory;
  Groth16 and PLONK proofs need about 80 GB, and Go 1.23 or later for the gnark prover (Ziren's `go.mod` declares `go 1.23.0`).
- Network proving: x86_64 Linux, a registered address ([apply here](https://www.zkm.io/apply)) and
  the network's client certificates.

> [!NOTE]
> All commands below run from the repository root unless they `cd` first.

## Running the project

There are four ways to run this project:
- **Execute** the program.
- Generate a **core** proof.
- Generate a **compressed** proof.
- Generate an **EVM-compatible** (Groth16 or PLONK) proof.

The guest program is built automatically by `host/build.rs` whenever the host is built.

### Execute the Program

```sh
cd host
cargo run --release -- --execute
```

This executes the guest program without proving it, checks its output and prints the cycle count.

### Generate a Core Proof

```sh
cd host
cargo run --release -- --core
```

### Generate a Compressed Proof

```sh
cd host
cargo run --release -- --compressed
```

See [proof types](https://docs.zkm.io/dev/prover.html) for the difference between core and
compressed proofs.

### Generate an EVM-Compatible Proof

Groth16 and PLONK proofs are cheap to verify on Ethereum but take longer to generate than core or
compressed proofs. The first run downloads the `v2.0.0` circuit artifacts to `~/.zkm/circuits`.

```sh
cd host
cargo run --release --bin evm -- --system groth16
cargo run --release --bin evm -- --system plonk
```

Each command verifies the proof and writes a fixture to `contracts/src/fixtures/` that the Solidity
tests verify.

### Retrieve the Verification Key

The `programVKey` your on-chain contract checks proofs against:

```sh
cd host
cargo run --release --bin vkey
```

## Using the Prover Network

Set the prover in `.env` (see `.env.example`):

```env
ZKM_PROVER=network
ZKM_PRIVATE_KEY=
SSL_CERT_PATH=
SSL_KEY_PATH=
CA_CERT_PATH=
```

The network prover generates compressed and Groth16 proofs. See the
[network prover](https://docs.zkm.io/dev/prover.html) documentation for the endpoint and certificate
settings.

## Solidity Verifier

Install [Foundry](https://getfoundry.sh/) if you do not have it:

```sh
curl -L https://foundry.paradigm.xyz | bash
```

### Verify the EVM-Compatible Proofs

```sh
cd contracts
forge test
```

The tests verify the Groth16 and PLONK fixtures against the `v2.0.0` verifiers, and check that a
changed proof or changed public values are rejected.

### Deploy the Verifier Contract

```sh
cd contracts
forge script script/ZKMVerifierGroth16.s.sol:ZKMVerifierGroth16Script --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

Use `script/ZKMVerifierPlonk.s.sol:ZKMVerifierPlonkScript` for the PLONK verifier. For more details,
see [the contracts guide](contracts/README.md).
