// Spaced repetition in the style of Anki's SM-2: each rating sets when the word is next due.

export const RATINGS = ["again", "hard", "good", "easy"] as const;
export type Rating = (typeof RATINGS)[number];

export interface Schedule {
  interval_days: number;
  ease: number;
  reps: number;
  lapses: number;
}

export const NEW_CARD: Schedule = { interval_days: 0, ease: 2.5, reps: 0, lapses: 0 };

const MIN_EASE = 1.3;
const AGAIN_MINUTES = 10;
const DAY_MS = 24 * 60 * 60 * 1000;

export function review(card: Schedule, rating: Rating, now: Date): Schedule & { due_at: Date } {
  if (rating === "again") {
    return {
      interval_days: 0,
      ease: Math.max(MIN_EASE, card.ease - 0.2),
      reps: 0,
      lapses: card.lapses + (card.reps > 0 ? 1 : 0),
      due_at: new Date(now.getTime() + AGAIN_MINUTES * 60 * 1000),
    };
  }
  const { interval, ease } = next(card, rating);
  return {
    interval_days: interval,
    ease,
    reps: card.reps + 1,
    lapses: card.lapses,
    due_at: new Date(now.getTime() + interval * DAY_MS),
  };
}

function next(card: Schedule, rating: Exclude<Rating, "again">): { interval: number; ease: number } {
  const grown = (factor: number) => Math.max(card.interval_days + 1, Math.round(card.interval_days * factor));
  switch (rating) {
    case "hard":
      return { interval: card.reps === 0 ? 1 : grown(1.2), ease: Math.max(MIN_EASE, card.ease - 0.15) };
    case "good":
      return { interval: card.reps === 0 ? 1 : card.reps === 1 ? 3 : grown(card.ease), ease: card.ease };
    case "easy":
      return { interval: card.reps === 0 ? 4 : grown(card.ease * 1.3), ease: card.ease + 0.15 };
  }
}
