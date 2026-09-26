#!/usr/bin/env bash
# Rebuilds the whole Penny site in light mode with every section:
# hero, proof band, how it works, the audit, findings, built on Bob, limits, FAQ, footer.
# Replaces site/index.html, site/src/style.css and site/src/main.js.
# Keeps site/public/hero.jpg, package.json and node_modules.
# Run from the penny folder. Your running `npm run dev` picks it up on its own.
set -euo pipefail

if [ ! -f site/package.json ]; then echo "Run scripts/06_setup_site_vite.sh first."; exit 1; fi
if [ ! -f site/public/hero.jpg ]; then echo "Missing site/public/hero.jpg. Run scripts/06_setup_site_vite.sh first."; exit 1; fi
mkdir -p site/src

cat > site/index.html << 'HTML_EOF'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <meta name="theme-color" content="#FAF8F4">
  <title>Penny: your tests pass, your books don't</title>
  <meta name="description" content="Penny is a money auditor inside IBM Bob. She proves every discrepancy in your payment code with a failing test, fixes it, and proves the books balance.">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Geist:wght@100..900&family=Geist+Mono:wght@100..900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/src/style.css">
</head>
<body>

  <header class="nav" id="nav">
    <div class="nav-inner">
      <a href="#top" class="brand" aria-label="Penny home"><span class="coin" aria-hidden="true">P</span>Penny</a>
      <nav class="nav-links" aria-label="Main">
        <a href="#how">How it works</a>
        <a href="#findings">Findings</a>
        <a href="#bob">Built on Bob</a>
        <a href="#limits">Limits</a>
        <a href="https://github.com/Kingnanaweb3/penny" target="_blank" rel="noopener">GitHub</a>
      </nav>
      <a href="#audit" class="nav-cta">See the audit</a>
      <button class="burger" id="burger" aria-label="Open menu" aria-expanded="false" aria-controls="drawer"><span></span></button>
    </div>
  </header>

  <div class="scrim" id="scrim"></div>
  <aside class="drawer" id="drawer" aria-label="Menu" aria-hidden="true">
    <button class="burger drawer-close" id="close" aria-label="Close menu">&times;</button>
    <a href="#how">How it works</a>
    <a href="#findings">Findings</a>
    <a href="#bob">Built on Bob</a>
    <a href="#limits">Limits</a>
    <a href="https://github.com/Kingnanaweb3/penny" target="_blank" rel="noopener">GitHub</a>
    <a href="#audit" class="pill-lg solid">See the audit</a>
  </aside>

  <main id="top">

    <!-- ================= HERO ================= -->
    <section class="hero" aria-labelledby="hero-title">
      <img class="hero-img" src="/hero.jpg" alt="" fetchpriority="high">
      <div class="hero-copy">
        <h1 id="hero-title" class="rise">
          <span class="l1">Your tests pass. Your books don't.</span>
          <span class="l2">Penny finds every cent.</span>
        </h1>
        <p class="lead rise d1">A money auditor that lives inside IBM Bob. She proves every discrepancy in your payment code with a failing test, fixes it, and proves the books balance.</p>
        <div class="ctas rise d2">
          <a href="#audit" class="pill-lg solid">See the audit</a>
          <a href="https://github.com/Kingnanaweb3/penny" class="pill-lg ghost" target="_blank" rel="noopener">Read the code</a>
        </div>
      </div>
    </section>

    <!-- ================= PROOF BAND ================= -->
    <section class="s proof-sec" aria-label="The audit in numbers">
      <div class="wrap">
        <p class="proof-kicker r">One simulated day at ShopLedger, a sample payments app, 500 orders</p>
        <div class="proof r">
          <div><b class="num">$43,627.98</b><p>Missing from the books before Penny</p></div>
          <div><b class="num">5 of 5</b><p>Original tests passing while the books were off</p></div>
          <div><b class="num">0 of 7</b><p>Fee schedule rules enforced at audit</p></div>
          <div><b class="num">7</b><p>Findings, each proven with a failing test</p></div>
        </div>
      </div>
    </section>

    <!-- ================= HOW IT WORKS ================= -->
    <section class="s feat" id="how" aria-labelledby="how-title">
      <div class="wrap">
        <div class="sec-top r">
          <div>
            <span class="chip-label">How it works</span>
            <h2 id="how-title">An auditor's method, run inside your editor.</h2>
          </div>
        </div>

        <div class="feat-row r">
          <div class="stage" aria-hidden="true">
            <div class="glow"></div>
            <div class="mock tilt-l">
              <div class="mock-bar"><i></i><i></i><i></i><span class="mono">02-spec-check.md</span></div>
              <div class="mock-body">
                <div class="mock-title">Fee schedule, rule by rule</div>
                <ul class="rules">
                  <li><span class="rn mono">R1</span>Whole cents only<b class="tag bad">Violated</b></li>
                  <li><span class="rn mono">R2</span>Tax rounded once<b class="tag bad">Violated</b></li>
                  <li><span class="rn mono">R3</span>Fee capped at $20<b class="tag bad">Violated</b></li>
                  <li><span class="rn mono">R4</span>Fee taken once<b class="tag bad">Violated</b></li>
                  <li><span class="rn mono">R5</span>Retries charge once<b class="tag warn">Missing</b></li>
                  <li><span class="rn mono">R6</span>Refunds never exceed charge<b class="tag warn">Missing</b></li>
                  <li><span class="rn mono">R7</span>Clearing nets to zero<b class="tag bad">Violated</b></li>
                </ul>
              </div>
            </div>
            <div class="chip chip-br"><span class="k mono">Enforced at audit</span><span class="v num">0 of 7</span></div>
            <div class="badge badge-r"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5M10 13h6M10 17h6"/></svg></div>
          </div>
          <div class="feat-copy">
            <h3>Every rule in your fee schedule, checked.</h3>
            <p>Penny reads your written money rules, turns each one into a check, and finds the exact file and line that breaks it. On our sample payments app, not one of the seven rules held.</p>
            <div class="feat-ctas">
              <a class="pill-md solid" href="https://github.com/Kingnanaweb3/penny/blob/main/penny-report/02-spec-check.md" target="_blank" rel="noopener">Read the spec check</a>
              <a class="pill-md ghost" href="https://github.com/Kingnanaweb3/penny/blob/main/sample-app/docs/fee-schedule.md" target="_blank" rel="noopener">See the rules</a>
            </div>
          </div>
        </div>

        <div class="feat-row flip r">
          <div class="stage" aria-hidden="true">
            <div class="glow"></div>
            <div class="mock term-mock tilt-r">
              <div class="mock-bar"><i></i><i></i><i></i><span class="mono">p3-idempotency.test.js</span></div>
              <div class="mock-body term mono">
                <div class="ln dim">$ node --test tests/penny/p3-idempotency.test.js</div>
                <div class="ln bad">✖ customer debited once on retry</div>
                <div class="ln dim">&nbsp;&nbsp;expected 107.50</div>
                <div class="ln dim">&nbsp;&nbsp;actual&nbsp;&nbsp;&nbsp;215.00</div>
                <div class="ln sep"></div>
                <div class="ln dim"># fix: remember each idempotency key</div>
                <div class="ln sep"></div>
                <div class="ln good">✔ customer debited once on retry</div>
                <div class="ln dim">&nbsp;&nbsp;tests 12 &nbsp;pass 12 &nbsp;fail 0</div>
              </div>
            </div>
            <div class="chip chip-tl"><span class="k mono">Order</span><span class="v small">Red, then green</span></div>
            <div class="badge badge-l"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 12l4 4L19 6"/></svg></div>
          </div>
          <div class="feat-copy">
            <h3>Every fix starts with a failing test.</h3>
            <p>Penny never patches on a hunch. She writes a test that shows the money going wrong, runs it and lets it fail, makes the smallest fix, then runs the whole suite again. One finding, one proof, one fix.</p>
            <div class="feat-ctas">
              <a class="pill-md solid" href="https://github.com/Kingnanaweb3/penny/blob/main/penny-report/04-fix-log.md" target="_blank" rel="noopener">Read the fix log</a>
              <a class="pill-md ghost" href="https://github.com/Kingnanaweb3/penny/tree/main/sample-app/tests/penny" target="_blank" rel="noopener">See the tests</a>
            </div>
          </div>
        </div>

        <div class="feat-row r">
          <div class="stage" aria-hidden="true">
            <div class="glow"></div>
            <div class="mock tilt-l">
              <div class="mock-bar"><i></i><i></i><i></i><span class="mono">03-findings.md</span></div>
              <div class="mock-body">
                <div class="mock-title">Clearing account, explained</div>
                <div class="decomp">
                  <div class="drow"><span>Retries charged twice <em class="mono">P3</em></span><b class="num">+15,348.51</b></div>
                  <div class="drow"><span>Fee taken at charge <em class="mono">P4</em></span><b class="num">−11,532.69</b></div>
                  <div class="drow"><span>Float noise <em class="mono">P1</em></span><b class="num">0.00</b></div>
                  <div class="drow total"><span>Ledger difference</span><b class="num">+3,815.82</b></div>
                </div>
              </div>
            </div>
            <div class="chip chip-br"><span class="k mono">Unexplained</span><span class="v num good">$0.00</span></div>
            <div class="badge badge-r"><svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 7h16M4 12h16M4 17h10"/></svg></div>
          </div>
          <div class="feat-copy">
            <h3>Every dollar traced to its cause.</h3>
            <p>A total is not an explanation. Penny splits each account's gap into the bugs that caused it, and the parts add up to the cent. No plug figures, nothing left over.</p>
            <div class="feat-ctas">
              <a class="pill-md solid" href="https://github.com/Kingnanaweb3/penny/blob/main/penny-report/03-findings.md" target="_blank" rel="noopener">Read the findings</a>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- ================= THE ARITHMETIC ================= -->
    <section class="s sum-sec" id="audit" aria-labelledby="audit-title">
      <div class="wrap">
        <div class="sec-top r">
          <div>
            <span class="chip-label">The audit</span>
            <h2 id="audit-title">The whole story, in one line.</h2>
            <p class="sub">Same simulated day, same 500 orders, same reconciliation script. The only thing that changed is the code Penny fixed.</p>
          </div>
        </div>
        <div class="sum r">
          <div class="sum-box warn">
            <span class="k">Before Penny</span>
            <b class="v num">$43,627.98</b>
            <p class="n">Off across four accounts, with every original test passing.</p>
          </div>
          <div class="sum-op" aria-hidden="true">&minus;</div>
          <div class="sum-box">
            <span class="k">Seven proven fixes</span>
            <b class="v num">7</b>
            <p class="n">Each one a failing test first, then the smallest change that makes it pass.</p>
          </div>
          <div class="sum-op" aria-hidden="true">=</div>
          <!-- AFTER VALUE: replace "Pending" with the real total from Penny's Phase 5 trial balance -->
          <div class="sum-box pending" id="after-box">
            <span class="k">After Penny</span>
            <b class="v num" id="after-value">Pending</b>
            <p class="n" id="after-note">Filled in from Penny's final trial balance, not before.</p>
          </div>
        </div>
      </div>
    </section>

    <!-- ================= FINDINGS ================= -->
    <section class="s findings" id="findings" aria-labelledby="findings-title">
      <div class="wrap">
        <div class="sec-top r">
          <div>
            <span class="chip-label">Findings</span>
            <h2 id="findings-title">Seven findings. Every one proven.</h2>
            <p class="sub">From Penny's audit of ShopLedger, a sample payments app with deliberately seeded bugs. Pick one to see its impact.</p>
          </div>
          <a class="explore" href="https://github.com/Kingnanaweb3/penny/blob/main/penny-report/03-findings.md" target="_blank" rel="noopener">Explore <span aria-hidden="true">&rsaquo;</span></a>
        </div>

        <div class="fnd r">
          <div class="picker-panel">
            <ul class="picker" id="picker" role="listbox" aria-label="Findings">
              <li role="option"><span class="pid mono">P1</span>Float money</li>
              <li role="option"><span class="pid mono">P2</span>Rounding drift</li>
              <li role="option"><span class="pid mono">P3</span>Retries charged twice</li>
              <li role="option"><span class="pid mono">P4</span>Fee taken twice</li>
              <li role="option"><span class="pid mono">P5</span>Fee cap missing</li>
              <li role="option"><span class="pid mono">P6</span>Refunds over the charge</li>
              <li role="option"><span class="pid mono">P7</span>Clearing never zero</li>
            </ul>
          </div>
          <div class="fnd-side">
            <div class="detail" aria-live="polite">
              <div class="d-head"><span class="d-id mono" id="d-id">P3</span><span id="d-title">Retries charged twice</span><b class="sev Critical" id="d-sev">Critical</b></div>
              <p id="d-desc">A retried charge with the same idempotency key debited the customer a second time.</p>
              <dl>
                <div><dt>Rule broken</dt><dd id="d-rule">Rule 5</dd></div>
                <div><dt>Impact, one day</dt><dd class="num" id="d-imp">$15,582.24</dd></div>
                <div><dt>Who loses</dt><dd id="d-who">Customers</dd></div>
              </dl>
            </div>
            <ul class="feats">
              <li><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M4 20h16M7 16V9M12 16V5M17 16v-4"/></svg>Graded by dollar impact, not by guesswork</li>
              <li><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>Each one proven by a failing test before the fix</li>
              <li><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.7"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>Cited to a rule, a file and a line</li>
              <li><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.7"><path d="M3 12h18M3 6h18M3 18h12"/></svg>Split per account, adding up to the cent</li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- ================= BUILT ON BOB ================= -->
    <section class="s bob-band" id="bob" aria-labelledby="bob-title">
      <div class="wrap">
        <div class="sec-top r">
          <div>
            <h2 id="bob-title">Built into IBM Bob, not bolted on.</h2>
            <p class="sub">Penny is not a script that calls Bob. She is Bob, shaped by a custom mode, her own rules and five skills, working in your repository.</p>
          </div>
          <a class="explore" href="https://github.com/Kingnanaweb3/penny/tree/main/.bob" target="_blank" rel="noopener">Explore <span aria-hidden="true">&rsaquo;</span></a>
        </div>
        <div class="hub r" aria-hidden="true">
          <div class="node n-top">Custom mode</div>
          <div class="node n-left">Mode rules</div>
          <div class="core"><span>Penny</span></div>
          <div class="node n-right">Five skills</div>
          <div class="node n-bottom">Reads documents</div>
        </div>
        <div class="hub-legend r">
          <div><b>Custom mode</b><p>A Bob mode with her own role, five phases, and tool access limited to reading, editing and running tests.</p></div>
          <div><b>Mode rules</b><p>Active only in Penny mode. She may never edit the fee schedule, and every fix needs a failing test first.</p></div>
          <div><b>Five skills</b><p>One per phase: map the money, check the rules, hunt, prove and fix, trial balance.</p></div>
          <div><b>Reads documents</b><p>Penny reads the written fee schedule and checks the code against every rule in it.</p></div>
        </div>
      </div>
    </section>

    <!-- ================= HONEST LIMITS ================= -->
    <section class="s limits-sec" id="limits" aria-labelledby="limits-title">
      <div class="wrap">
        <div class="sec-top r">
          <div>
            <span class="chip-label">Limits</span>
            <h2 id="limits-title">What Penny does not do yet.</h2>
            <p class="sub">Said plainly, so you can judge the rest of the page with it in mind.</p>
          </div>
        </div>
        <div class="limits r">
          <div><b>The bugs were seeded</b><p>ShopLedger's money bugs were planted on purpose to mirror common real failures. Penny has not yet been run against a production payments codebase.</p></div>
          <div><b>A simple ledger</b><p>The sample app keeps its ledger in memory. There is no database, no concurrency and no real payment provider in the loop.</p></div>
          <div><b>It needs written rules</b><p>Policy checks depend on a fee schedule document. Without one, Penny can still catch float and rounding bugs, but not broken business rules.</p></div>
          <div><b>Wired to this repo</b><p>Penny's rules point at ShopLedger's file paths. Using her on another codebase today means editing those paths in the .bob folder.</p></div>
          <div><b>Not a human auditor</b><p>Penny produces evidence for an engineer or finance lead to review. She does not sign off on anyone's books.</p></div>
        </div>
      </div>
    </section>

    <!-- ================= FAQ ================= -->
    <section class="s faq-sec" aria-labelledby="faq-title">
      <div class="wrap-narrow">
        <h2 id="faq-title" class="r">Questions a skeptic would ask.</h2>
        <div class="faq r">
          <details open>
            <summary>Couldn't normal tests catch this?</summary>
            <p>They didn't. ShopLedger's five original tests all passed while the books were $43,627.98 off. Tests check what a developer thought to check. Penny checks the ledger against the written rules, then proves each gap with a new test.</p>
          </details>
          <details>
            <summary>Why not just ask Bob in Agent mode?</summary>
            <p>Agent mode will happily fix code. Penny's mode adds the discipline an audit needs: she cannot edit the fee schedule or the reconciliation script, she must show a failing test before any fix, and she stops after every phase so a person reviews the evidence.</p>
          </details>
          <details>
            <summary>Does Penny change my code without asking?</summary>
            <p>No. She works one phase at a time and waits for you to say continue. Fixes go one finding at a time, each with its own test and an entry in the fix log.</p>
          </details>
          <details>
            <summary>How do I know the numbers are real?</summary>
            <p>Everything on this page comes from files in the repository: the reconciliation script, Penny's reports and the test suite. Clone it, run npm test and npm run simulate, and you get the same numbers.</p>
          </details>
        </div>
      </div>
    </section>
  </main>

  <!-- ================= FOOTER ================= -->
  <footer class="foot">
    <div class="foot-inner">
      <div class="foot-brand">
        <a href="#top" class="brand"><span class="coin" aria-hidden="true">P</span>Penny</a>
        <p>Every cent accounted for.</p>
      </div>
      <div class="foot-cols">
        <div><b>Product</b><a href="#how">How it works</a><a href="#audit">The audit</a><a href="#findings">Findings</a><a href="#limits">Limits</a></div>
        <div><b>Evidence</b><a href="https://github.com/Kingnanaweb3/penny/tree/main/penny-report" target="_blank" rel="noopener">Reports</a><a href="https://github.com/Kingnanaweb3/penny/tree/main/sample-app/tests" target="_blank" rel="noopener">Tests</a><a href="https://github.com/Kingnanaweb3/penny/tree/main/bob_sessions" target="_blank" rel="noopener">Bob sessions</a></div>
        <div><b>Built with</b><a href="https://github.com/Kingnanaweb3/penny/tree/main/.bob" target="_blank" rel="noopener">IBM Bob 2.0</a><a href="https://github.com/Kingnanaweb3/penny" target="_blank" rel="noopener">GitHub</a></div>
      </div>
    </div>
    <div class="foot-img" aria-hidden="true"><img src="/hero.jpg" alt="" loading="lazy"></div>
    <p class="foot-note">Built for the IBM Bob 2.0 Hackathon, September 2026.</p>
  </footer>

  <script type="module" src="/src/main.js"></script>
</body>
</html>
HTML_EOF

cat > site/src/style.css << 'CSS_EOF'
/* Penny landing page.
   Structure, type scale, spacing and components follow the landing page design system.
   Color is reskinned to a light, warm palette taken from the hero painting. */
:root {
  color-scheme: light;

  --bg:     #FAF8F4;
  --panel:  #F1EEE8;
  --ink:    #1A1917;
  --muted:  #67635B;
  --faint:  #9C978E;
  --line:   rgba(26,25,23,.10);
  --accent: #4A63B0;   /* dusk blue from the top of the sky */

  --good: #2E8B57;
  --warn: #B26B12;
  --bad:  #B8412F;

  --card: #FFFFFF;
  --shadow: 0 1px 2px rgba(26,25,23,.04), 0 12px 32px -12px rgba(26,25,23,.14);

  --step--2: clamp(10px, 0.55vw + 8.4px, 11.5px);
  --step--1: clamp(11.5px, 0.6vw + 9.7px, 12.5px);
  --step-0:  clamp(12.5px, 0.7vw + 10.5px, 13.5px);
  --step-1:  clamp(13.5px, 0.8vw + 11.2px, 15px);
  --step-2:  clamp(15px, 1vw + 12.2px, 17px);
  --step-3:  clamp(18px, 1.6vw + 13.8px, 22px);
  --step-4:  clamp(21px, 2.4vw + 14.6px, 28px);
  --step-5:  clamp(24px, 3.4vw + 15px, 34px);

  --sans: 'Geist', -apple-system, system-ui, sans-serif;
  --mono: 'Geist Mono', ui-monospace, 'SF Mono', monospace;

  --section: clamp(88px, 13vw, 170px);
}

*, *::before, *::after { box-sizing: border-box; }
html { scroll-padding-top: 72px; -webkit-text-size-adjust: 100%; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--ink);
  font-family: var(--sans);
  font-weight: 400;
  font-feature-settings: "cv02", "cv03", "cv04", "cv11";
  letter-spacing: -0.4px;
  font-optical-sizing: auto;
  font-synthesis: none;
  -webkit-font-smoothing: antialiased;
  overflow-x: hidden;
}
a { color: inherit; text-decoration: none; }
img { max-width: 100%; display: block; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; border-radius: 8px; }

.num  { font-variant-numeric: tabular-nums; letter-spacing: -0.5px; }
.mono { font-family: var(--mono); font-size: 0.92em; letter-spacing: 0; }

section.s { padding-inline: 16px; }
@media (min-width: 640px)  { section.s { padding-inline: 32px } }
@media (min-width: 1024px) { section.s { padding-inline: 30px } }
.wrap        { max-width: 1160px; margin: 0 auto; }
.wrap-narrow { max-width: 860px;  margin: 0 auto; }

h2 {
  margin: 0; font-size: clamp(30px, 4.2vw, 52px); font-weight: 400;
  line-height: 1.04; letter-spacing: -1.4px; text-wrap: balance;
}

/* ================= NAV ================= */
.nav {
  position: fixed; inset-inline: 0; top: 0; z-index: 50;
  height: 56px; display: flex; align-items: center;
  padding-inline: 16px;
  padding-top: env(safe-area-inset-top, 0px);
  box-sizing: content-box;
  background: transparent; border-bottom: 1px solid transparent;
  transition: background 200ms, border-color 200ms;
}
@media (min-width: 640px)  { .nav { padding-inline: 32px } }
@media (min-width: 1024px) { .nav { padding-inline: 30px; height: 64px; } }
.nav.stuck {
  background: rgba(250,248,244,.84);
  backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px);
  border-bottom-color: var(--line);
}
.nav-inner { width: 100%; max-width: 1160px; margin: 0 auto; display: flex; align-items: center; justify-content: space-between; gap: 24px; }
.brand { display: inline-flex; align-items: center; gap: 10px; font-size: var(--step-3); font-weight: 480; letter-spacing: -0.6px; }
.brand .coin {
  width: 22px; height: 22px; border-radius: 50%; border: 1.5px solid currentColor;
  display: grid; place-items: center; font-size: 11px; font-weight: 600; letter-spacing: 0;
}
.nav-links { display: none; align-items: center; gap: 2px; }
.nav-links a {
  display: inline-flex; align-items: center; height: 34px; padding-inline: 11px; border-radius: 999px;
  font-size: var(--step-1); font-weight: 450; color: rgba(26,25,23,.7);
  border: 1px solid transparent; transition: color 160ms, border-color 160ms, background 160ms;
}
.nav-links a:hover { color: var(--ink); border-color: var(--line); background: rgba(255,255,255,.5); }
.nav-cta {
  display: none; align-items: center; height: 38px; padding: 0 18px; border-radius: 999px;
  font-size: var(--step-1); font-weight: 500; background: var(--ink); color: var(--bg);
  transition: transform 180ms, opacity 180ms;
}
.nav-cta:hover { transform: translateY(-1px); opacity: .9; }

.burger {
  width: 40px; height: 40px; border-radius: 999px; border: 1px solid var(--line);
  background: rgba(255,255,255,.55); color: var(--ink);
  display: grid; place-items: center; cursor: pointer; padding: 0; font-size: 22px; font-weight: 300;
  backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
}
.burger span, .burger span::before, .burger span::after {
  display: block; width: 16px; height: 1.5px; background: var(--ink); border-radius: 2px; position: relative; content: '';
}
.burger span::before { position: absolute; top: -5px; }
.burger span::after  { position: absolute; top: 5px; }

.scrim {
  position: fixed; inset: 0; z-index: 60; background: rgba(26,25,23,.25);
  backdrop-filter: blur(6px); -webkit-backdrop-filter: blur(6px);
  opacity: 0; pointer-events: none; transition: opacity 220ms;
}
.drawer {
  position: fixed; top: 0; right: 0; bottom: 0; z-index: 70;
  width: min(84vw, 340px); background: var(--bg); border-left: 1px solid var(--line);
  padding: calc(14px + env(safe-area-inset-top, 0px)) 22px calc(22px + env(safe-area-inset-bottom, 0px));
  transform: translateX(100%); transition: transform 280ms cubic-bezier(.16,1,.3,1);
  display: flex; flex-direction: column; overflow-y: auto;
}
.drawer a:not(.pill-lg) { padding: 16px 4px; font-size: 18px; font-weight: 450; border-bottom: 1px solid var(--line); }
.drawer .pill-lg { margin-top: 24px; justify-content: center; }
.drawer-close { align-self: flex-end; margin-bottom: 8px; }
body.open .scrim { opacity: 1; pointer-events: auto; }
body.open .drawer { transform: none; }
body.open { overflow: hidden; }

@media (min-width: 861px) {
  .nav .nav-links { display: flex; }
  .nav .nav-cta { display: inline-flex; }
  .nav .burger { display: none; }
}

/* ================= BUTTONS ================= */
.pill-lg {
  display: inline-flex; align-items: center; justify-content: center; gap: 9px; height: 52px; padding: 0 26px;
  border-radius: 999px; font-size: 16px; font-weight: 530;
  transition: transform 180ms, opacity 180ms, background 180ms;
}
.pill-lg.solid { background: var(--ink); color: var(--bg); }
.pill-lg.solid:hover { transform: translateY(-1px); opacity: .9; }
.pill-lg.ghost {
  background: rgba(255,255,255,.6); color: var(--ink); border: 1px solid rgba(26,25,23,.14);
  backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
}
.pill-lg.ghost:hover { transform: translateY(-1px); background: rgba(255,255,255,.9); }

.pill-md {
  display: inline-flex; align-items: center; height: 42px; padding: 0 18px; border-radius: 999px;
  font-size: var(--step-1); font-weight: 500; transition: transform 180ms, opacity 180ms, background 180ms;
}
.pill-md.solid { background: var(--ink); color: var(--bg); }
.pill-md.solid:hover { transform: translateY(-1px); opacity: .9; }
.pill-md.ghost { border: 1px solid rgba(26,25,23,.16); background: var(--card); }
.pill-md.ghost:hover { transform: translateY(-1px); }

/* ================= HERO ================= */
.hero {
  position: relative; min-height: max(640px, 100svh);
  display: flex; justify-content: center; align-items: flex-start;
  padding: calc(56px + env(safe-area-inset-top, 0px) + clamp(56px, 13vh, 150px)) 16px 0;
  overflow: hidden; isolation: isolate; text-align: center;
}
.hero-img {
  position: absolute; inset: 0; z-index: -2; width: 100%; height: 100%;
  object-fit: cover; object-position: 60% 100%;
  transform: scale(1.05); animation: settle 2.6s cubic-bezier(.16,1,.3,1) forwards;
}
.hero::before {
  content: ''; position: absolute; inset: 0; z-index: -1;
  background:
    radial-gradient(ellipse 58% 42% at 50% 32%, rgba(250,248,244,.58) 0%, rgba(250,248,244,.22) 55%, rgba(250,248,244,0) 78%),
    linear-gradient(to bottom, rgba(250,248,244,.3) 0%, rgba(250,248,244,0) 14%);
}
.hero::after {
  content: ''; position: absolute; inset: auto 0 0 0; height: 18%; z-index: -1;
  background: linear-gradient(to bottom, rgba(250,248,244,0), var(--bg));
}
.hero-copy { max-width: 1100px; }
h1 { margin: 0; font-size: 38px; font-weight: 400; line-height: 1.02; letter-spacing: -1px; text-wrap: balance; }
h1 span { display: block; }
h1 .l2 { color: rgba(26,25,23,.58); }
@media (min-width: 640px)  { h1 { font-size: 52px; letter-spacing: -1.6px; } }
@media (min-width: 768px)  { h1 { font-size: 62px; letter-spacing: -2px; } }
@media (min-width: 1024px) { h1 { font-size: 74px; letter-spacing: -2.6px; line-height: 0.98; } h1 .l1 { white-space: nowrap; } }
.lead {
  margin: 24px auto 0; font-size: 16px; line-height: 1.7; color: rgba(26,25,23,.78);
  max-width: 38rem; text-wrap: balance;
}
@media (min-width: 640px) { .lead { font-size: 18px } }
.ctas { display: flex; flex-wrap: wrap; justify-content: center; gap: 12px; margin-top: 32px; }
@media (max-width: 420px) { .ctas .pill-lg { flex: 1 1 100%; } }

/* ================= SHARED SECTION PIECES ================= */
.sec-top { display: flex; justify-content: space-between; align-items: flex-end; gap: 24px; margin-bottom: clamp(40px, 6vw, 72px); }
.sec-top h2 { max-width: 17ch; }
.sub { margin: 16px 0 0; font-size: var(--step-2); line-height: 1.65; color: var(--muted); max-width: 50ch; }
.chip-label {
  display: inline-block; margin-bottom: 16px; padding: 4px 11px; border-radius: 999px;
  font-size: var(--step--1); font-weight: 480; color: var(--muted);
  border: 1px solid var(--line); background: var(--card);
}
.explore {
  flex: none; display: inline-flex; align-items: center; gap: 6px; height: 36px; padding: 0 14px;
  border-radius: 999px; border: 1px solid var(--line); background: var(--card);
  font-size: var(--step-0); font-weight: 500; box-shadow: 0 1px 2px rgba(26,25,23,.05);
  transition: transform 160ms;
}
.explore:hover { transform: translateY(-1px); }
.explore span { font-size: 16px; line-height: 1; }
@media (max-width: 640px) { .sec-top { flex-direction: column; align-items: flex-start; } }

/* ================= PROOF BAND ================= */
.proof-sec { padding-top: clamp(40px, 6vw, 80px); }
.proof-kicker { margin: 0 0 22px; font-size: var(--step--1); color: var(--faint); text-align: center; }
.proof { border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); display: grid; grid-template-columns: 1fr 1fr; }
@media (min-width: 900px) { .proof { grid-template-columns: repeat(4, 1fr); } }
.proof div { padding: clamp(24px, 3vw, 40px) clamp(14px, 2.2vw, 32px); border-right: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.proof div:nth-child(2n) { border-right: 0; }
.proof div:nth-child(n+3) { border-bottom: 0; }
@media (min-width: 900px) {
  .proof div { border-bottom: 0; border-right: 1px solid var(--line); }
  .proof div:nth-child(2n) { border-right: 1px solid var(--line); }
  .proof div:last-child { border-right: 0; }
}
.proof b { display: block; font-size: clamp(26px, 4vw, 42px); font-weight: 400; letter-spacing: -1px; line-height: 1; }
.proof div:first-child b { color: var(--warn); }
.proof p { margin: 12px 0 0; font-size: 13.5px; line-height: 1.5; color: var(--muted); }

/* ================= HOW IT WORKS ================= */
.feat { padding-top: var(--section); }
.feat-row { display: grid; gap: clamp(28px, 5vw, 72px); align-items: center; padding-block: clamp(28px, 6vw, 72px); }
@media (min-width: 900px) {
  .feat-row { grid-template-columns: 1.1fr 1fr; }
  .feat-row.flip { grid-template-columns: 1fr 1.1fr; }
  .feat-row.flip .stage { order: 2; }
}
.feat-copy h3 { margin: 0; font-size: clamp(26px, 3vw, 38px); font-weight: 400; line-height: 1.1; letter-spacing: -1px; text-wrap: balance; max-width: 22ch; }
.feat-copy p { margin: 18px 0 0; font-size: var(--step-2); line-height: 1.7; color: var(--muted); max-width: 46ch; }
.feat-ctas { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 28px; }

.stage {
  position: relative; perspective: 1600px;
  padding: clamp(28px, 4vw, 48px) clamp(14px, 3vw, 40px);
  border-radius: 24px; background: var(--panel);
}
.glow {
  position: absolute; inset: 14% 10%; z-index: 0; border-radius: 50%;
  background: radial-gradient(closest-side, rgba(233,170,110,.45), rgba(233,170,110,0));
  filter: blur(30px);
}
.mock {
  position: relative; z-index: 1; background: var(--card);
  border: 1px solid var(--line); border-radius: 16px; overflow: hidden;
  box-shadow: 0 40px 70px -40px rgba(26,25,23,.45), 0 2px 6px rgba(26,25,23,.05);
  transition: transform 700ms cubic-bezier(.16,1,.3,1);
}
.tilt-l { transform: rotateY(10deg) rotateX(4deg) rotateZ(-1deg); }
.tilt-r { transform: rotateY(-10deg) rotateX(4deg) rotateZ(1deg); }
.stage:hover .mock { transform: none; }
@media (max-width: 899px) { .tilt-l, .tilt-r { transform: none; } }

.mock-bar { height: 32px; display: flex; align-items: center; gap: 7px; padding: 0 14px; background: #F6F4F0; border-bottom: 1px solid var(--line); }
.mock-bar i { width: 9px; height: 9px; border-radius: 50%; background: #DDD9D2; }
.mock-bar span { margin-left: 8px; font-size: 11.5px; color: var(--faint); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.mock-body { padding: clamp(14px, 2vw, 22px); }
.mock-title { font-size: var(--step-1); font-weight: 500; margin-bottom: 12px; }

.rules { list-style: none; margin: 0; padding: 0; display: grid; gap: 3px; }
.rules li { display: grid; grid-template-columns: 30px 1fr auto; align-items: center; gap: 8px; padding: 8px 10px; border-radius: 10px; font-size: var(--step-0); color: var(--muted); background: #F8F7F4; }
.rules .rn { color: var(--faint); font-size: 11px; }
.tag { font-size: 11px; font-weight: 500; padding: 3px 9px; border-radius: 999px; letter-spacing: 0; white-space: nowrap; }
.tag.bad  { color: var(--bad);  background: rgba(184,65,47,.09); }
.tag.warn { color: var(--warn); background: rgba(178,107,18,.10); }

.term-mock { background: #16161A; border-color: rgba(0,0,0,.2); }
.term-mock .mock-bar { background: #1F1F24; border-bottom-color: rgba(255,255,255,.06); }
.term-mock .mock-bar i { background: #3A3A40; }
.term { font-size: 12px; line-height: 1.9; color: #D9D6CF; }
.term .ln { white-space: pre-wrap; word-break: break-word; }
.term .dim  { color: #8E8A82; }
.term .bad  { color: #F08A7B; }
.term .good { color: #6FD39B; }
.term .sep  { height: 6px; }

.decomp { display: grid; gap: 3px; }
.drow { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; padding: 10px 10px; border-radius: 10px; font-size: var(--step-0); color: var(--muted); background: #F8F7F4; }
.drow em { font-style: normal; font-size: 11px; color: var(--faint); margin-left: 6px; }
.drow b { font-weight: 450; color: var(--ink); }
.drow.total { background: transparent; border-top: 1px solid var(--line); border-radius: 0; margin-top: 6px; padding-top: 14px; color: var(--ink); }

.chip {
  position: absolute; z-index: 2; display: grid; gap: 4px; padding: 12px 16px; border-radius: 14px;
  background: rgba(255,255,255,.92); border: 1px solid var(--line); box-shadow: var(--shadow);
  backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px);
}
.chip .k { font-size: 10px; letter-spacing: .06em; text-transform: uppercase; color: var(--faint); }
.chip .v { font-size: clamp(20px, 2.6vw, 30px); font-weight: 400; letter-spacing: -1px; line-height: 1; }
.chip .v.small { font-size: var(--step-3); letter-spacing: -0.5px; }
.chip .v.good { color: var(--good); }
.chip-br { right: 10px; bottom: 10px; }
.chip-tl { left: 10px; top: 8px; }
@media (max-width: 899px) {
  .stage { display: flex; flex-direction: column; }
  .chip { position: relative; inset: auto; align-self: flex-start; margin-top: 14px; }
  .chip-tl { order: 2; }
}

.badge {
  position: absolute; z-index: 2; top: 50%; width: 50px; height: 50px; border-radius: 50%;
  display: grid; place-items: center; color: var(--accent);
  background: var(--card); border: 1px solid var(--line);
  box-shadow: 0 0 0 6px rgba(74,99,176,.07), var(--shadow);
}
.badge-r { right: -12px; transform: translateY(-50%); }
.badge-l { left: -12px; transform: translateY(-50%); }
@media (max-width: 899px) { .badge { display: none; } }

/* ================= THE ARITHMETIC ================= */
.sum-sec { padding-top: var(--section); }
.sum { display: grid; gap: 12px; }
@media (min-width: 860px) { .sum { grid-template-columns: 1fr auto 1fr auto 1fr; } }
.sum-box { border: 1px solid var(--line); border-radius: 16px; padding: clamp(20px, 2.2vw, 28px); background: var(--card); box-shadow: 0 1px 2px rgba(26,25,23,.04); }
.sum-box .k { font-family: var(--mono); font-size: 10.5px; letter-spacing: .08em; text-transform: uppercase; color: var(--faint); }
.sum-box .v { display: block; margin-top: 14px; font-size: clamp(30px, 3.6vw, 42px); font-weight: 400; letter-spacing: -1.2px; }
.sum-box .n { margin: 12px 0 0; font-size: 13.5px; line-height: 1.55; color: var(--muted); }
.sum-box.warn { background: rgba(178,107,18,.05); border-color: rgba(178,107,18,.22); }
.sum-box.warn .v { color: var(--warn); }
.sum-box.good { background: rgba(46,139,87,.06); border-color: rgba(46,139,87,.24); }
.sum-box.good .v { color: var(--good); }
.sum-box.pending { border-style: dashed; }
.sum-box.pending .v { color: var(--faint); }
.sum-op { display: grid; place-items: center; color: var(--faint); font-size: 26px; font-weight: 300; }
@media (max-width: 859px) { .sum-op { height: 22px; } }

/* ================= FINDINGS ================= */
.findings { padding-top: var(--section); }
.fnd { display: grid; gap: clamp(20px, 4vw, 56px); align-items: center; }
@media (min-width: 900px) { .fnd { grid-template-columns: 1fr 1fr; } }
.picker-panel {
  border-radius: 20px; background: var(--panel);
  min-height: clamp(360px, 44vw, 500px); width: 100%;
  display: grid; place-items: center; overflow: hidden; padding: 28px 0;
}
.picker { list-style: none; margin: 0; padding: 0; display: grid; gap: 6px; width: min(80%, 330px); }
.picker li {
  display: flex; align-items: center; gap: 10px; padding: 11px 14px; border-radius: 12px; cursor: pointer;
  font-size: var(--step-1); color: var(--muted); background: rgba(255,255,255,.55); border: 1px solid transparent;
  transition: opacity 260ms, transform 260ms, background 260ms, color 260ms, box-shadow 260ms;
}
.picker .pid { font-size: 11px; color: var(--faint); width: 22px; }
.picker li[data-d="0"] { opacity: 1; transform: scale(1.06); background: var(--card); color: var(--ink); border-color: var(--line); box-shadow: var(--shadow); }
.picker li[data-d="0"] .pid { color: var(--accent); }
.picker li[data-d="1"] { opacity: .85; transform: scale(.98); }
.picker li[data-d="2"] { opacity: .55; transform: scale(.95); }
.picker li[data-d="3"] { opacity: .32; transform: scale(.92); }
.picker li[data-d="4"], .picker li[data-d="5"], .picker li[data-d="6"] { opacity: .18; transform: scale(.9); }
.picker li:hover { color: var(--ink); opacity: 1; }

.detail { border-radius: 16px; padding: clamp(18px, 2vw, 24px); background: var(--panel); }
.d-head { display: flex; align-items: center; flex-wrap: wrap; gap: 8px 10px; font-size: var(--step-2); font-weight: 500; }
.d-id { font-size: 12px; color: var(--accent); }
.sev { margin-left: auto; font-size: 11px; font-weight: 500; padding: 3px 9px; border-radius: 999px; }
.sev.Critical { color: var(--bad);  background: rgba(184,65,47,.10); }
.sev.High     { color: var(--warn); background: rgba(178,107,18,.10); }
.sev.Low      { color: var(--muted); background: rgba(26,25,23,.06); }
.detail p { margin: 10px 0 0; font-size: var(--step-0); line-height: 1.6; color: var(--muted); }
.detail dl { margin: 16px 0 0; display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; border-top: 1px solid var(--line); padding-top: 14px; }
.detail dt { font-size: 11px; color: var(--faint); }
.detail dd { margin: 4px 0 0; font-size: var(--step-1); }
@media (max-width: 420px) { .detail dl { grid-template-columns: 1fr 1fr; } }
.feats { list-style: none; margin: 14px 0 0; padding: 0; display: grid; }
.feats li { display: flex; align-items: center; gap: 12px; padding: 13px 4px; font-size: var(--step-1); color: var(--muted); }
.feats svg { color: var(--faint); flex: none; }

/* ================= BUILT ON BOB ================= */
.bob-band {
  margin-top: var(--section);
  padding-top: clamp(72px, 10vw, 128px); padding-bottom: clamp(72px, 10vw, 128px);
  background: var(--panel);
}
.hub {
  --gx: clamp(28px, 5vw, 64px); --gy: clamp(28px, 4vw, 48px);
  display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; justify-items: center;
  column-gap: var(--gx); row-gap: var(--gy); margin-inline: auto; max-width: 980px;
}
.node {
  position: relative; padding: 12px 22px; border-radius: 999px; white-space: nowrap;
  font-size: var(--step-1); font-weight: 480; background: rgba(26,25,23,.05);
}
.n-top { grid-column: 2; grid-row: 1; }
.n-left { grid-column: 1; grid-row: 2; justify-self: end; }
.core { grid-column: 2; grid-row: 2; }
.n-right { grid-column: 3; grid-row: 2; justify-self: start; }
.n-bottom { grid-column: 2; grid-row: 3; }
.node::after { content: ''; position: absolute; background: rgba(26,25,23,.18); }
.n-top::after    { left: 50%; top: 100%; width: 1px; height: var(--gy); }
.n-bottom::after { left: 50%; bottom: 100%; width: 1px; height: var(--gy); }
.n-left::after   { top: 50%; left: 100%; height: 1px; width: var(--gx); }
.n-right::after  { top: 50%; right: 100%; height: 1px; width: var(--gx); }
.core {
  position: relative; overflow: hidden;
  width: clamp(240px, 30vw, 380px); height: clamp(96px, 11vw, 136px); border-radius: 999px;
  display: grid; place-items: center;
  background: url('/hero.jpg') 60% 72% / cover no-repeat;
  box-shadow: 0 0 0 8px rgba(255,255,255,.7), 0 0 0 9px rgba(26,25,23,.06), 0 0 0 18px rgba(255,255,255,.35), 0 30px 60px -28px rgba(26,25,23,.5);
}
.core::before { content: ''; position: absolute; inset: 0; background: linear-gradient(to bottom, rgba(0,0,0,0), rgba(0,0,0,.18)); }
.core span { position: relative; font-size: clamp(30px, 3.6vw, 46px); font-weight: 450; letter-spacing: -1.4px; color: #fff; text-shadow: 0 2px 18px rgba(0,0,0,.3); }
@media (max-width: 759px) {
  .hub { grid-template-columns: 1fr 1fr; gap: 12px; }
  .core { grid-column: 1 / -1; grid-row: 1; width: 100%; margin-bottom: 14px; }
  .n-top, .n-left, .n-right, .n-bottom { grid-column: auto; grid-row: auto; justify-self: stretch; text-align: center; white-space: normal; }
  .node::after { display: none; }
}
.hub-legend { margin-top: clamp(56px, 8vw, 96px); display: grid; border-top: 1px solid var(--line); }
@media (min-width: 760px) { .hub-legend { grid-template-columns: repeat(4, 1fr); } }
.hub-legend div { padding: 22px 20px 4px 0; }
@media (min-width: 760px) { .hub-legend div + div { padding-left: 20px; border-left: 1px solid var(--line); } }
.hub-legend b { font-weight: 500; font-size: var(--step-1); }
.hub-legend p { margin: 8px 0 0; font-size: var(--step-0); line-height: 1.65; color: var(--muted); }

/* ================= LIMITS ================= */
.limits-sec { padding-top: var(--section); }
.limits { border-top: 1px solid var(--line); }
.limits div { padding: 22px 0; border-bottom: 1px solid var(--line); display: grid; gap: 6px; }
@media (min-width: 760px) { .limits div { grid-template-columns: 260px 1fr; gap: 32px; align-items: baseline; } }
.limits b { font-weight: 480; font-size: 15px; }
.limits p { margin: 0; font-size: 14.5px; line-height: 1.65; color: var(--muted); max-width: 64ch; }

/* ================= FAQ ================= */
.faq-sec { padding-top: var(--section); padding-bottom: var(--section); }
.faq-sec h2 { margin-bottom: clamp(32px, 5vw, 56px); }
.faq { border-top: 1px solid var(--line); }
.faq details { border-bottom: 1px solid var(--line); }
.faq summary { list-style: none; cursor: pointer; padding: 22px 40px 22px 0; position: relative; font-size: 16px; font-weight: 480; }
.faq summary::-webkit-details-marker { display: none; }
.faq summary::after { content: '+'; position: absolute; right: 6px; top: 19px; color: var(--faint); font-size: 22px; font-weight: 300; }
.faq details[open] summary::after { content: '\2212'; }
.faq p { margin: 0; padding: 0 0 24px; font-size: 14.5px; line-height: 1.75; color: var(--muted); max-width: 70ch; }

/* ================= FOOTER ================= */
.foot { position: relative; background: var(--bg); overflow: hidden; }
.foot-inner {
  position: relative; z-index: 2; max-width: 1160px; margin: 0 auto;
  padding: 56px 16px 0; display: grid; gap: 36px; border-top: 1px solid var(--line);
}
@media (min-width: 640px) { .foot-inner { padding-inline: 32px; } }
@media (min-width: 1024px) { .foot-inner { padding-inline: 30px; } }
@media (min-width: 860px) { .foot-inner { grid-template-columns: 1fr 2fr; } }
.foot-brand p { margin: 12px 0 0; color: var(--muted); font-size: var(--step-1); }
.foot-cols { display: grid; grid-template-columns: repeat(2, 1fr); gap: 28px; }
@media (min-width: 560px) { .foot-cols { grid-template-columns: repeat(3, 1fr); } }
.foot-cols div { display: grid; gap: 10px; align-content: start; }
.foot-cols b { font-weight: 500; font-size: var(--step-1); margin-bottom: 4px; }
.foot-cols a { font-size: var(--step-0); color: var(--muted); transition: color 160ms; }
.foot-cols a:hover { color: var(--ink); }
.foot-img { position: relative; margin-top: -40px; height: clamp(220px, 32vw, 420px); }
.foot-img img { width: 100%; height: 100%; object-fit: cover; object-position: 60% 80%; }
.foot-img::before { content: ''; position: absolute; inset: 0; z-index: 1; background: linear-gradient(to bottom, var(--bg) 0%, rgba(250,248,244,.4) 45%, rgba(250,248,244,0) 70%); }
.foot-note { position: absolute; left: 0; right: 0; bottom: max(16px, env(safe-area-inset-bottom, 0px)); z-index: 2; margin: 0; text-align: center; font-size: var(--step--1); color: rgba(255,255,255,.9); text-shadow: 0 1px 8px rgba(0,0,0,.35); }

/* ================= MOTION ================= */
/* Hero: one load moment. Everything else: skill section 15 reveal on scroll. */
.rise { opacity: 0; transform: translateY(14px); animation: rise .9s cubic-bezier(.16,1,.3,1) .15s forwards; }
.rise.d1 { animation-delay: .27s; }
.rise.d2 { animation-delay: .39s; }
@keyframes rise { to { opacity: 1; transform: none; } }
@keyframes settle { to { transform: scale(1); } }

.r { opacity: 0; transform: translateY(18px); transition: opacity .7s cubic-bezier(.16,1,.3,1), transform .7s cubic-bezier(.16,1,.3,1); }
.r.in { opacity: 1; transform: none; }
.r-1 { transition-delay: .06s; }
.r-2 { transition-delay: .12s; }

@media (prefers-reduced-motion: reduce) {
  .rise, .hero-img, .r { opacity: 1; transform: none; animation: none; transition: none; }
  .mock { transition: none; }
}
CSS_EOF

cat > site/src/main.js << 'JS_EOF'
// ---------- Nav: solid after 24px of scroll ----------
const nav = document.getElementById('nav');
const onScroll = () => nav.classList.toggle('stuck', window.scrollY > 24);
onScroll();
window.addEventListener('scroll', onScroll, { passive: true });

// ---------- Mobile drawer ----------
const body = document.body;
const burger = document.getElementById('burger');
const drawer = document.getElementById('drawer');
const setOpen = (open) => {
  body.classList.toggle('open', open);
  burger.setAttribute('aria-expanded', String(open));
  drawer.setAttribute('aria-hidden', String(!open));
};
burger.addEventListener('click', () => setOpen(true));
document.getElementById('close').addEventListener('click', () => setOpen(false));
document.getElementById('scrim').addEventListener('click', () => setOpen(false));
drawer.querySelectorAll('a').forEach((a) => a.addEventListener('click', () => setOpen(false)));
document.addEventListener('keydown', (e) => { if (e.key === 'Escape') setOpen(false); });

// ---------- Reveal on scroll (design system section 15) ----------
// Header and body of a section stagger against each other; cards inside do not.
document.querySelectorAll('section').forEach((sec) => {
  sec.querySelectorAll(':scope .r').forEach((el, i) => { if (i === 1) el.classList.add('r-1'); if (i >= 2) el.classList.add('r-2'); });
});
const io = new IntersectionObserver((entries) => {
  for (const e of entries) {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  }
}, { rootMargin: '0px 0px -10% 0px', threshold: 0.06 });
document.querySelectorAll('.r').forEach((el) => io.observe(el));

// ---------- The audit: after value ----------
// Set this from Penny's Phase 5 trial balance. Leave null until it has actually been observed.
const AFTER_TOTAL = null; // for example '$0.00'
if (AFTER_TOTAL !== null) {
  const box = document.getElementById('after-box');
  box.classList.remove('pending');
  box.classList.add('good');
  document.getElementById('after-value').textContent = AFTER_TOTAL;
  document.getElementById('after-note').textContent = 'Total discrepancy after every fix, from the same reconciliation script.';
}

// ---------- Findings picker (numbers from penny-report/03-findings.md) ----------
const FINDINGS = [
  { id: 'P1', title: 'Float money', sev: 'Low', rule: 'Rule 1', imp: 'Under $0.05', who: 'Every account',
    desc: 'Money was stored as fractional numbers, so amounts carried stray fractions of a cent.' },
  { id: 'P2', title: 'Rounding drift', sev: 'Low', rule: 'Rule 2', imp: '$0.59', who: 'Customers',
    desc: 'Tax was rounded per line, so the amount charged could differ from the receipt.' },
  { id: 'P3', title: 'Retries charged twice', sev: 'Critical', rule: 'Rule 5', imp: '$15,582.24', who: 'Customers',
    desc: 'A retried charge with the same idempotency key debited the customer a second time.' },
  { id: 'P4', title: 'Fee taken twice', sev: 'Critical', rule: 'Rule 4', imp: '$11,532.69', who: 'Clearing account',
    desc: 'The platform fee was posted at charge time and again at settlement.' },
  { id: 'P5', title: 'Fee cap missing', sev: 'High', rule: 'Rule 3', imp: '$6,231.71', who: 'Merchants',
    desc: 'The $20 fee cap in the fee schedule was never applied, so large orders paid more.' },
  { id: 'P6', title: 'Refunds over the charge', sev: 'High', rule: 'Rule 6', imp: '$2,577.08', who: 'Merchants',
    desc: 'Duplicate refund requests paid out more than the customer was charged.' },
  { id: 'P7', title: 'Clearing never zero', sev: 'High', rule: 'Rule 7', imp: '$3,815.82', who: 'Platform',
    desc: 'The holding account kept a balance after settlement, caused by P3 and P4 together.' },
];
const picker = document.getElementById('picker');
if (picker) {
  const items = [...picker.querySelectorAll('li')];
  const $ = (id) => document.getElementById(id);
  const select = (sel) => {
    items.forEach((li, i) => { li.dataset.d = String(Math.abs(i - sel)); li.setAttribute('aria-selected', String(i === sel)); });
    const f = FINDINGS[sel];
    $('d-id').textContent = f.id; $('d-title').textContent = f.title;
    $('d-sev').textContent = f.sev; $('d-sev').className = `sev ${f.sev}`;
    $('d-desc').textContent = f.desc; $('d-rule').textContent = f.rule;
    $('d-imp').textContent = f.imp; $('d-who').textContent = f.who;
  };
  items.forEach((li, i) => {
    li.tabIndex = 0;
    li.addEventListener('click', () => select(i));
    li.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); select(i); } });
  });
  select(2);
}
JS_EOF

echo "Site rebuilt in light mode with all sections."
