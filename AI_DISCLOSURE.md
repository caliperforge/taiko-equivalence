# AI Disclosure: taiko-equivalence

The `taiko-equivalence` harness is built and maintained by CaliperForge
under an AI-augmented authoring stack. This document is calm disclosure
of which surfaces are AI-touched and the review discipline that gates
each one. The discipline mirrors CaliperForge's other public
repositories.

## What is AI-touched

- **The execution-layer mirrors and the differential harness.** The
  clean/planted twin contracts under `clean/src/` and `planted/src/`
  and the differential harness `test/Equivalence.t.sol` are drafted by
  a Claude model against the public specifications cited in `NOTICE`
  (Yellow Paper Appendix E, EIP-2929, NIST FIPS 180-4, Taiko docs and
  whitepaper), then reviewed and edited by the case specialist before
  landing. Every case is additionally gated by an independent
  code-quality review before any public flip.
- **README, case rationale, NOTICE prose.** Drafted with AI
  assistance; reviewed against CaliperForge's internal register rubric
  and an independent claims review before publish.

## What is NOT AI-touched

- The specifications themselves. EIP-2929 constants, the FIPS 180-4
  "abc" vector, and the Yellow Paper precompile surface are quoted
  from their public sources, not generated.
- Forge-std. It is vendored as a pinned, unmodified git submodule
  (tag v1.9.4, zero patches). Nothing in `lib/` is authored here.
- The CI verdict. Pass/fail is a function of the `forge` runs on the
  two legs, not of any model output. The planted leg's assertion is
  inverted (it must fail with markers), so a green pipeline is
  standing proof of detection, not an unfalsified checkmark.
- The operator's final-pass sign-off decisions and the gate reviews
  (content register, code quality) that precede the public flip.

## Audit trail

- Every commit lists the author (Michael Moffett, operator at
  CaliperForge) and is operator-clean.
- Both CI legs (`clean-passes` and `planted-bug-twin-fails`) run on
  every push; the planted leg prints its `INVARIANT VIOLATED` markers
  into the job summary so reviewers can see each catch.
- Independent content and code-quality reviews run BEFORE any public
  flip; this repository is private until those gates pass.

## Why we disclose

CaliperForge's identity register makes AI-augmented authorship the
default disclosure posture, not the exception. Reviewers should know
which content was AI-drafted so they can apply their own scrutiny at
that surface. See
[caliperforge.com/ai-disclosure](https://caliperforge.com/ai-disclosure)
for the org-level register.

## Contact

Operator: Michael Moffett, michael@caliperforge.com, team@caliperforge.com.
