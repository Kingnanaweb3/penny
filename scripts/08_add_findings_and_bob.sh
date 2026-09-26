#!/usr/bin/env bash
# Adds the Findings section (interactive picker) and the Built on Bob section (hub diagram).
# Run from the penny folder. Safe to run twice.
set -euo pipefail

if [ ! -f site/index.html ]; then echo "Run scripts/06_setup_site_vite.sh first."; exit 1; fi
if ! grep -q 'id="how"' site/index.html; then echo "Run scripts/07_add_how_section.sh first."; exit 1; fi
if grep -q 'id="findings"' site/index.html; then echo "Sections already added, skipping."; exit 0; fi

TMP="$(mktemp)"
cat > "$TMP" << 'SEC_EOF'
    <section class="s findings" id="findings" aria-labelledby="findings-title">
      <div class="wrap">
        <div class="sec-top r">
          <div>
            <span class="chip-label">Findings</span>
            <h2 id="findings-title">Seven findings. Every one proven.</h2>
            <p class="sub">From Penny's audit of ShopLedger, a sample payments app with deliberately seeded bugs, over one simulated day of 500 orders.</p>
          </div>
          <a class="explore" href="https://github.com/Kingnanaweb3/penny/blob/main/penny-report/03-findings.md" target="_blank" rel="noopener">Explore <span aria-hidden="true">&rsaquo;</span></a>
        </div>

        <div class="fnd r">
          <div class="picker-panel">
            <ul class="picker" id="picker" role="listbox" aria-label="Findings">
              <li role="option" data-i="0"><span class="pid mono">P1</span>Float money</li>
              <li role="option" data-i="1"><span class="pid mono">P2</span>Rounding drift</li>
              <li role="option" data-i="2"><span class="pid mono">P3</span>Retries charged twice</li>
              <li role="option" data-i="3"><span class="pid mono">P4</span>Fee taken twice</li>
              <li role="option" data-i="4"><span class="pid mono">P5</span>Fee cap missing</li>
              <li role="option" data-i="5"><span class="pid mono">P6</span>Refunds over the charge</li>
              <li role="option" data-i="6"><span class="pid mono">P7</span>Clearing never zero</li>
            </ul>
          </div>

          <div class="fnd-side">
            <div class="detail" id="detail" aria-live="polite">
              <div class="d-head"><span class="d-id mono" id="d-id">P3</span><span id="d-title">Retries charged twice</span><b class="sev" id="d-sev">Critical</b></div>
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

SEC_EOF

SEC="$TMP" perl -0pi -e 'BEGIN { local $/; open my $f, "<", $ENV{SEC} or die; $s = <$f>; } s#(\s*<div class="next" id="audit"></div>)#\n$s$1#' site/index.html
rm -f "$TMP"

cat >> site/src/style.css << 'CSS_EOF'

/* ===== Shared section header (Duna style: title left, Explore pill right) ===== */
.sec-top { display: flex; justify-content: space-between; align-items: flex-end; gap: 24px; margin-bottom: clamp(40px, 6vw, 72px); }
.sec-top h2 { max-width: 16ch; }
.sub { margin: 16px 0 0; font-size: var(--step-2); line-height: 1.65; color: var(--muted); max-width: 48ch; }
.chip-label {
  display: inline-block; margin-bottom: 16px; padding: 4px 10px; border-radius: 999px;
  font-size: var(--step--1); font-weight: 450; color: var(--muted);
  border: 1px solid var(--line); background: rgba(255,255,255,.03);
}
.explore {
  flex: none; display: inline-flex; align-items: center; gap: 6px; height: 36px; padding: 0 14px;
  border-radius: 999px; border: 1px solid var(--line); font-size: var(--step-0); font-weight: 500;
  background: rgba(255,255,255,.03); transition: background 160ms, border-color 160ms;
}
.explore:hover { background: rgba(255,255,255,.07); border-color: rgba(255,255,255,.2); }
.explore span { font-size: 16px; line-height: 1; }
@media (max-width: 640px) { .sec-top { flex-direction: column; align-items: flex-start; } }

/* ===== Findings: picker panel left, detail and features right ===== */
.findings { padding-top: clamp(88px, 13vw, 170px); }
.fnd { display: grid; gap: clamp(24px, 4vw, 56px); align-items: center; }
@media (min-width: 900px) { .fnd { grid-template-columns: 1fr 1fr; } }

.picker-panel {
  border-radius: 20px; border: 1px solid var(--line);
  background: var(--panel);
  aspect-ratio: 1 / 1; max-height: 520px; width: 100%;
  display: grid; place-items: center; overflow: hidden;
}
.picker { list-style: none; margin: 0; padding: 0; display: grid; gap: 6px; width: min(78%, 330px); }
.picker li {
  display: flex; align-items: center; gap: 10px;
  padding: 11px 14px; border-radius: 12px; cursor: pointer;
  font-size: var(--step-1); color: var(--muted);
  background: rgba(255,255,255,.035); border: 1px solid transparent;
  transition: opacity 260ms, transform 260ms, background 260ms, color 260ms, border-color 260ms;
}
.picker .pid { font-size: 11px; color: var(--faint); width: 22px; }
.picker li[data-d="0"] { opacity: 1; transform: scale(1.06); background: #26262A; color: var(--ink); border-color: rgba(255,255,255,.12); box-shadow: 0 18px 40px -18px rgba(0,0,0,.9); }
.picker li[data-d="0"] .pid { color: var(--accent); }
.picker li[data-d="1"] { opacity: .8; transform: scale(.98); }
.picker li[data-d="2"] { opacity: .5; transform: scale(.95); }
.picker li[data-d="3"] { opacity: .28; transform: scale(.92); }
.picker li[data-d="4"], .picker li[data-d="5"], .picker li[data-d="6"] { opacity: .16; transform: scale(.9); }
.picker li:hover { color: var(--ink); }

.detail {
  border-radius: 16px; padding: clamp(18px, 2vw, 24px);
  background: var(--panel); border: 1px solid var(--line);
}
.d-head { display: flex; align-items: center; gap: 10px; font-size: var(--step-2); font-weight: 500; }
.d-id { font-size: 12px; color: var(--accent); }
.sev { margin-left: auto; font-size: 11px; font-weight: 500; padding: 3px 9px; border-radius: 999px; }
.sev.Critical { color: var(--bad);  background: rgba(248,113,113,.10); }
.sev.High     { color: var(--warn); background: rgba(224,168,90,.10); }
.sev.Low      { color: var(--muted); background: rgba(255,255,255,.06); }
.detail p { margin: 10px 0 0; font-size: var(--step-0); line-height: 1.6; color: var(--muted); }
.detail dl { margin: 16px 0 0; display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; border-top: 1px solid var(--line); padding-top: 14px; }
.detail dt { font-size: 11px; color: var(--faint); }
.detail dd { margin: 4px 0 0; font-size: var(--step-1); }

.feats { list-style: none; margin: 18px 0 0; padding: 0; display: grid; }
.feats li { display: flex; align-items: center; gap: 12px; padding: 14px 4px; font-size: var(--step-1); color: var(--muted); }
.feats svg { color: var(--faint); flex: none; }

/* ===== Built on Bob: full width band with a hub diagram ===== */
.bob-band {
  margin-top: clamp(88px, 13vw, 170px);
  padding-top: clamp(72px, 10vw, 128px); padding-bottom: clamp(72px, 10vw, 128px);
  background: var(--panel); border-block: 1px solid var(--line);
}
.hub {
  --gx: clamp(28px, 5vw, 64px); --gy: clamp(28px, 4vw, 48px);
  display: grid; grid-template-columns: 1fr auto 1fr; align-items: center; justify-items: center;
  column-gap: var(--gx); row-gap: var(--gy); margin-inline: auto; max-width: 980px;
}
.node {
  position: relative; padding: 12px 22px; border-radius: 999px;
  font-size: var(--step-1); font-weight: 450; white-space: nowrap;
  background: rgba(255,255,255,.05); border: 1px solid var(--line);
}
.n-top { grid-column: 2; grid-row: 1; }
.n-left { grid-column: 1; grid-row: 2; justify-self: end; }
.core { grid-column: 2; grid-row: 2; }
.n-right { grid-column: 3; grid-row: 2; justify-self: start; }
.n-bottom { grid-column: 2; grid-row: 3; }
.node::after { content: ''; position: absolute; background: rgba(255,255,255,.16); }
.n-top::after    { left: 50%; top: 100%; width: 1px; height: var(--gy); }
.n-bottom::after { left: 50%; bottom: 100%; width: 1px; height: var(--gy); }
.n-left::after   { top: 50%; left: 100%; height: 1px; width: var(--gx); }
.n-right::after  { top: 50%; right: 100%; height: 1px; width: var(--gx); }

.core {
  width: clamp(240px, 30vw, 380px); height: clamp(96px, 11vw, 136px); border-radius: 999px;
  display: grid; place-items: center;
  background: url('/hero.jpg') 60% 72% / cover no-repeat;
  box-shadow: 0 0 0 8px rgba(255,255,255,.04), 0 0 0 16px rgba(255,255,255,.025), 0 30px 60px -24px rgba(0,0,0,.9);
  position: relative; overflow: hidden;
}
.core::before { content: ''; position: absolute; inset: 0; background: linear-gradient(to bottom, rgba(12,12,12,.05), rgba(12,12,12,.35)); }
.core span { position: relative; font-size: clamp(30px, 3.6vw, 46px); font-weight: 450; letter-spacing: -1.4px; color: #fff; text-shadow: 0 2px 18px rgba(0,0,0,.35); }

@media (max-width: 759px) {
  .hub { grid-template-columns: 1fr 1fr; }
  .core { grid-column: 1 / -1; grid-row: 1; width: 100%; margin-bottom: 8px; }
  .n-top, .n-left, .n-right, .n-bottom { grid-column: auto; grid-row: auto; justify-self: stretch; text-align: center; }
  .node::after { display: none; }
}

.hub-legend {
  margin-top: clamp(56px, 8vw, 96px);
  display: grid; border-top: 1px solid var(--line);
}
@media (min-width: 760px) { .hub-legend { grid-template-columns: repeat(4, 1fr); } }
.hub-legend div { padding: 22px 20px 4px 0; }
@media (min-width: 760px) { .hub-legend div + div { padding-left: 20px; border-left: 1px solid var(--line); } }
.hub-legend b { font-weight: 500; font-size: var(--step-1); }
.hub-legend p { margin: 8px 0 0; font-size: var(--step-0); line-height: 1.65; color: var(--muted); }
CSS_EOF

cat >> site/src/main.js << 'JS_EOF'

// Findings picker: every number comes from penny-report/03-findings.md
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
    items.forEach((li, i) => {
      li.dataset.d = String(Math.abs(i - sel));
      li.setAttribute('aria-selected', String(i === sel));
    });
    const f = FINDINGS[sel];
    $('d-id').textContent = f.id;
    $('d-title').textContent = f.title;
    $('d-sev').textContent = f.sev;
    $('d-sev').className = `sev ${f.sev}`;
    $('d-desc').textContent = f.desc;
    $('d-rule').textContent = f.rule;
    $('d-imp').textContent = f.imp;
    $('d-who').textContent = f.who;
  };
  items.forEach((li, i) => {
    li.tabIndex = 0;
    li.addEventListener('click', () => select(i));
    li.addEventListener('keydown', (e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); select(i); } });
  });
  select(2);
}
JS_EOF

echo "Added the Findings and Built on Bob sections. Your dev server will refresh on its own."
