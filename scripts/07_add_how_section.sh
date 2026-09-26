#!/usr/bin/env bash
# Adds the "How Penny works" section (alternating feature rows) below the hero.
# Run from the penny folder. Safe to run twice.
set -euo pipefail

if [ ! -f site/index.html ]; then echo "Run scripts/06_setup_site_vite.sh first."; exit 1; fi
if grep -q 'id="how"' site/index.html; then echo "Section already added, skipping."; exit 0; fi

TMP="$(mktemp)"
cat > "$TMP" << 'SEC_EOF'
    <section class="s feat" id="how" aria-labelledby="how-title">
      <div class="wrap">
        <div class="feat-head r">
          <div class="eyebrow"><i></i><span>How Penny works</span></div>
          <h2 id="how-title">An auditor's method, run inside your editor.</h2>
        </div>

        <!-- Row 1: spec check -->
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
            <div class="chip chip-br">
              <span class="k mono">Enforced at audit</span>
              <span class="v num">0 of 7</span>
            </div>
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

        <!-- Row 2: failing test first -->
        <div class="feat-row flip r">
          <div class="stage" aria-hidden="true">
            <div class="glow"></div>
            <div class="mock tilt-r">
              <div class="mock-bar"><i></i><i></i><i></i><span class="mono">p2-rounding-drift.test.js</span></div>
              <div class="mock-body term mono">
                <div class="ln dim">$ node --test tests/penny/p2-rounding-drift.test.js</div>
                <div class="ln bad">✖ charge equals receipt</div>
                <div class="ln dim">&nbsp;&nbsp;expected 322.51</div>
                <div class="ln dim">&nbsp;&nbsp;actual&nbsp;&nbsp;&nbsp;322.52</div>
                <div class="ln sep"></div>
                <div class="ln dim">$ fix: tax calculated once, in whole cents</div>
                <div class="ln sep"></div>
                <div class="ln good">✔ charge equals receipt</div>
                <div class="ln dim">&nbsp;&nbsp;tests 9 &nbsp;pass 9 &nbsp;fail 0</div>
              </div>
            </div>
            <div class="chip chip-tl">
              <span class="k mono">Order</span>
              <span class="v small">Red, then green</span>
            </div>
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

        <!-- Row 3: decomposition -->
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
            <div class="chip chip-br">
              <span class="k mono">Unexplained</span>
              <span class="v num good">$0.00</span>
            </div>
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

    <div class="next" id="audit"></div>
SEC_EOF

SEC="$TMP" perl -0pi -e 'BEGIN { local $/; open my $f, "<", $ENV{SEC} or die; $s = <$f>; } s#\s*<div class="next" id="audit"></div>\n#\n$s#' site/index.html
rm -f "$TMP"

cat >> site/src/style.css << 'CSS_EOF'

/* ===== Section: How Penny works (alternating feature rows) ===== */
.eyebrow { display: flex; align-items: center; gap: 9px; margin-bottom: 18px; }
.eyebrow i { height: 3px; width: 18px; border-radius: 2px; background: var(--accent); display: block; }
.eyebrow span { font-family: var(--mono); font-size: 11px; letter-spacing: .08em; text-transform: uppercase; color: var(--faint); }

.feat { padding-top: clamp(88px, 13vw, 170px); }
.feat-head { max-width: 760px; margin-bottom: clamp(48px, 8vw, 96px); }
h2 {
  margin: 0; font-size: clamp(30px, 4.2vw, 52px); font-weight: 400;
  line-height: 1.04; letter-spacing: -1.4px; text-wrap: balance;
}

.feat-row {
  display: grid; gap: clamp(32px, 5vw, 72px); align-items: center;
  padding-block: clamp(36px, 6vw, 72px);
}
@media (min-width: 900px) {
  .feat-row { grid-template-columns: 1.1fr 1fr; }
  .feat-row.flip { grid-template-columns: 1fr 1.1fr; }
  .feat-row.flip .stage { order: 2; }
}

.feat-copy h3 {
  margin: 0; font-size: clamp(26px, 3vw, 38px); font-weight: 400;
  line-height: 1.1; letter-spacing: -1px; text-wrap: balance; max-width: 22ch;
}
.feat-copy p { margin: 18px 0 0; font-size: var(--step-2); line-height: 1.7; color: var(--muted); max-width: 46ch; }
.feat-ctas { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 28px; }

.pill-md {
  display: inline-flex; align-items: center; height: 42px; padding: 0 18px;
  border-radius: 999px; font-size: var(--step-1); font-weight: 500;
  transition: transform 180ms, opacity 180ms, background 180ms;
}
.pill-md.solid { background: var(--ink); color: var(--bg); }
.pill-md.solid:hover { transform: translateY(-1px); opacity: .92; }
.pill-md.ghost { border: 1px solid rgba(255,255,255,.18); color: var(--ink); }
.pill-md.ghost:hover { transform: translateY(-1px); background: rgba(255,255,255,.05); }

/* The stage: tilted product card, a floating chip, a round badge, soft accent glow */
.stage { position: relative; padding: clamp(24px, 4vw, 48px) clamp(12px, 3vw, 40px); perspective: 1600px; }
.glow {
  position: absolute; inset: 12% 8%; z-index: 0; border-radius: 50%;
  background: radial-gradient(closest-side, rgba(124,147,214,.42), rgba(124,147,214,0));
  filter: blur(34px);
}
.mock {
  position: relative; z-index: 1;
  background: linear-gradient(180deg, #1D1D1B, var(--panel));
  border: 1px solid var(--line); border-radius: 18px; overflow: hidden;
  box-shadow: 0 50px 90px -40px rgba(0,0,0,.95), 0 0 0 1px rgba(255,255,255,.02) inset;
  transition: transform 600ms cubic-bezier(.16,1,.3,1);
}
.tilt-l { transform: rotateY(12deg) rotateX(5deg) rotateZ(-1deg); }
.tilt-r { transform: rotateY(-12deg) rotateX(5deg) rotateZ(1deg); }
.stage:hover .mock { transform: none; }
@media (max-width: 899px) { .tilt-l, .tilt-r { transform: rotateX(4deg); } }

.mock-bar {
  height: 34px; display: flex; align-items: center; gap: 7px; padding: 0 14px;
  background: #151515; border-bottom: 1px solid var(--line);
}
.mock-bar i { width: 9px; height: 9px; border-radius: 50%; background: #2E2E2E; }
.mock-bar span { margin-left: 8px; font-size: 11.5px; color: var(--faint); }
.mock-body { padding: clamp(16px, 2vw, 22px); }
.mock-title { font-size: var(--step-1); font-weight: 500; margin-bottom: 12px; }

.rules { list-style: none; margin: 0; padding: 0; display: grid; gap: 2px; }
.rules li {
  display: grid; grid-template-columns: 34px 1fr auto; align-items: center; gap: 8px;
  padding: 9px 10px; border-radius: 10px; font-size: var(--step-0); color: var(--muted);
  background: rgba(255,255,255,.02);
}
.rules .rn { color: var(--faint); font-size: 11px; }
.tag {
  font-size: 11px; font-weight: 500; padding: 3px 9px; border-radius: 999px; letter-spacing: 0;
}
.tag.bad  { color: var(--bad);  background: rgba(248,113,113,.10); }
.tag.warn { color: var(--warn); background: rgba(224,168,90,.10); }

.term { font-size: 12.5px; line-height: 1.9; }
.term .ln { white-space: pre-wrap; }
.term .dim  { color: var(--faint); }
.term .bad  { color: var(--bad); }
.term .good { color: var(--good); }
.term .sep  { height: 8px; }

.decomp { display: grid; gap: 2px; }
.drow {
  display: flex; justify-content: space-between; align-items: baseline; gap: 12px;
  padding: 11px 10px; border-radius: 10px; font-size: var(--step-0); color: var(--muted);
  background: rgba(255,255,255,.02);
}
.drow em { font-style: normal; font-size: 11px; color: var(--faint); margin-left: 6px; }
.drow b { font-weight: 450; color: var(--ink); }
.drow.total { background: transparent; border-top: 1px solid var(--line); border-radius: 0; margin-top: 6px; padding-top: 14px; color: var(--ink); }

.chip {
  position: absolute; z-index: 2;
  display: grid; gap: 4px; padding: 14px 18px; border-radius: 14px;
  background: rgba(23,23,21,.9); border: 1px solid rgba(255,255,255,.14);
  backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px);
  box-shadow: 0 24px 50px -20px rgba(0,0,0,.9);
}
.chip .k { font-size: 10.5px; letter-spacing: .06em; text-transform: uppercase; color: var(--faint); }
.chip .v { font-size: clamp(22px, 2.6vw, 30px); font-weight: 400; letter-spacing: -1px; line-height: 1; }
.chip .v.small { font-size: var(--step-3); letter-spacing: -0.5px; }
.chip .v.good { color: var(--good); }
.chip-br { right: 0; bottom: 4px; }
.chip-tl { left: 0; top: -6px; }

.badge {
  position: absolute; z-index: 2; top: 50%; width: 52px; height: 52px; border-radius: 50%;
  display: grid; place-items: center; color: var(--accent);
  background: rgba(23,23,21,.92); border: 1px solid rgba(124,147,214,.35);
  box-shadow: 0 0 0 6px rgba(124,147,214,.07), 0 18px 40px -16px rgba(0,0,0,.9);
}
.badge-r { right: -6px; transform: translateY(-50%); }
.badge-l { left: -6px; transform: translateY(-50%); }
@media (max-width: 899px) { .badge { display: none; } }

/* Section reveal (skill section 15): whole rows, not individual cards */
.r { opacity: 0; transform: translateY(18px); transition: opacity .7s cubic-bezier(.16,1,.3,1), transform .7s cubic-bezier(.16,1,.3,1); }
.r.in { opacity: 1; transform: none; }
@media (prefers-reduced-motion: reduce) { .r { opacity: 1; transform: none; transition: none; } }
CSS_EOF

cat >> site/src/main.js << 'JS_EOF'

// Reveal whole sections and rows as they scroll into view (skill section 15)
const io = new IntersectionObserver((entries) => {
  for (const e of entries) {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  }
}, { rootMargin: '0px 0px -12% 0px', threshold: 0.08 });
document.querySelectorAll('.r').forEach((el) => io.observe(el));
JS_EOF

echo "Added the How Penny works section. Your dev server will refresh on its own."
