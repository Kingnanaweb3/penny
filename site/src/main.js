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
