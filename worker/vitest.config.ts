import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

export default defineConfig(async () => ({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: "./wrangler.jsonc" },
      miniflare: {
        bindings: { TOKEN: "test-token", MIGRATIONS: await readD1Migrations("./migrations") },
      },
    }),
  ],
  test: { setupFiles: ["./test/migrate.ts"] },
}));
