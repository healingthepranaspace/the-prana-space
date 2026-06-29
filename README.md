# The Prana Space — Landing Page

A single-page marketing site for Mamta Kaushik's Pranic Healing & Counselling
Psychology practice (Pune, India).

Live reference: https://pranaspace-v2.vercel.app

---

## What's in this folder

```
index.html          The entire site — HTML, CSS (inline <style>) and JS (inline <script>).
                    No build step. No dependencies.
vercel.json         Vercel config (clean URLs, no trailing slash).
assets/
  hero.mp4          Hero background video — lotus flowers (autoplays, muted, loops).
  hero-poster.jpg   Poster frame shown before the video loads.
  logo.jpg          Brand logo (used in nav + footer).
  mamta.jpg         Portrait photo of Mamta (About section).
```

Fonts (Fraunces + Inter) load from Google Fonts via a `<link>` in the `<head>` —
nothing to install.

---

## How to deploy

This is a **static site** — any static host works. Pick one:

### Option A — Vercel (recommended, matches the live reference)
```bash
npm i -g vercel        # if not already installed
cd mamta-website-share
vercel deploy --prod
```
Or drag-and-drop this folder into the Vercel dashboard.

### Option B — Netlify
Drag this folder onto https://app.netlify.com/drop — done.

### Option C — Any web server / shared hosting
Upload the contents of this folder (keep `assets/` alongside `index.html`)
to the web root. No server-side runtime is required.

### Test locally first
```bash
cd mamta-website-share
python3 -m http.server 8000
# open http://localhost:8000
```

---

## Connecting a custom domain (thepranaspace.com)

On Vercel/Netlify: add the domain in the project settings and point the
domain's DNS (A / CNAME records) as the host instructs. No code change needed.

---

## Things the developer may want to wire up

1. **Contact form** — Currently the form has no backend. In `index.html`, search
   for `FORMSPREE_ID`. It's empty (`""`), so the form falls back to opening
   WhatsApp with the message pre-filled. To collect form submissions by email
   instead, create a free form at https://formspree.io and paste the form ID
   into `FORMSPREE_ID`.

2. **WhatsApp / phone / Instagram** — already wired to:
   - WhatsApp / Call: +91 92095 57407
   - Instagram: @the_pranaspace
   Search those in `index.html` to change them.

3. **Hero video** — to swap, replace `assets/hero.mp4` (and ideally regenerate
   `assets/hero-poster.jpg` from the first frame). Keep it short, muted, and
   compressed (current file is ~480 KB) so mobile stays fast.

---

## Notes

- Fully responsive — desktop, tablet and mobile breakpoints are in the inline
  CSS (search `@media`).
- All colors/fonts are CSS custom properties in `:root` (top of the `<style>`
  block) — easy to retheme in one place.
- Medical disclaimer is in the footer (Pranic Healing complements, does not
  replace, medical/psychological care).
