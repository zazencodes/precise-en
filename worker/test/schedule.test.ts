import { describe, expect, it } from "vitest";
import { NEW_CARD, review } from "../src/schedule";

const now = new Date("2026-11-15T12:00:00Z");
const days = (date: Date) => (date.getTime() - now.getTime()) / 86_400_000;

describe("review", () => {
  it("brings a new word back tomorrow when you knew it", () => {
    expect(days(review(NEW_CARD, "good", now).due_at)).toBe(1);
  });

  it("brings a forgotten word back in ten minutes and counts a lapse once it was learned", () => {
    const learned = { interval_days: 10, reps: 3, lapses: 0 };
    const again = review(learned, "again", now);
    expect(again.due_at.getTime() - now.getTime()).toBe(10 * 60 * 1000);
    expect(again).toMatchObject({ interval_days: 0, reps: 0, lapses: 1 });
    expect(review(NEW_CARD, "again", now).lapses).toBe(0);
  });

  it("grows the interval with each good answer", () => {
    let card = { ...NEW_CARD };
    const intervals = [];
    for (let i = 0; i < 5; i++) {
      card = review(card, "good", now);
      intervals.push(card.interval_days);
    }
    expect(intervals).toEqual([1, 3, 8, 20, 50]);
  });

  it("grows a relearned word as fast as a new one, since failing never lowers its ease", () => {
    let card = review({ interval_days: 50, reps: 5, lapses: 0 }, "again", now);
    const intervals = [];
    for (let i = 0; i < 3; i++) {
      card = review(card, "good", now);
      intervals.push(card.interval_days);
    }
    expect(intervals).toEqual([1, 3, 8]);
  });
});
