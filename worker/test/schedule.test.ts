import { describe, expect, it } from "vitest";
import { NEW_CARD, review } from "../src/schedule";

const now = new Date("2026-11-15T12:00:00Z");
const days = (date: Date) => (date.getTime() - now.getTime()) / 86_400_000;

describe("review", () => {
  it("schedules a new word by rating", () => {
    expect(days(review(NEW_CARD, "hard", now).due_at)).toBe(1);
    expect(days(review(NEW_CARD, "good", now).due_at)).toBe(1);
    expect(days(review(NEW_CARD, "easy", now).due_at)).toBe(4);
  });

  it("brings a forgotten word back in ten minutes and counts a lapse once it was learned", () => {
    const learned = { interval_days: 10, ease: 2.5, reps: 3, lapses: 0 };
    const again = review(learned, "again", now);
    expect(again.due_at.getTime() - now.getTime()).toBe(10 * 60 * 1000);
    expect(again).toMatchObject({ interval_days: 0, reps: 0, lapses: 1, ease: 2.3 });
    expect(review(NEW_CARD, "again", now).lapses).toBe(0);
  });

  it("grows the interval with each good answer", () => {
    let card = { ...NEW_CARD };
    const intervals = [];
    for (let i = 0; i < 4; i++) {
      card = review(card, "good", now);
      intervals.push(card.interval_days);
    }
    expect(intervals).toEqual([1, 3, 8, 20]);
  });

  it("never lets ease fall below 1.3 or an interval stand still", () => {
    let card = { interval_days: 1, ease: 1.3, reps: 2, lapses: 0 };
    card = review(card, "hard", now);
    expect(card.ease).toBe(1.3);
    expect(card.interval_days).toBe(2);
  });
});
