import { applyD1Migrations } from "cloudflare:test";
import { env } from "cloudflare:workers";

const testEnv = env as unknown as { DB: D1Database; MIGRATIONS: Parameters<typeof applyD1Migrations>[1] };
await applyD1Migrations(testEnv.DB, testEnv.MIGRATIONS);
