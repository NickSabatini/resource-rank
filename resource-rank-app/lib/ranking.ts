const Z_95 = 1.96;

export function wilsonLowerBound(upCount: number, downCount: number) {
  const n = upCount + downCount;
  if (n === 0) return 0;

  const phat = upCount / n;
  const z2 = Z_95 ** 2;

  const numerator =
    phat +
    z2 / (2 * n) -
    Z_95 * Math.sqrt((phat * (1 - phat) + z2 / (4 * n)) / n);
  const denominator = 1 + z2 / n;

  return numerator / denominator;
}

export function hotScore(score: number, createdAt: Date, now = new Date()) {
  const ageHours = Math.max(1, (now.getTime() - createdAt.getTime()) / 36e5);
  return score / Math.pow(ageHours, 1.1);
}
