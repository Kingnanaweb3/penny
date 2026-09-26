#!/usr/bin/env bash
# Hero restyle: headline smaller, two lines, low and centered in white over a darkened image.
# Nav turns white over the hero and back to the light bar on scroll.
# Replaces only the hero block in site/index.html and the hero block in site/src/style.css.
# Run from the penny folder. Safe to run twice.
set -euo pipefail

F_HTML=site/index.html; F_CSS=site/src/style.css
grep -q "================= HERO =================" "$F_HTML" || { echo "Run scripts/09_site_light_full.sh first."; exit 1; }
if grep -q "pill-glass" "$F_CSS"; then echo "Hero already restyled, skipping."; exit 0; fi

T1="$(mktemp)"; T2="$(mktemp)"
cat > "$T1" << 'HTML_EOF'
    <!-- ================= HERO ================= -->
    <section class="hero" aria-labelledby="hero-title">
      <img class="hero-img" src="/hero.jpg" alt="" fetchpriority="high">
      <div class="hero-copy">
        <h1 id="hero-title" class="rise">Your tests pass. Your books don't.</h1>
        <p class="lead rise d1">Penny is a money auditor inside IBM Bob. She finds every cent your payment code loses, proves it with a failing test, and fixes it.</p>
        <div class="ctas rise d2">
          <a href="#audit" class="pill-glass">See the audit</a>
          <a href="https://github.com/Kingnanaweb3/penny" class="pill-glass quiet" target="_blank" rel="noopener">Read the code</a>
        </div>
      </div>
    </section>

HTML_EOF
cat > "$T2" << 'CSS_EOF'
/* ================= HERO ================= */
/* Headline low and centered over a darkened lower image, in the style of the reference. */
.hero {
  position: relative; min-height: max(640px, 100svh);
  display: flex; justify-content: center; align-items: flex-end;
  padding: 0 20px clamp(64px, 11vh, 128px);
  overflow: hidden; isolation: isolate; text-align: center; color: #fff;
}
.hero-img {
  position: absolute; inset: 0; z-index: -2; width: 100%; height: 100%;
  object-fit: cover; object-position: 60% 62%;
  filter: saturate(.95) brightness(.9);
  transform: scale(1.05); animation: settle 2.6s cubic-bezier(.16,1,.3,1) forwards;
}
.hero::before {
  content: ''; position: absolute; inset: 0; z-index: -1;
  background:
    linear-gradient(to bottom, rgba(24,20,16,.38) 0%, rgba(24,20,16,0) 20%),
    linear-gradient(to bottom, rgba(24,20,16,0) 42%, rgba(24,20,16,.42) 64%, rgba(20,17,14,.78) 88%, rgba(18,15,12,.9) 100%);
}
.hero::after { content: none; }
.hero-copy { max-width: 820px; }
h1 {
  margin: 0; font-size: 40px; font-weight: 450; line-height: 1.02; letter-spacing: -1.2px;
  text-wrap: balance; color: #fff; text-shadow: 0 2px 30px rgba(0,0,0,.25);
}
@media (min-width: 640px)  { h1 { font-size: 56px; letter-spacing: -2px; } }
@media (min-width: 1024px) { h1 { font-size: 76px; letter-spacing: -3px; line-height: 0.98; } }
.lead {
  margin: 22px auto 0; font-size: 16px; line-height: 1.6; color: rgba(255,255,255,.86);
  max-width: 40rem; text-wrap: balance;
}
@media (min-width: 640px) { .lead { font-size: 18px } }
.ctas { display: flex; flex-wrap: wrap; justify-content: center; gap: 12px; margin-top: 32px; }
.pill-glass {
  display: inline-flex; align-items: center; justify-content: center; height: 50px; padding: 0 26px;
  border-radius: 999px; font-size: 16px; font-weight: 500; color: #fff;
  background: rgba(20,17,14,.34); border: 1px solid rgba(255,255,255,.34);
  backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px);
  transition: background 180ms, border-color 180ms, transform 180ms;
}
.pill-glass:hover { background: rgba(255,255,255,.14); border-color: rgba(255,255,255,.5); transform: translateY(-1px); }
.pill-glass.quiet { background: transparent; border-color: rgba(255,255,255,.2); color: rgba(255,255,255,.88); }
@media (max-width: 420px) { .ctas .pill-glass { flex: 1 1 100%; } }

/* Nav reads white over the hero, then turns into the light bar once scrolled */
.nav:not(.stuck) { color: #fff; }
.nav:not(.stuck) .nav-links a { color: rgba(255,255,255,.86); }
.nav:not(.stuck) .nav-links a:hover { color: #fff; border-color: rgba(255,255,255,.3); background: rgba(255,255,255,.08); }
.nav:not(.stuck) .nav-cta { background: rgba(20,17,14,.3); color: #fff; border: 1px solid rgba(255,255,255,.4); backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px); }
.nav:not(.stuck) .burger { background: rgba(20,17,14,.3); border-color: rgba(255,255,255,.35); }
.nav:not(.stuck) .burger span, .nav:not(.stuck) .burger span::before, .nav:not(.stuck) .burger span::after { background: #fff; }
.nav .nav-cta { border: 1px solid transparent; }
@media (min-width: 1024px) {
  .nav-inner { max-width: 1080px; }
}

CSS_EOF

# swap the hero section in the HTML (from its marker up to the proof band marker)
BLK="$T1" perl -0pi -e 'BEGIN { local $/; open my $f, "<", $ENV{BLK} or die; $b = <$f>; } s#\s*<!-- =+ HERO =+ -->.*?(?=\s*<!-- =+ PROOF BAND)#\n$b#s' "$F_HTML"
# swap the hero block in the CSS (from its marker up to the shared section marker)
BLK="$T2" perl -0pi -e 'BEGIN { local $/; open my $f, "<", $ENV{BLK} or die; $b = <$f>; } s#/\* =+ HERO =+ \*/.*?(?=/\* =+ SHARED SECTION PIECES)#$b#s' "$F_CSS"
rm -f "$T1" "$T2"

echo "Hero restyled. Your dev server will refresh on its own."
