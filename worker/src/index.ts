// The precise-en API: the word list the apps review and the capture hook adds to.
import { NEW_CARD, RATINGS, type Rating, review } from "./schedule";

export interface Env {
  DB: D1Database;
  TOKEN: string;
}

interface WordRow {
  id: number;
  word: string;
  part_of_speech: string;
  difficulty: Difficulty;
  definition: string;
  phrase: string;
  rewrite: string;
  created_at: string;
  seen_at: string | null;
  due_at: string;
  interval_days: number;
  reps: number;
  lapses: number;
  reviewed_at: string | null;
  archived_at: string | null;
}

const PARTS_OF_SPEECH = ["noun", "verb", "adjective", "adverb"];
const DIFFICULTIES = ["common", "advanced", "rare"] as const;
type Difficulty = (typeof DIFFICULTIES)[number];
const WORD = /^[a-z]+(-[a-z]+)*$/;

class HttpError extends Error {
  constructor(
    readonly status: number,
    message: string,
  ) {
    super(message);
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      authorize(request, env);
      return await route(request, env);
    } catch (error) {
      if (error instanceof HttpError) {
        return Response.json({ error: error.message }, { status: error.status });
      }
      throw error;
    }
  },
} satisfies ExportedHandler<Env>;

function authorize(request: Request, env: Env) {
  if (!env.TOKEN) {
    throw new Error("TOKEN secret is not set");
  }
  const given = new TextEncoder().encode(request.headers.get("Authorization") ?? "");
  const expected = new TextEncoder().encode(`Bearer ${env.TOKEN}`);
  if (given.byteLength !== expected.byteLength || !crypto.subtle.timingSafeEqual(given, expected)) {
    throw new HttpError(401, "unauthorized");
  }
}

async function route(request: Request, env: Env): Promise<Response> {
  const path = new URL(request.url).pathname;
  if (path === "/words") {
    if (request.method === "GET") return listWords(env);
    if (request.method === "POST") return addWord(request, env);
  }
  if (path === "/capture-limits" && request.method === "GET") {
    const { results } = await env.DB.prepare("SELECT * FROM daily_capture").all();
    return Response.json({ limits: results });
  }
  const limitMatch = path.match(/^\/capture-limits\/(common|advanced|rare)$/);
  if (limitMatch && request.method === "PUT") {
    const limit = (await json(request)).daily_limit;
    if (typeof limit !== "number" || !Number.isInteger(limit) || limit < 0 || limit > 99) {
      throw new HttpError(400, "daily_limit must be an integer from 0 to 99");
    }
    await env.DB.prepare("UPDATE capture_limits SET daily_limit = ? WHERE difficulty = ?")
      .bind(limit, limitMatch[1]).run();
    return new Response(null, { status: 204 });
  }
  const match = path.match(/^\/words\/(\d+)\/(review|seen|archive|restore)$/);
  if (match && request.method === "POST") {
    const id = Number(match[1]);
    switch (match[2]) {
      case "review":
        return reviewWord(id, request, env);
      case "seen":
        return markSeen(id, env);
      case "archive":
        return archiveWord(id, env);
      case "restore":
        return restoreWord(id, env);
    }
  }
  throw new HttpError(404, `no route for ${request.method} ${path}`);
}

async function listWords(env: Env): Promise<Response> {
  const { results } = await env.DB.prepare("SELECT * FROM words ORDER BY created_at DESC, id DESC").all<WordRow>();
  return Response.json({ words: results });
}

async function addWord(request: Request, env: Env): Promise<Response> {
  const body = await json(request);
  const word = text(body, "word", 40);
  if (!WORD.test(word)) {
    throw new HttpError(400, `word must be one lowercase English word, got ${JSON.stringify(word)}`);
  }
  const partOfSpeech = text(body, "part_of_speech", 20);
  if (!PARTS_OF_SPEECH.includes(partOfSpeech)) {
    throw new HttpError(400, `part_of_speech must be one of ${PARTS_OF_SPEECH.join(", ")}`);
  }
  const difficulty = text(body, "difficulty", 20);
  if (!DIFFICULTIES.includes(difficulty as Difficulty)) {
    throw new HttpError(400, `difficulty must be one of ${DIFFICULTIES.join(", ")}`);
  }
  const row = await env.DB.prepare(
    `INSERT INTO words (word, part_of_speech, difficulty, definition, phrase, rewrite, created_at, due_at,
       interval_days, reps, lapses)
     SELECT ?, ?, ?, ?, ?, ?, strftime('%Y-%m-%dT%H:%M:%SZ','now'), strftime('%Y-%m-%dT%H:%M:%SZ','now'), ?, ?, ?
     FROM daily_capture WHERE difficulty = ? AND captured_today < daily_limit
     ON CONFLICT (word) DO NOTHING
     RETURNING *`,
  )
    .bind(
      word,
      partOfSpeech,
      difficulty,
      text(body, "definition", 400),
      text(body, "phrase", 400),
      text(body, "rewrite", 600),
      NEW_CARD.interval_days,
      NEW_CARD.reps,
      NEW_CARD.lapses,
      difficulty,
    )
    .first<WordRow>();
  if (!row) {
    if (await env.DB.prepare("SELECT id FROM words WHERE word = ?").bind(word).first()) {
      throw new HttpError(409, `${word} is already saved`);
    }
    throw new HttpError(429, `daily limit reached for ${difficulty} words`);
  }
  return Response.json({ word: row }, { status: 201 });
}

async function reviewWord(id: number, request: Request, env: Env): Promise<Response> {
  const rating = (await json(request)).rating;
  if (!RATINGS.includes(rating as Rating)) {
    throw new HttpError(400, `rating must be one of ${RATINGS.join(", ")}`);
  }
  const existing = await find(id, env);
  if (existing.archived_at !== null) {
    throw new HttpError(409, `${existing.word} is archived; restore it to review`);
  }
  const now = new Date();
  const next = review(existing, rating as Rating, now);
  const row = await env.DB.prepare(
    `UPDATE words SET due_at = ?, interval_days = ?, reps = ?, lapses = ?, reviewed_at = ?,
       seen_at = COALESCE(seen_at, ?)
     WHERE id = ? RETURNING *`,
  )
    .bind(timestamp(next.due_at), next.interval_days, next.reps, next.lapses, timestamp(now), timestamp(now), id)
    .first<WordRow>();
  return Response.json({ word: row });
}

async function markSeen(id: number, env: Env): Promise<Response> {
  await find(id, env);
  const row = await env.DB.prepare("UPDATE words SET seen_at = COALESCE(seen_at, ?) WHERE id = ? RETURNING *")
    .bind(timestamp(new Date()), id)
    .first<WordRow>();
  return Response.json({ word: row });
}

async function archiveWord(id: number, env: Env): Promise<Response> {
  await find(id, env);
  const row = await env.DB.prepare("UPDATE words SET archived_at = COALESCE(archived_at, ?) WHERE id = ? RETURNING *")
    .bind(timestamp(new Date()), id)
    .first<WordRow>();
  return Response.json({ word: row });
}

async function restoreWord(id: number, env: Env): Promise<Response> {
  await find(id, env);
  const row = await env.DB.prepare("UPDATE words SET archived_at = NULL WHERE id = ? RETURNING *")
    .bind(id)
    .first<WordRow>();
  return Response.json({ word: row });
}

async function find(id: number, env: Env): Promise<WordRow> {
  const row = await env.DB.prepare("SELECT * FROM words WHERE id = ?").bind(id).first<WordRow>();
  if (!row) {
    throw new HttpError(404, `no word with id ${id}`);
  }
  return row;
}

async function json(request: Request): Promise<Record<string, unknown>> {
  const body: unknown = await request.json().catch(() => {
    throw new HttpError(400, "body must be JSON");
  });
  if (typeof body !== "object" || body === null || Array.isArray(body)) {
    throw new HttpError(400, "body must be a JSON object");
  }
  return body as Record<string, unknown>;
}

function text(body: Record<string, unknown>, field: string, max: number): string {
  const value = body[field];
  if (typeof value !== "string" || value.trim() === "" || value.length > max) {
    throw new HttpError(400, `${field} must be a non-empty string of at most ${max} characters`);
  }
  return value.trim();
}

// ISO 8601 to the second, which every client parses.
function timestamp(date: Date): string {
  return date.toISOString().replace(/\.\d{3}Z$/, "Z");
}
