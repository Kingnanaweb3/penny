# Penny

Every cent accounted for.

Penny is a money auditor that lives inside IBM Bob. She finds where payment code loses money, proves it with a test that fails, fixes it, and then proves the books balance.

I built her for the IBM Bob 2.0 Hackathon on lablab.ai.

## Why I built this

Every shop ends the day the same way. Somebody counts the till. The receipts say one amount, the cash drawer says another, and someone has to find the difference down to the last cent.

In software, nobody counts the till. The tests pass, and everyone goes home.

That is the problem. Money bugs don't crash anything. A customer gets charged twice on a retry. A fee gets taken at two different steps. Tax gets rounded on every line instead of once. Nothing breaks, every test stays green, and weeks later finance finds a gap that nobody can explain.

I have an accounting background, so this one is personal. An accountant would never sign off books without a trial balance. I wanted the same thing for payment code.

## What I did

I built a small payments app called ShopLedger and planted real world money bugs in it on purpose. Then I ran one simulated day of business through it: 500 orders.

All 5 of its tests passed. The books were off by **$43,627.98**.

Then I let Penny loose on it.

## How Penny works

Penny works in five steps, and she stops after every step so a person can check her work before she moves on.

1. **Map the money.** She finds every place money is created, moved, rounded or stored, with the file and line.
2. **Check the rules.** She reads the written fee schedule and checks the code against every rule in it. Not one of the 7 rules held.
3. **Hunt.** She lists every bug, ties each one to a rule, a file and a dollar amount, and splits the missing money into the bugs that caused it. Every account adds up to the cent. No guessing, no made up numbers to force it to balance.
4. **Prove, then fix.** This is the part I care about most. For every bug, she writes a test that fails first and shows it failing. Only then does she make the smallest fix, and then she runs every test again. One bug, one proof, one fix.
5. **Trial balance.** Same day, same 500 orders, same reconciliation, run again.

## The result

| | Before Penny | After Penny |
|---|---|---|
| Money missing from the books | $43,627.98 | $0.00 |
| Tests | 5 passing | 25 passing |

## How I used IBM Bob

Penny is not an app that calls Bob. Penny is Bob, set up for one job. Everything lives in the `.bob` folder, so anyone who opens this project in Bob gets the same auditor.

**A custom mode.** `.bob/custom_modes.yaml` gives Penny her role, her five steps in order, and a rule to stop after each step and wait for me.

**Rules she can't break.** `.bob/rules-penny` only applies in Penny mode. She is not allowed to edit the fee schedule or the reconciliation script, so she can't pass the audit by moving the goalposts. Every fix needs a failing test first.

**Five skills.** One skill per step in `.bob/skills`, each saying what to read, what to run and what file to write.

**Reading documents.** In step 2, Penny read the fee schedule, quoted every rule word for word, and checked the code against each one.

I reviewed her after every step, and I pushed back when something was off. At one point her numbers only balanced because of a $233.73 figure she labeled as rounding noise. I challenged it, she traced it to fees counted twice, and she fixed the report until every account matched to the cent. Another time her first fix rounded in dollars instead of whole cents. I rolled it back and she did it properly.

All my Bob sessions are exported in `bob_sessions`.

## Run it yourself

You only need Node. There is nothing to install.

```bash
git clone https://github.com/Kingnanaweb3/penny
cd penny/sample-app
npm test
npm run simulate
```

You should see 25 tests passing and "Books balance."

To see the original buggy version and the $43,627.98 gap, go back to the main folder and run:

```bash
bash scripts/04_show_before.sh
```

## Where everything is

| Folder | What's inside |
|---|---|
| `.bob` | Penny herself: her mode, her rules and her five skills |
| `penny-report` | Her five reports, one per step |
| `sample-app` | ShopLedger, the payments app she audited |
| `sample-app/tests/penny` | Her tests, one per bug |
| `sample-app/docs/fee-schedule.md` | The money rules she checked the code against |
| `bob_sessions` | My exported Bob sessions and usage |
| `scripts` | The scripts I used to set things up and run the final check |
| `site` | The landing page |

The demo video and its source clips are in the [media release](https://github.com/Kingnanaweb3/penny/releases/tag/media-v1).

## Being honest about the limits

I would rather tell you these myself.

- **The bugs were planted.** I seeded them on purpose to copy common real failures. Penny has not been run on a real production codebase yet.
- **The ledger is simple.** It lives in memory. No database, no real payment provider.
- **She needs written rules.** Without a fee schedule she can still catch rounding and number type bugs, but not broken business rules.
- **She is set up for this project.** Her rules point at this repo's folders. Using her somewhere else means editing the `.bob` folder for now.
- **The last step ran outside Bob.** My 40 Bobcoins ran out while Penny was writing her final test. So I ran the trial balance with `scripts/11_trial_balance.sh`, which follows her trial balance skill and pastes the raw output into the report. The report says this at the top.
- **One bug had no failing step.** The clearing account bug was caused by two other bugs together. Once those were fixed, its test passed on the first run, so there was nothing red to show. I say that instead of faking one.

## What's next

- Point Penny at real open source payment code, like the payment module in Medusa, without telling her where to look.
- Make her work on any repo without editing paths.
- The big idea: every payments team should count the till on their code before every release, the same way finance does on the books.

## Built for

The IBM Bob 2.0 Hackathon by lablab.ai and IBM, September 2026.
