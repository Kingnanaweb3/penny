#!/usr/bin/env bash
# Builds the Penny landing page (hero only for now) into site/
# Run from the penny folder.
set -euo pipefail

SRC="${1:-$HOME/Downloads/Penny frontend.png}"
mkdir -p site

if [ -f "$SRC" ]; then
  if command -v sips >/dev/null 2>&1; then
    sips -s format jpeg -s formatOptions 84 "$SRC" --out site/hero.jpg >/dev/null
    echo "Hero image converted to site/hero.jpg"
  else
    cp "$SRC" site/hero.jpg
    echo "Hero image copied to site/hero.jpg"
  fi
elif [ -f site/hero.jpg ]; then
  echo "Using existing site/hero.jpg"
else
  echo "Could not find the hero image at: $SRC"
  echo "Pass the path as an argument: bash scripts/05_build_site.sh /path/to/image.png"
  exit 1
fi

cat > site/index.html << 'HTML_EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>Penny: every cent accounted for</title>
<meta name="description" content="Penny is a money auditor that lives inside IBM Bob. She proves every discrepancy in your payment code with a failing test, fixes it, and proves the books balance.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Geist:wght@100..900&family=Geist+Mono:wght@100..900&display=swap" rel="stylesheet">
<style>
:root {
  color-scheme: light;

  /* Reskinned from the landing page system: light, warm, from the hero sky */
  --bg:     #F6F1E9;
  --panel:  #EFE8DC;
  --ink:    #1B1916;
  --muted:  #625C53;
  --faint:  #978F83;
  --line:   rgba(27,25,22,.12);
  --accent: #3F5AA6;

  /* data only, darkened for a light background */
  --good: #2E8B57;
  --warn: #B26B12;
  --bad:  #B8412F;

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

  padding-top: env(safe-area-inset-top, 0px);
  padding-bottom: env(safe-area-inset-bottom, 0px);
}

*, *::before, *::after { box-sizing: border-box; }
html { scroll-padding-top: 72px; }
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
}
a { color: inherit; text-decoration: none; }
img { max-width: 100%; display: block; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 3px; border-radius: 6px; }

.wrap { max-width: 1160px; margin: 0 auto; }
section.s { padding-inline: 16px; }
@media (min-width: 640px)  { section.s { padding-inline: 32px } }
@media (min-width: 1024px) { section.s { padding-inline: 30px } }

/* ---------- Nav ---------- */
.nav {
  position: fixed; inset-inline: 0; top: 0; z-index: 50;
  height: 56px; display: flex; align-items: center; justify-content: space-between;
  padding-inline: 16px;
  margin-top: env(safe-area-inset-top, 0px);
  background: transparent;
  border-bottom: 1px solid transparent;
  transition: background 200ms, border-color 200ms;
}
@media (min-width: 640px)  { .nav { padding-inline: 32px } }
@media (min-width: 1024px) { .nav { padding-inline: 30px } }
.nav.stuck {
  background: rgba(246,241,233,.84);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border-bottom-color: var(--line);
}
.brand { display: inline-flex; align-items: center; gap: 10px; font-size: 17px; font-weight: 560; letter-spacing: -0.5px; }
.brand .coin {
  width: 22px; height: 22px; border-radius: 50%;
  border: 1.5px solid var(--ink);
  display: grid; place-items: center;
  font-size: 11px; font-weight: 600; letter-spacing: 0;
}
.nav-links { display: none; align-items: center; gap: 2px; }
.nav-links a {
  display: inline-flex; align-items: center; height: 34px; padding-inline: 11px;
  border-radius: 999px; font-size: var(--step-1); font-weight: 450; color: rgba(27,25,22,.72);
  border: 1px solid transparent; transition: color 160ms, border-color 160ms, background 160ms;
}
.nav-links a:hover { color: var(--ink); border-color: var(--line); background: rgba(255,255,255,.35); }
.pill-sm {
  display: inline-flex; align-items: center; height: 36px; padding: 0 16px;
  border-radius: 999px; background: var(--ink); color: var(--bg);
  font-size: var(--step-1); font-weight: 530; transition: transform 180ms, opacity 180ms;
}
.pill-sm:hover { transform: translateY(-1px); opacity: .92; }

.burger {
  width: 40px; height: 40px; border-radius: 999px; border: 1px solid var(--line);
  background: rgba(255,255,255,.3); display: grid; place-items: center; cursor: pointer; padding: 0;
}
.burger span, .burger span::before, .burger span::after {
  display: block; width: 16px; height: 1.5px; background: var(--ink); border-radius: 2px; position: relative; content: '';
}
.burger span::before { position: absolute; top: -5px; }
.burger span::after  { position: absolute; top: 5px; }

.scrim {
  position: fixed; inset: 0; z-index: 60; background: rgba(27,25,22,.28);
  backdrop-filter: blur(6px); -webkit-backdrop-filter: blur(6px);
  opacity: 0; pointer-events: none; transition: opacity 220ms;
}
.drawer {
  position: fixed; top: 0; right: 0; bottom: 0; z-index: 70;
  width: min(84vw, 340px); background: var(--bg); border-left: 1px solid var(--line);
  padding: calc(18px + env(safe-area-inset-top, 0px)) 22px calc(22px + env(safe-area-inset-bottom, 0px));
  transform: translateX(100%); transition: transform 280ms cubic-bezier(.16,1,.3,1);
  display: flex; flex-direction: column; gap: 4px;
}
.drawer a { padding: 14px 4px; font-size: 18px; font-weight: 450; border-bottom: 1px solid var(--line); }
.drawer .pill-sm { margin-top: 20px; justify-content: center; height: 48px; font-size: 16px; border-bottom: 0; }
.drawer-close { align-self: flex-end; margin-bottom: 8px; }
body.open .scrim { opacity: 1; pointer-events: auto; }
body.open .drawer { transform: none; }
body.open { overflow: hidden; }

.nav .nav-cta { display: none; }
@media (min-width: 861px) {
  .nav .nav-links { display: flex; }
  .nav .nav-cta { display: inline-flex; }
  .nav .burger { display: none; }
}

/* ---------- Hero ---------- */
.hero {
  position: relative;
  min-height: clamp(640px, 94svh, 980px);
  display: flex; flex-direction: column;
  overflow: hidden;
  isolation: isolate;
}
.hero-img {
  position: absolute; inset: 0; z-index: -2;
  width: 100%; height: 100%;
  object-fit: cover; object-position: 62% 100%;
}
/* A light wash behind the copy only. Not a scrim: the sky stays visible. */
.hero::before {
  content: ''; position: absolute; inset: 0; z-index: -1;
  background:
    radial-gradient(ellipse 70% 60% at 22% 34%, rgba(246,241,233,.62) 0%, rgba(246,241,233,.28) 45%, rgba(246,241,233,0) 72%),
    linear-gradient(to bottom, rgba(246,241,233,.35) 0%, rgba(246,241,233,0) 18%);
}
/* Water melts into the page so the next section continues from it */
.hero::after {
  content: ''; position: absolute; inset: auto 0 0 0; height: 16%; z-index: -1;
  background: linear-gradient(to bottom, rgba(246,241,233,0), var(--bg));
}
.hero .wrap { width: 100%; }
.hero-copy { padding-top: calc(56px + clamp(56px, 11vh, 132px)); }
.hero-copy > * { max-width: 820px; }
.eyebrow { display: flex; align-items: center; gap: 9px; margin-bottom: 22px; }
.eyebrow i { height: 3px; width: 18px; border-radius: 2px; background: var(--accent); display: block; }
.eyebrow span {
  font-family: var(--mono); font-size: 11px; letter-spacing: .08em; text-transform: uppercase;
  color: rgba(27,25,22,.66);
}
h1 {
  margin: 0;
  font-size: 40px; font-weight: 400; line-height: 0.98; letter-spacing: -0.5px;
  text-wrap: balance; max-width: 72rem;
}
@media (min-width: 640px)  { h1 { font-size: 56px } }
@media (min-width: 768px)  { h1 { font-size: 68px } }
@media (min-width: 1024px) { h1 { font-size: 84px; letter-spacing: -1.2px; } }
.lead {
  margin: 26px 0 0;
  font-size: 16px; line-height: 1.75;
  color: rgba(27,25,22,.8);
  max-width: 36rem; text-wrap: pretty;
}
@media (min-width: 640px) { .lead { font-size: 19px } }
.ctas { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 34px; }
.pill-lg {
  display: inline-flex; align-items: center; gap: 9px; height: 52px; padding: 0 26px;
  border-radius: 999px; font-size: 16px; font-weight: 530;
  transition: transform 180ms, opacity 180ms, background 180ms;
}
.pill-lg.solid { background: var(--ink); color: var(--bg); }
.pill-lg.solid:hover { transform: translateY(-1px); opacity: .92; }
.pill-lg.ghost { background: rgba(246,241,233,.42); color: var(--ink); border: 1px solid rgba(27,25,22,.18);
  backdrop-filter: blur(6px); -webkit-backdrop-filter: blur(6px); }
.pill-lg.ghost:hover { transform: translateY(-1px); background: rgba(246,241,233,.7); }

.hero-foot {
  margin-top: auto;
  padding-bottom: clamp(22px, 4vh, 40px);
}
.built {
  display: inline-flex; align-items: center; gap: 10px;
  font-size: var(--step-0); color: rgba(27,25,22,.72);
  padding: 8px 14px 8px 10px; border-radius: 999px;
  background: rgba(246,241,233,.62); border: 1px solid rgba(27,25,22,.1);
  backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
}
.built b { font-weight: 530; color: var(--ink); }
.built .dot { width: 7px; height: 7px; border-radius: 50%; background: var(--good); }

/* the one motion moment: the hero copy settles in on load */
.rise { opacity: 0; transform: translateY(14px); animation: rise .9s cubic-bezier(.16,1,.3,1) forwards; }
.rise.d1 { animation-delay: .08s; } .rise.d2 { animation-delay: .16s; } .rise.d3 { animation-delay: .24s; }
@keyframes rise { to { opacity: 1; transform: none; } }
@media (prefers-reduced-motion: reduce) { .rise { opacity: 1; transform: none; animation: none; } }

/* placeholder so the sticky nav can be seen working; replaced by real sections next */
.next { height: 60vh; }
</style>
</head>
<body>

<header class="nav" id="nav">
  <a href="#top" class="brand" aria-label="Penny home"><span class="coin" aria-hidden="true">P</span>Penny</a>
  <nav class="nav-links" aria-label="Main">
    <a href="#how">How it works</a>
    <a href="#findings">Findings</a>
    <a href="#bob">Built on Bob</a>
    <a href="https://github.com/Kingnanaweb3/penny" target="_blank" rel="noopener">GitHub</a>
  </nav>
  <a href="#audit" class="pill-sm nav-cta">See the audit</a>
  <button class="burger" id="burger" aria-label="Open menu" aria-expanded="false" aria-controls="drawer"><span></span></button>
</header>

<div class="scrim" id="scrim"></div>
<aside class="drawer" id="drawer" aria-label="Menu" aria-hidden="true">
  <button class="burger drawer-close" id="close" aria-label="Close menu">&times;</button>
  <a href="#how">How it works</a>
  <a href="#findings">Findings</a>
  <a href="#bob">Built on Bob</a>
  <a href="https://github.com/Kingnanaweb3/penny" target="_blank" rel="noopener">GitHub</a>
  <a href="#audit" class="pill-sm">See the audit</a>
</aside>

<main id="top">
  <section class="hero s" aria-labelledby="hero-title">
    <img class="hero-img" src="hero.jpg" alt="" fetchpriority="high">
    <div class="wrap hero-copy">
      <div class="eyebrow rise"><i></i><span>A money auditor for payment code</span></div>
      <h1 id="hero-title" class="rise d1">Every cent accounted for.</h1>
      <p class="lead rise d2">Penny lives inside IBM Bob. She runs a trial balance on your payment code, proves every discrepancy with a failing test, fixes it, and proves the books balance.</p>
      <div class="ctas rise d3">
        <a href="#audit" class="pill-lg solid">See the audit</a>
        <a href="https://github.com/Kingnanaweb3/penny" class="pill-lg ghost" target="_blank" rel="noopener">Read the code</a>
      </div>
    </div>
    <div class="wrap hero-foot">
      <span class="built"><span class="dot" aria-hidden="true"></span>Runs as a custom mode in <b>IBM Bob 2.0</b></span>
    </div>
  </section>

  <div class="next" id="audit"></div>
</main>

<script>
  const nav = document.getElementById('nav');
  const onScroll = () => nav.classList.toggle('stuck', window.scrollY > 24);
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  const body = document.body, burger = document.getElementById('burger'), drawer = document.getElementById('drawer');
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
</script>
</body>
</html>
HTML_EOF

echo "Built site/index.html"
echo "Preview it with: open site/index.html"
