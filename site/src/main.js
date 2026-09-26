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
