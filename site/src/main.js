// Nav turns solid after 24px of scroll
const nav = document.getElementById('nav');
const onScroll = () => nav.classList.toggle('stuck', window.scrollY > 24);
onScroll();
window.addEventListener('scroll', onScroll, { passive: true });

// Mobile drawer: opens from the right, closes on Escape, scrim or link
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

// Reveal whole sections and rows as they scroll into view (skill section 15)
const io = new IntersectionObserver((entries) => {
  for (const e of entries) {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  }
}, { rootMargin: '0px 0px -12% 0px', threshold: 0.08 });
document.querySelectorAll('.r').forEach((el) => io.observe(el));
