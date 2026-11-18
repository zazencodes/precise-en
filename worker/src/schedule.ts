// Spaced repetition graded pass/fail, as Japanese learners run Anki: Again or Good, with one fixed ease
// for every word, so failing a word never shrinks its future intervals.

export const RATINGS = ["again", "good"] as const;
export type Rating = (typeof RATINGS)[number];

export interface Schedule {
  interval_days: number;
  reps: number;
  lapses: number;
}

export const NEW_CARD: Schedule = { interval_days: 0, reps: 0, lapses: 0 };

const EASE = 2.5;
const AGAIN_MINUTES = 10;
const DAY_MS = 24 * 60 * 60 * 1000;

export function review(card: Schedule, rating: Rating, now: Date): Schedule & { due_at: Date } {
  if (rating === "again") {
    return {
      interval_days: 0,
      reps: 0,
      lapses: card.lapses + (card.reps > 0 ? 1 : 0),
      due_at: new Date(now.getTime() + AGAIN_MINUTES * 60 * 1000),
    };
  }
  const interval =
    card.reps === 0
      ? 1
      : card.reps === 1
        ? 3
        : Math.max(card.interval_days + 1, Math.round(card.interval_days * EASE));
  return {
    interval_days: interval,
    reps: card.reps + 1,
    lapses: card.lapses,
    due_at: new Date(now.getTime() + interval * DAY_MS),
  };
}
