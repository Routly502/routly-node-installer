import { createHash } from "node:crypto";
import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";

// 0001 was shipped before the Node employee-scope columns existed. The
// baseline is kept current for fresh installs, but released installations
// must be allowed to advance to the additive scope migration below.
const legacyMigrationHashes = new Map([
  ["0001-routly-node-baseline.sql", new Set(["da2795bfb505e5e342e535a0f52c80ebcedbac6a2204377db4cbc5384e496cd6"])],
]);
// This already-released migration contains PL/pgSQL BEGIN/END inside DO blocks.
// Its bytes are immutable because installed nodes verify the migration hash.
const legacyTaxMigrationHash = "51204261a81f8f490fef262b9d406c8e3ad7c20c896d5cb3cd83dd294423f5eb";
// The append-only stock ledger migration has one narrowly scoped trigger function.
const warehouseStockLedgerMigrationHash = "cd5e21990fc07bb3b9940191d495459d885ca8b0e0ff253a787d9f46a76041a6";
// Explicit product deletion updates that trigger without permitting arbitrary
// transaction wrappers or procedural commands in other migration files.
const warehousePermanentDeletionMigrationHash = "1c8d28ac43eed3c9b4d0017f8a6da56fcc6f42ddfa24a54600ad0f4db2ef2b3c";

export function loadMigrationPlan(directory) {
  const names = readdirSync(directory).filter(name => /^\d{4}[-_][A-Za-z0-9][A-Za-z0-9._-]*\.sql$/.test(name)).sort();
  if (!names.length) throw Error("no ordered migrations found");
  return names.map(name => {
    const source = readFileSync(join(directory, name), "utf8");
    const hash = createHash("sha256").update(source).digest("hex");
    const trustedLegacyDoBlocks = name === "0014-routly-other-taxes.sql" && hash === legacyTaxMigrationHash;
    const trustedWarehouseStockLedgerTrigger = name === "0040-warehouse-stock-movements.sql"
      && hash === warehouseStockLedgerMigrationHash;
    const trustedWarehousePermanentDeletion = name === "0043-warehouse-permanent-deletion.sql"
      && hash === warehousePermanentDeletionMigrationHash;
    if (/(^|[\r\n])\s*\\[A-Za-z]/.test(source) ||
        (!trustedLegacyDoBlocks && !trustedWarehouseStockLedgerTrigger && !trustedWarehousePermanentDeletion
          && /(^|[;\r\n])\s*(BEGIN|START\s+TRANSACTION|COMMIT|ROLLBACK|END)\s*;?/im.test(source)) ||
        source.includes("$ROUTLY_MIGRATION_CHECK$") ||
        source.includes("__ROUTLY_MIGRATION_") ||
        source.includes("routly_apply")) throw Error(`migration contains forbidden command, transaction, or quote tag: ${name}`);
    return { name, source, hash };
  });
}

export function quoteSql(value) { return `'${value.replaceAll("'", "''")}'`; }

export function buildMigrationScript(plan) {
  const blocks = plan.map(({ name, source, hash }) => `
DO $ROUTLY_MIGRATION_CHECK$ BEGIN
  IF EXISTS (SELECT 1 FROM routly_migration_ledger WHERE migration_name = ${quoteSql(name)}
            AND migration_sha256 <> ${quoteSql(hash)}
            ${legacyMigrationHashes.has(name) ? `AND migration_sha256 NOT IN (${[...legacyMigrationHashes.get(name)].map(quoteSql).join(",")})` : ""}) THEN
    RAISE EXCEPTION 'migration hash mismatch: ${name}';
  END IF;
END $ROUTLY_MIGRATION_CHECK$;
SELECT NOT EXISTS (SELECT 1 FROM routly_migration_ledger WHERE migration_name = ${quoteSql(name)}) AS routly_apply \\gset
\\if :routly_apply
${source.trimEnd()}
INSERT INTO routly_migration_ledger (migration_name,migration_sha256) VALUES (${quoteSql(name)},${quoteSql(hash)});
\\endif
`).join("\n");
  return `BEGIN;
SELECT pg_advisory_xact_lock(735194217);
CREATE TABLE IF NOT EXISTS routly_migration_ledger (
 migration_name text PRIMARY KEY, migration_sha256 text NOT NULL, applied_at timestamptz NOT NULL DEFAULT now()
);
${blocks}
COMMIT;
`;
}