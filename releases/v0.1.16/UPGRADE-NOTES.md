# Routly Node 0.1.16 — prepared, not assigned

Validated package for Linux amd64 / Ubuntu 22.04+ and Node.js 22+.

## Existing Node prerequisite
The migration planner installed by 0.1.15 rejects the new exact-hash-validated procedural migrations, beginning with 0014-routly-other-taxes.sql. Before assigning this release in Routly Control, an administrator must provision the matching routly-migration-plan.mjs supplied here at /usr/bin/routly-migration-plan.mjs, root-owned and mode 0644. Verify its trusted SHA-256 before installing. The package updater itself is unchanged from 0.1.15. Do not assign or publish in Control until this prerequisite is confirmed on a pilot Node.

Planner SHA-256: 0e7daf793293ff49d0f86f924acee2637b6cff54e4c86156a1cc2d19097276a2
Package SHA-256: 89b712ec9fd37100e5e44610f9db0839460b74e3e48e96e2475400c24e7474fe

All previously published Node SQL migrations retain their contents and filenames. Newly distributed portal-access and account-recovery migration filenames avoid the installed validator's secret-path guard; the validator is unchanged. Package migration inventory: 46 ordered SQL files.

Checks passed: 79 distribution tests and 10 startup-boundary/connection tests; package validator passed. No actual ISP upgrade or rollback has been performed. Replit Publish owns managed production schema; no production data or schema mutation was made.

This GitHub release is deliberately a draft: latest remains v0.1.15. No Control release was created, published or assigned, and no ISP was updated.
