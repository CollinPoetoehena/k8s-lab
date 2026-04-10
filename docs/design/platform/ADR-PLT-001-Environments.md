# ADR-PLT-001: Environment Strategy

**Date:** 2026-04-10  
**Status:** Accepted  
**Deciders:** CollinPoetoehena

## Context and Problem Statement

This project needs an environment structure that reflects a real-world software delivery pipeline, while remaining practical to operate solo on constrained resources. The question is how many environments to maintain, how they should differ from each other, and whether they should run concurrently or on-demand.

In professional engineering teams, a typical pipeline includes separate Development, Test, Acceptance, and Production environments. Each stage has dedicated infrastructure, isolated access controls, and defined promotion gates. This separation reduces deployment risk and increases confidence that changes behave correctly before reaching production.

For a learning project, the challenge is balancing fidelity to real-world patterns against the overhead of operating and maintaining multiple full environments.

## Decision

Use two logically separate environments — **DTA** and **Production** — where DTA is a single shared environment that consolidates the Development, Test, and Acceptance stages.

- **DTA** mirrors Production in design and network topology but is scaled down in resources (fewer VMs, smaller node pools). It serves all pre-production validation purposes.
- **Production** is the full-scale deployment, optimized for performance, reliability, and security within the constraints of the platform. Changes only reach Production after being validated in DTA.
- The two environments are treated as **mutually exclusive in terms of concurrency**: only one is active at a given time due to resource constraints. DTA is spun up for development and testing, torn down when work is promoted or paused, and Production is brought up separately for release validation or demonstration.

## Consequences

**Positive:**
- Mirrors industry-standard promotion discipline (DTA → Production) without the full operational overhead
- Infrastructure-as-code makes spinning environments up and down on demand straightforward
- Keeps resource usage manageable for a solo learning project
- Still captures the core intent: environment separation to reduce risk and increase deployment confidence

**Negative:**
- DTA and Production do not run in parallel, which diverges from real-world continuous delivery setups where both coexist at all times
- A single shared DTA environment cannot fully replicate the isolation benefits of separate Development, Test, and Acceptance stages

**Neutral:**
- The pattern of dynamic environment provisioning/teardown is itself a realistic cloud-native practice, so the trade-off is still educational

## Alternatives Considered

1. **Fully separate DTA stages (Dev, Test, Acceptance + Production):** Closer to enterprise practice but operationally excessive for a solo learning project; the overhead of managing four environments would detract from the learning goals.
2. **Single environment for everything:** Simpler to operate but eliminates the promotion discipline and environment separation concepts entirely — counter to the project's learning goals.
3. **Persistent concurrent DTA + Production:** More realistic, but resource constraints make this impractical. The on-demand approach is a fair compromise.

## Related Decisions

- None yet

## References

- [The Twelve-Factor App](https://github.com/twelve-factor/twelve-factor)
- [The Twelve-Factor App — Dev/prod parity](https://github.com/twelve-factor/twelve-factor/blob/next/content/dev-prod-parity.md)
- General industry practice: DTA/DTAP pipeline patterns in enterprise software delivery