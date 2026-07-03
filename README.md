# taiko-equivalence

[![ci](https://github.com/caliperforge/taiko-equivalence/actions/workflows/ci.yml/badge.svg)](https://github.com/caliperforge/taiko-equivalence/actions/workflows/ci.yml)

Differential equivalence tests for **Taiko's Type-1 Ethereum-equivalence
guarantee**, shipped as clean/planted twin Foundry projects. The harness
runs the same input against a canonical L1 reference fixture and a Taiko
execution-layer mirror under test, then asserts byte-equivalence. The
clean twin passes; the planted twin (a single-hunk seeded equivalence
break per case) fails with an explicit `INVARIANT VIOLATED <case>`
marker. Both twins run in CI on every commit, so the harness carries
standing proof that each property catches the divergence class it
claims to catch.

Taiko is a Type-1 ZK-EVM: full equivalence with Ethereum's
specification, including precompiled contracts and the gas schedule,
plus based sequencing with permissionless proposing and proving. Each
of the three v0.1 cases targets one of those named surfaces.

## Why these cases

| Case | Type-1 / based-rollup spec point | Taiko docs reference |
|---|---|---|
| **PrecompileParity** | Yellow Paper Appendix E (precompiled contracts): canonical L1 precompiles MUST return byte-identical output. Tested via SHA256 (`0x02`) on three input vectors (empty, the NIST FIPS 180-4 "abc" vector, fuzzed 1 KiB buffer). | Taiko docs, "Multi-proofs": "Taiko is a Type-1 ZK-EVM that aims for full equivalence with Ethereum's specification, including precompiled contracts." (https://docs.taiko.xyz/core-concepts/multi-proofs) |
| **GasScheduleEquivalence** | EIP-2929 (cold/warm storage access cost): cold SLOAD = 2100 gas, warm SLOAD = 100 gas. A Type-1 rollup MUST not silently re-price storage reads. Planted twin substitutes the pre-EIP-2929 constant (800) for cold SLOAD, the canonical bug class an execution-client shim ships when its constants table was forked off an older snapshot. | EIP-2929, "Specification" (https://eips.ethereum.org/EIPS/eip-2929); Taiko whitepaper, "Why Type-1": gas-schedule equivalence is the discriminator between Type-1 and Type-2 (https://taiko.xyz/whitepaper.pdf) |
| **BasedSequencingOrdering** | Based-rollup proposing rule: the prover MUST attest to the inclusion list in proposal order. Sorting by priority-fee descending IS the canonical sequencer-MEV-extraction violation that based sequencing forbids by construction. | Taiko whitepaper, "Based Contestable Rollup": proposing and proving roles are decoupled; based sequencing inherits L1's ordering rule via L1 inclusion (https://taiko.xyz/whitepaper.pdf); Taiko docs, "Based contestable rollup" (https://docs.taiko.xyz/core-concepts/based-contestable-rollup) |

Three illustrative cases ship in v0.1. They are the existence proof for
the pattern, not the exhaustive catalogue; the scope section below
names the larger surface.

## Layout

`clean/` and `planted/` are full Foundry projects. Toolchain config is
byte-identical between the two twins; only the three contracts under
`src/` differ.

```
taiko-equivalence/
  README.md                    # this file
  LICENSE                      # Apache-2.0
  NOTICE                       # spec/doc attributions (Yellow Paper, EIPs, NIST, Taiko Labs)
  AI_DISCLOSURE.md             # what is AI-touched and what gates it
  lib/forge-std                # pinned git submodule, tag v1.9.4
  ci/                          # the two CI leg scripts
  clean/
    foundry.toml               # solc 0.8.28; CI-friendly fuzz budgets
    remappings.txt
    lib/forge-std              # link to the repo-root submodule
    src/
      PrecompileMirror.sol     # passes through to precompile 0x02
      GasSchedule.sol          # post-EIP-2929 constants (2100 / 100)
      BasedSequencer.sol       # preserves insertion order on finalize()
    test/
      Equivalence.t.sol        # differential harness, all three cases
  planted/
    foundry.toml               # byte-identical to clean/foundry.toml
    remappings.txt
    lib/forge-std              # link to the repo-root submodule
    src/
      PrecompileMirror.sol     # XOR-masks top byte of SHA256 output
      GasSchedule.sol          # pre-EIP-2929 cold SLOAD (800)
      BasedSequencer.sol       # sorts by priority-fee descending on finalize()
    test/
      Equivalence.t.sol        # BYTE-IDENTICAL to clean/test/Equivalence.t.sol
```

`diff -r clean/src planted/src` shows the three planted hunks as
single-localized mutations: one hunk per case, nothing else changes.

## Differential harness

`test/Equivalence.t.sol` is the harness. For each case it:

1. Reads a fixed canonical L1 reference (precompile `0x02`, EIP-2929
   constants, or the insertion-order golden list). Forge's local EVM is
   itself L1-equivalent, so calling precompile `0x02` directly gives a
   contemporaneous L1 SHA256 output without forking a remote node.

2. Reads the Taiko execution-layer mirror under test.

3. Asserts byte-equivalence. On divergence: emits
   `INVARIANT VIOLATED <CaseName>` on stdout, dumps the L1 vs mirror
   bytes, and reverts with the same marker as the revert reason, so the
   CI grep picks it up in both the failure list and the logs.

The harness is byte-identical between `clean/test/` and `planted/test/`.
The `clean/` leg passes silently; the `planted/` leg fires the marker on
every case that has a planted hunk.

## Running locally

Requires `forge` 1.7.x. Clone with submodules:

```sh
git clone --recursive https://github.com/caliperforge/taiko-equivalence
cd taiko-equivalence

# clean leg - equivalence holds
cd clean
forge test            # 6/6 pass, zero INVARIANT VIOLATED markers

# planted leg - equivalence fails on every planted hunk
cd ../planted
forge test -vv        # 5 of 6 tests fail with INVARIANT VIOLATED markers
                      # (warm SLOAD test stays green - the planted hunk
                      # only mutated cold SLOAD, demonstrating the
                      # single-localized-hunk discipline)
```

CI runs both legs on every push: `clean-passes` asserts a zero exit
code and zero markers; `planted-bug-twin-fails` asserts a non-zero exit
code and at least one `INVARIANT VIOLATED` marker on stdout. A green
pipeline therefore proves both that the properties hold on the clean
mirrors and that they catch the planted breaks.

## Scope discipline

These three cases are illustrative. The Type-1 surface is much larger:
every precompile address, every opcode gas cost, every state-access
edge case from EIP-2929 / EIP-3529 / EIP-3651, plus the based-rollup
proving-pipeline race conditions. Future versions expand case coverage;
v0.1 ships the pattern (planted twin + differential harness +
`INVARIANT VIOLATED` marker convention) that every additional case
reuses.

The L1 reference fixture in the harness is the in-process Foundry EVM,
not a remote L1 fork. That suffices for the bug-class demonstration. A
follow-on extension can replace the in-process fixture with a forked L1
RPC endpoint (`vm.createSelectFork`) to lift the differential harness
to a true cross-chain check; the harness already isolates the L1 vs
mirror call shape behind the same interface, so the lift is a one-line
substitution per case.

## Toolchain

- solc `0.8.28`, `via_ir = false`, optimizer at 200 runs.
- `lib/forge-std` pinned at tag `v1.9.4` as a git submodule; each twin
  links it into its own `lib/`, so both projects build offline from a
  recursive clone.

## License and attribution

Apache-2.0 (see `LICENSE`). Upstream attributions for the Ethereum
Yellow Paper, the EIP authors (EIP-2929), NIST FIPS 180-4, and Taiko
Labs documentation are in `NOTICE`. No Taiko-Labs-authored source is
vendored or copied; the mirrors are original code written against the
public specifications. The "Taiko" name is a trademark of Taiko Labs;
this repository is not affiliated with, sponsored by, or endorsed by
Taiko Labs.

## AI disclosure

CaliperForge's authoring stack is AI-augmented. What is AI-touched on
this repo, and the reviews that gate it, are disclosed in
`AI_DISCLOSURE.md`. CI verdicts and the quoted spec constants are not
AI-touched.
