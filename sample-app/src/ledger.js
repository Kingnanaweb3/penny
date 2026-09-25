export class Ledger {
  constructor() {
    this.entries = [];
  }

  post({ ref, from, to, amount, memo = '' }) {
    this.entries.push({ ref, from, to, amount, memo, seq: this.entries.length + 1 });
  }

  balance(account) {
    let total = 0;
    for (const e of this.entries) {
      if (e.to === account) total += e.amount;
      if (e.from === account) total -= e.amount;
    }
    return total;
  }

  accounts() {
    return [...new Set(this.entries.flatMap((e) => [e.from, e.to]))];
  }
}
