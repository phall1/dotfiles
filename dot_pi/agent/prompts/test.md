---
description: Add high-value tests grounded in actual behavior and risk
---
Add tests for $@ using the project's existing framework and conventions. Inspect implementation and neighboring tests first. Cover observable contracts, important boundaries, error paths, and the reported regression; avoid assertions coupled only to implementation details. Demonstrate that the new test fails for the defect when feasible, then run the smallest relevant suite plus nearby checks. Report coverage gained, commands/results, and untested risks.
