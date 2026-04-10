# Environments

This project uses two environments that reflect a real-world software delivery pipeline: DTA and Production. The structure is intentionally modelled after how professional engineering teams operate, to build familiarity with industry-standard practices around environment separation, promotion workflows, and infrastructure consistency, etc.

## DTA (Development, Test, Acceptance)

The DTA environment is a scaled-down mirror of production. It exists to mimic real-world delivery pipelines, where changes are validated in a production-like environment (or multiple environments, depending on the criticality of the system) before being promoted. In professional settings, DTA stages are often separate environments — each with its own dedicated infrastructure, access controls, and promotion gates. Having distinct Development, Test, and Acceptance environments allows teams to isolate concerns: development builds are tested in isolation, integration testing happens in a shared test environment, and acceptance testing validates the release candidate against business requirements before going live.

However, because this is a learning project, maintaining fully separate environments for each DTA stage is not necessary or practical. The overhead of operating three independent environments would outweigh the learning value at this stage. Instead, a single shared DTA environment is used that serves all three purposes. This still captures the core intent — infrastructure that closely mirrors production in design and network topology, etc., just scaled down in resources (e.g., fewer VMs, smaller node pools) to keep everything manageable and iteration fast.

The important takeaway is the *why* behind the pattern: environment separation exists to reduce risk, increase confidence in deployments, and catch issues before they reach production. This is a fundamental principle of software delivery that transcends specific tools or platforms. By following this pattern, even in a simplified form, it mimics real-world practices and improves reliability.

## Production

The production environment is the real, fully scaled deployment of the system. It is optimized for performance, reliability, and security within the constraints of the platform used. Changes only reach production after being validated in DTA, reflecting the same promotion discipline used in professional engineering teams.

## Concurrency of Environments

Due to resource constraints, not all environments run simultaneously. In practice, only one of DTA or Production is active at any given time.

This is a deliberate trade-off. In a professional setting, DTA and Production would run in parallel continuously, allowing teams to develop and test against DTA while production serves live traffic. Here, the two are treated as mutually exclusive: DTA is brought up for development and testing, then torn down when work is promoted or paused, and Production is spun up separately when validating a release or demonstrating the system.

This pattern is still realistic — many teams spin environments up and down dynamically, especially in cloud-native setups where infrastructure-as-code makes it easy to provision and destroy on demand. The key discipline being practiced here is that the environments remain logically separate and follow the same promotion flow, even if they don't coexist at all times (this mimics the concepts without having the ongoing management/cost of the two environments, which is feasible in this case since it is a learning project).