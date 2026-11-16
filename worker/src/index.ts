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
  definition: string;
  phrase: string;
  rewrite: string;
  created_at: string;
  seen_at: string | null;
  due_at: string;
  interval_days: number;
  ease: number;
  reps: number;
  lapses: number;
  reviewed_at: string | null;
}

const PARTS_OF_SPEECH = ["noun", "verb", "adjective", "adverb"];
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
  const match = path.match(/^\/words\/(\d+)(\/review|\/seen)?$/);
  if (match) {
    const id = Number(match[1]);
    if (match[2] === "/review" && request.method === "POST") return reviewWord(id, request, env);
    if (match[2] === "/seen" && request.method === "POST") return markSeen(id, env);
    if (match[2] === undefined && request.method === "DELETE") return deleteWord(id, env);
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
  const now = timestamp(new Date());
  const row = await env.DB.prepare(
    `INSERT INTO words (word, part_of_speech, definition, phrase, rewrite, created_at, due_at,
       interval_days, ease, reps, lapses)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON CONFLICT (word) DO NOTHING
     RETURNING *`,
  )
    .bind(
      word,
      partOfSpeech,
      text(body, "definition", 400),
      text(body, "phrase", 400),
      text(body, "rewrite", 600),
      now,
      now,
      NEW_CARD.interval_days,
      NEW_CARD.ease,
      NEW_CARD.reps,
      NEW_CARD.lapses,
    )
    .first<WordRow>();
  if (!row) {
    throw new HttpError(409, `${word} is already saved`);
  }
  return Response.json({ word: row }, { status: 201 });
}

async function reviewWord(id: number, request: Request, env: Env): Promise<Response> {
  const rating = (await json(request)).rating;
  if (!RATINGS.includes(rating as Rating)) {
    throw new HttpError(400, `rating must be one of ${RATINGS.join(", ")}`);
  }
  const now = new Date();
  const next = review(await find(id, env), rating as Rating, now);
  const row = await env.DB.prepare(
    `UPDATE words SET due_at = ?, interval_days = ?, ease = ?, reps = ?, lapses = ?, reviewed_at = ?,
       seen_at = COALESCE(seen_at, ?)
     WHERE id = ? RETURNING *`,
  )
    .bind(timestamp(next.due_at), next.interval_days, next.ease, next.reps, next.lapses, timestamp(now), timestamp(now), id)
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

async function deleteWord(id: number, env: Env): Promise<Response> {
  await find(id, env);
  await env.DB.prepare("DELETE FROM words WHERE id = ?").bind(id).run();
  return new Response(null, { status: 204 });
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
