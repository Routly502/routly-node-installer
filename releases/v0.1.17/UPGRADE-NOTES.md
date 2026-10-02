# Routly Node 0.1.17

Corrective release after the 0.1.15 to 0.1.16 pilot rollback. The published 0.1.16 archive and tag are retained unchanged.

- Restores the exact canonical 0.1.15 baseline; no ISP ledger edits or hash bypasses.
- Adds forward SQL bridges for current services, finance, fiber dependencies, notification and monitoring schemas.
- Keeps ambiguous legacy plan/service associations unknown rather than selecting an arbitrary match.
- Invalidates fiber verification within service mutation transactions without requiring new procedural migrations on the installed planner.
- Future upgrades from the 0.1.17 updater validate and load only the fixed signed, manifested package planner before downtime, removing the need for per-release manual planner installation.

Validation: 100 distribution tests and 16 startup tests pass. Real isolated PostgreSQL checks cover 0.1.15 upgrades using the installed signed 0.1.16 planner and the current planner, fresh install, preservation of prior hashes and records, unknown-hash rejection, and all 65 non-control runtime tables / 835 columns. Two independent package builds are byte-identical. The signed 0.1.16 package validator accepts this archive.

Archive SHA-256: af6a9d10eb07bfc3eab1d085eed3d2227f63875dc235a9ba7a80658055aa3584

Rollout still requires a separately approved publication in Routly Control. Normal updates are assigned and monitored there; no ISP server command is required for this corrected update.
