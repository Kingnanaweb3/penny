export class Ledger {
  constructor() {
    this.entries = [];
  }

  post({ ref, from, to, amount, memo = '' }) {
    // Convert naira to whole kobo (integer) on entry. Math.round avoids
    // IEEE-754 drift (e.g. 1612.4999999... rounds to 1612, not truncates).
    const amountKobo = Math.round(amount * 100);
    this.entries.push({ ref, from, to, amountKobo, memo, seq: this.entries.length + 1 });
  }

  // Public interface: returns naira (for callers that expect naira).
  balance(account) {
    let totalKobo = 0;
    for (const e of this.entries) {
      if (e.to   === account) totalKobo += e.amountKobo;
      if (e.from === account) totalKobo -= e.amountKobo;
    }
    return totalKobo / 100;
  }

  // Returns the balance as an integer number of kobo.
  balanceKobo(account) {
    let totalKobo = 0;
    for (const e of this.entries) {
      if (e.to   === account) totalKobo += e.amountKobo;
      if (e.from === account) totalKobo -= e.amountKobo;
    }
    return totalKobo;
  }

  accounts() {
    return [...new Set(this.entries.flatMap((e) => [e.from, e.to]))];
  }
}
