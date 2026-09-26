export class Ledger {
  constructor() {
    this.entries = [];
  }

  post({ ref, from, to, amount, memo = '' }) {
    // Convert dollars to whole cents (integer) on entry. Math.round avoids
    // IEEE-754 drift (e.g. 1612.4999999... rounds to 1612, not truncates).
    const amountCents = Math.round(amount * 100);
    this.entries.push({ ref, from, to, amountCents, memo, seq: this.entries.length + 1 });
  }

  // Public interface: returns dollars (for callers that expect dollars).
  balance(account) {
    let totalCents = 0;
    for (const e of this.entries) {
      if (e.to   === account) totalCents += e.amountCents;
      if (e.from === account) totalCents -= e.amountCents;
    }
    return totalCents / 100;
  }

  // Returns the balance as an integer number of cents.
  balanceCents(account) {
    let totalCents = 0;
    for (const e of this.entries) {
      if (e.to   === account) totalCents += e.amountCents;
      if (e.from === account) totalCents -= e.amountCents;
    }
    return totalCents;
  }

  accounts() {
    return [...new Set(this.entries.flatMap((e) => [e.from, e.to]))];
  }
}
