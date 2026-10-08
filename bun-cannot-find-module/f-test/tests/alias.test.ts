import { expect, test } from "bun:test";
import { sum } from "~/lib/math";
test("sum", () => expect(sum(1, 2)).toBe(3));
