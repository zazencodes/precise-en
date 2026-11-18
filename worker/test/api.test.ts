import { env, exports } from "cloudflare:workers";
import { beforeEach, describe, expect, it } from "vitest";

const auth = { Authorization: "Bearer test-token" };
// Each test starts with all daily limits available.
beforeEach(async () => {
  await env.DB.prepare("DELETE FROM words").run();
});
const entry = (word: string, difficulty = "advanced") => ({
  word,
  part_of_speech: "adjective",
  difficulty,
  definition: "Producing the same result however many times it is applied.",
  phrase: "make sure running it twice doesn't break anything",
  rewrite: "Make the migration idempotent.",
});

function call(path: string, init: RequestInit = {}) {
  return exports.default.fetch(`https://api.test${path}`, { ...init, headers: { ...auth, ...init.headers } });
}

function post(path: string, body: unknown) {
  return call(path, { method: "POST", body: JSON.stringify(body) });
}

describe("API", () => {
  it("refuses requests without the token", async () => {
    const response = await exports.default.fetch("https://api.test/words", {
      headers: { Authorization: "Bearer wrong" },
    });
    expect(response.status).toBe(401);
  });

  it("adds a word that is new, due now, unseen and unarchived", async () => {
    const response = await post("/words", entry("idempotent"));
    expect(response.status).toBe(201);
    const { word } = (await response.json()) as { word: Record<string, unknown> };
    expect(word).toMatchObject({ ...entry("idempotent"), seen_at: null, archived_at: null, reps: 0 });
    expect(word.due_at).toBe(word.created_at);
    expect(word.created_at).toMatch(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/);
    const list = (await (await call("/words")).json()) as { words: { word: string }[] };
    expect(list.words.map((w) => w.word)).toContain("idempotent");
  });

  it("refuses a word that is already saved", async () => {
    expect((await post("/words", entry("terse"))).status).toBe(201);
    const duplicate = await post("/words", { ...entry("terse"), definition: "Another definition." });
    expect(duplicate.status).toBe(409);
    expect(await duplicate.json()).toEqual({ error: "terse is already saved" });
  });

  it("enforces independent daily limits even for simultaneous captures and archived words", async () => {
    const limits = async () => (await (await call("/capture-limits")).json() as {
      limits: { difficulty: string; daily_limit: number; captured_today: number }[];
    }).limits;
    const setCommon = (value: unknown) => call("/capture-limits/common", {
      method: "PUT", body: JSON.stringify({ daily_limit: value }),
    });
    expect(await limits()).toEqual(expect.arrayContaining([
      { difficulty: "common", daily_limit: 5, captured_today: 0 },
      { difficulty: "advanced", daily_limit: 5, captured_today: 0 },
      { difficulty: "rare", daily_limit: 5, captured_today: 0 },
    ]));
    for (const value of [-1, 100, 1.5, "2", null]) {
      expect((await setCommon(value)).status).toBe(400);
    }
    expect((await setCommon(1)).status).toBe(204);
    const captures = await Promise.all(["brief", "plain"].map(w => post("/words", entry(w, "common"))));
    expect(captures.map(r => r.status).sort()).toEqual([201, 429]);
    const { word } = await captures.find(r => r.status === 201)!.json() as { word: { id: number } };
    expect((await post(`/words/${word.id}/archive`, {})).status).toBe(200);
    expect((await post("/words", entry("short", "common"))).status).toBe(429);
    expect((await post("/words", entry("pithy"))).status).toBe(201);
    expect((await setCommon(2)).status).toBe(204);
    expect((await post("/words", entry("short", "common"))).status).toBe(201);
    expect((await limits()).find(row => row.difficulty === "common")?.captured_today).toBe(2);

    await env.DB.prepare("UPDATE words SET created_at = strftime('%Y-%m-%dT23:59:59Z','now','-1 day')").run();
    expect((await limits()).find(row => row.difficulty === "common")?.captured_today).toBe(0);
    expect((await setCommon(0)).status).toBe(204);
    expect((await post("/words", entry("crisp", "common"))).status).toBe(429);
    expect((await setCommon(5)).status).toBe(204);
    expect((await post("/words", entry("crisp", "common"))).status).toBe(201);
  });

  it("refuses anything but one lowercase word and valid fields", async () => {
    for (const word of ["Idempotent", "two words", "", "idem2"]) {
      expect((await post("/words", entry(word))).status).toBe(400);
    }
    expect((await post("/words", { ...entry("lucid"), part_of_speech: "phrase" })).status).toBe(400);
    expect((await post("/words", { ...entry("lucid"), difficulty: undefined })).status).toBe(400);
    expect((await post("/words", { ...entry("lucid"), difficulty: "obscure" })).status).toBe(400);
    expect((await post("/words", { ...entry("lucid"), definition: undefined })).status).toBe(400);
  });

  it("schedules a review and marks the word seen", async () => {
    const { word } = (await (await post("/words", entry("succinct", "common"))).json()) as { word: { id: number } };
    const response = await post(`/words/${word.id}/review`, { rating: "good" });
    const reviewed = ((await response.json()) as { word: Record<string, unknown> }).word;
    expect(reviewed).toMatchObject({ reps: 1, interval_days: 1, difficulty: "common" });
    expect(reviewed.seen_at).not.toBeNull();
    expect(reviewed.reviewed_at).not.toBeNull();
    for (const rating of ["great", "hard", "easy"]) {
      expect((await post(`/words/${word.id}/review`, { rating })).status).toBe(400);
    }
  });

  it("marks a word seen once and keeps the first time", async () => {
    const { word } = (await (await post("/words", entry("salient"))).json()) as { word: { id: number } };
    const first = ((await (await post(`/words/${word.id}/seen`, {})).json()) as { word: { seen_at: string } }).word;
    const again = ((await (await post(`/words/${word.id}/seen`, {})).json()) as { word: { seen_at: string } }).word;
    expect(first.seen_at).not.toBeNull();
    expect(again.seen_at).toBe(first.seen_at);
  });

  it("archives and restores a word without removing it from GET /words", async () => {
    const { word } = (await (await post("/words", entry("ephemeral", "rare"))).json()) as { word: { id: number } };
    const archived = (await post(`/words/${word.id}/archive`, {}));
    expect(archived.status).toBe(200);
    const archivedWord = ((await archived.json()) as { word: { archived_at: string | null } }).word;
    expect(archivedWord.archived_at).toMatch(/^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ$/);

    const archivedAgain = ((await (await post(`/words/${word.id}/archive`, {})).json()) as {
      word: { archived_at: string | null };
    }).word;
    expect(archivedAgain.archived_at).toBe(archivedWord.archived_at);

    const reviewArchived = await post(`/words/${word.id}/review`, { rating: "good" });
    expect(reviewArchived.status).toBe(409);
    expect(await reviewArchived.json()).toEqual({ error: "ephemeral is archived; restore it to review" });

    const list = (await (await call("/words")).json()) as { words: { word: string; archived_at: string | null }[] };
    expect(list.words.find((w) => w.word === "ephemeral")?.archived_at).toBe(archivedWord.archived_at);

    const restored = await post(`/words/${word.id}/restore`, {});
    expect(restored.status).toBe(200);
    expect(((await restored.json()) as { word: { archived_at: string | null } }).word.archived_at).toBeNull();
    expect((await post(`/words/${word.id}/review`, { rating: "good" })).status).toBe(200);

    expect((await call(`/words/${word.id}`, { method: "DELETE" })).status).toBe(404);
    expect((await post("/words/99999/archive", {})).status).toBe(404);
    expect((await post("/words/99999/restore", {})).status).toBe(404);
  });
});
