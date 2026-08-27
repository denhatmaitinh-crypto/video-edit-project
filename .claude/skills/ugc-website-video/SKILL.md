---
name: ugc-website-video
version: 1.0
description: |
  A UGC-style video for any WEBSITE / web app / service / store / product page at a URL — the HERO is what is ON SCREEN: the site shown as REAL captured screenshots (product page, ratings, specs, pricing) while a creator talks to camera the whole time (hook → it solves my problem → result). Screenshots pop in as overlay cards; never a screen recording, never AI-generated UI. Works for a physical product too when it has a store/product URL — shown via its PAGE, in hand only in the closer.
  Triggers: "SaaS UGC" / "UGC SaaS", "UGC ad from this link/URL", "video about my site / app / store / product page", "site tour". A URL whose PAGE should appear on screen routes here; when the URL is only where the product lives and the page is never shown, use the product-side flows (ugc-review-video / ugc-product-video / ugc-unboxing-video / ugc-try-on-video / ugc-tutorial-video). Naming this flow always selects it.
  NOT for: a product with NO URL shown only in-hand; building/editing a website; AI-generating a UI.
---

# ugc-website-video

One continuous **talking-head creator** (9:16, US accent, natural lively UGC pace) narrates
hook → the site solves it → result. The site appears ONLY as **real captured screenshots**
overlaid as large insets over the face (~1.2–1.5s each); the creator's voice runs under everything.
There are **no storyboards** — the creator image seeds Seedance directly. Deliverable:
`output/final_captioned.mp4`, uploaded and delivered as a hosted URL.

**Hard rules (apply everywhere):**
- The screen is ALWAYS real captured pixels. Never AI-generate UI, never animate a screenshot (no
  image-to-video on the site), never ask the user to record their screen.
- Product appears ONLY in the closer (in hand if physical, acting on a blank/turned-away phone if
  SaaS); the body is product-free — and a body clip's VISUAL never even names the product, or the
  model invents a fake one.
- English speech, American accent (never British), unless the user explicitly asks otherwise.
- Captions are ON by default; `caption_mode` picks the layers (`Both` default / `Subtitles` / `Hook`).
- One creator identity: the same `character_media_id` seeds every clip; never regenerate it mid-run.
- Capture fails on the FIRST try (error / bot wall / login / <3 usable cards) → ask the user
  immediately, one question, options "I'll send screenshots" / "Make it without the site". Never
  retry on your own, never pull images from anywhere but the page. No screenshots → deliver
  talking-head-only and say so in the report.

## Sandbox script execution

All shell/media work (capture, ffmpeg, python) runs in the E2B sandbox via `sandbox_exec` — never
locally. The template preinstalls ffmpeg, Playwright+Chromium, faster-whisper (model pre-baked),
Pillow, and the caption fonts.

**The sandbox is EPHEMERAL** — discarded seconds after each call returns; the files YOU write do
NOT survive between calls. Every `sandbox_exec` call must therefore be self-contained:
- The bundle scripts are the one thing that persists: they are preinstalled at
  `${HF_WORKFLOWS}/ugc-website-video/scripts/`, so run them straight from there (never read script
  contents with `get_workflow_bundle_file`, never paste them into commands).
- Bring inputs in and send outputs out INSIDE the same command: pre-create slots with
  `media_upload` BEFORE the call, then in the command `curl -sL -o` the inputs, do the work, and
  `curl -X PUT --upload-file <file> <upload_url>` the outputs; `media_confirm` after.
- Long renders (composite, transcription): `background: true`, poll the log at least every 60s —
  each poll keeps the sandbox alive; the command itself must end by uploading its outputs.
- **Budget the command against the 16000-char cap.** Each presigned PUT URL runs ~1800 chars, so only
  a handful fit alongside the script — pre-create slots only for the artifacts you actually need out
  of that call (the final video, and the stills you will reuse), not for every intermediate.
- **If a `background: true` call comes back `deadline_exceeded`, detaching is broken on that build.**
  Do NOT fall back to `nohup … &` — the sandbox waits for the whole process tree,
  so a shell-backgrounded command times out exactly the same way. Split the work into FOREGROUND
  calls that each finish inside `timeout_seconds` (max 120) and chain them with `&&`, exporting
  every artifact in the same call that produced it.

## Pipeline

**1. Parse.** Extract the site URL (required), duration, creator gender/overrides, and
`caption_mode` (`Both` default / `Subtitles` / `Hook`). Classify the site (`type`:
saas/ecommerce/marketplace/service/portfolio/content, `audience`: b2b/prosumer/consumer, `surface`:
web/mobile-app/dashboard) — steers look and tone only, decided once here. Duration → N clips:

| Total D | N | Clip durations |
|---|---|---|
| 4-15 | 1 | D |
| 16-19 | 2 | balance to >=4s each |
| 20-30 | 2 | 15, D-15 |
| 31-45 | 3 | 15, 15, D-30 |
| 46-60 | 4 | 15, 15, 15, D-45 |
| >60 | ceil(D/15) | 15 each, last >=4s |

**Routing gate.** Stay here when the user names this flow (a hard override) or the SITE is what
should appear on screen — including a physical product shown through its store page. Hand off to
`ugc-review-video` and its siblings only when there is no page to show and the ask is a pure product-in-hand
video; then stop.

**1.1 Persona source.** User attached a person photo → that IS the creator: bring it in
(`media_upload_widget`, or `media_upload` → `curl PUT` → `media_confirm`), capture
`(character_media_id, character_url)`, and skip steps 3 and 3.5. Hard gate, not a question — the
photo's framing quality is the user's own call.

**2. Capture the site** — `references/website-capture.md`. Full-page mobile capture via
`${HF_WORKFLOWS}/ugc-website-video/scripts/capture_site.mjs`, then section stills (`--sections`) of the USEFUL parts (product, reviews,
specs, pricing, individual feature screens). **Capture generously — target ~6-10 stills**, because
card count equals the number of distinct useful stills. Build a section map (top→bottom bands) that
drives both the monologue order and the card order. Minimum 3 usable cards or fall back to asking.

**3. Generate the creator** (skip if provided) — `references/ugc-character.md` carries the creator
rules (identity, beauty floor, variety roll, wardrobe, modesty, safety); layer
`references/saas-ugc-character.md` over it for the SaaS specifics (self-film setting, framing, US
accent, delivery, audio texture to carry into the clip prompt). Product-free, clean person — the site
is composited later, never baked into the character image.

`generate_image` model `soul_2`, `aspect_ratio: "3:4"`, `quality: "2k"`; poll `job_status`;
`(character_media_id, character_url)` = `(job_id, result.url)`. The seed is a 3:4 identity-only
portrait — the 9:16 framing (creator ~2/3 of frame, **head centered, no top headroom**), US accent,
varied lively pace and phone-mic audio are enforced in the step-5 clip prompt, so carry them there.

**3.5 De-slop the creator seed (MANDATORY when generated)** — Soul holds identity but can render
waxy / over-smoothed skin. Two calls, in this order; skip entirely for a user-provided photo, which
is used as-is and never edited.

1. `media_import_url` on `character_url` -> `creator_input_id` (Seedream's `image_references` role
   rejects a `job_id` chain-ref).
2. `generate_image` model `seedream_v5_pro`, `aspect_ratio: "3:4"`, `resolution: "2k"`,
   `medias: [{ value: creator_input_id, role: "image_references" }]`, with this exact prompt:

> KEEP EXACTLY the framing, composition, pose, subject and identity of this vertical portrait — no reframe, no zoom, no crop, no change to the person's face / hair / body / clothing. CHANGE ONLY micro-realism: true-to-life pore-level skin with natural texture and fine vellus hair, real material detail, even natural daytime light with gentle highlight roll-off and faint true sensor noise, a flat authentic iPhone selfie, deep focus. PRESERVE the face's exact shape / width / proportions 1:1 — do NOT squeeze / narrow / slim / stretch the face. AVOID AI-slop: waxy plastic skin, airbrushed poreless skin, beauty-filter smoothing, over-saturation, HDR glow / bloom / halos, oversharpening, teal-orange grade, shallow depth of field, bokeh, cinematic / DSLR look. No added text, no watermark.

The de-slopped output OVERWRITES `(character_media_id, character_url)` and becomes the locked seed
for every clip. Moderation block → retry once on `seedream_v5_lite`; still failing → keep the raw
Soul creator rather than stalling the run.

**4. Write the monologue** — `references/saas-monologue.md`. English always, even when the brief is in
another language. Hook (≤8 words, a hook token, no pointing opener) → body naming the useful sections
in card order, with the FIRST body beat naming the site → closer with the product action. Natural
lively pace **~2.4–2.7 words/sec, with the speed varying within the take**; density <=10s ~22-26
words, 11-12s ~28-33, 13-15s ~35-40 (**hard ceiling ~40 words per 15s** — beyond that the render
crams and talks too fast; aim for the middle). Save the monologue verbatim to `output/script.txt`,
the hook line to `output/hook.txt`, plus the ordered `{section_label, words}` beats — one beat per
captured still.

**5. Generate the talking-head clips** — `references/saas-clip-prompt.md`. ONE continuous shot per
clip: no boards, no intra-clip cuts, no Angle Lock. `generate_video` model `seedance_2_5`,
`aspect_ratio: "9:16"`, `resolution: "1080p"`, the per-clip `duration`,
`mode: "omni_reference"`, `generate_audio: true`, and
`medias: [{ value: character_media_id, role: "image_references" }]` for every clip; the
physical-product closer adds the product image as a second `image_references` entry, imported with
`media_import_url` **from the product page itself** — never hunted from elsewhere, no crop, no
background removal. Submit all N in one parallel batch. Closer returns `nsfw` → retry the closer
only, without product media, neutral gesture, same character. Run the reference's pre-submit
checklist. Frozen-frame QA each clip (one creator, <=2 hands, face matches the reference, no baked
text, clean lips on mid-word frames).

**6. Composite** — `references/screen-broll-and-composite.md`. Concat the clips (stream-copy) →
`output/creator_full.mp4`; build the card images; anchor each card at its narrated word-time
(`t = T × cum_words/total_words`), ~1.2–1.5s each with ~0.3–0.5s clean-face gaps, none during the hook
or the closer; overlay contain-fit into `0.78W × ≤0.60H`, centred slightly up; audio copied →
`output/final.mp4`.

**Degrade case** (capture failed and no user screenshots): skip the overlay entirely — concat the
clips into `output/final.mp4` and go straight to step 7. Talking-head-only is the accepted fallback;
state in the report that the site could not be shown.

**7. Captions** — `references/subtitles.md`, ON by default, layers per `caption_mode`. Raw word-level
Whisper of the FINAL audio → bottom captions (`--size 50 --no-caps`) and/or the top hook plate from
`output/hook.txt`, burned in ONE pass → `output/final_captioned.mp4`. No speech found → burn nothing
and deliver `output/final.mp4`; never guess timing.

**8. Deliver.** Upload from the sandbox: `media_upload` → returned `curl PUT` → `media_confirm`; show
the hosted URL + total duration; hide job ids and intermediate steps. Then ask once: "Publish to
TikTok?" (Yes / No). On yes: `tiktok_accounts` → (`tiktok_connect` if there is no account, share the
authorize link, wait for the OAuth) → `tiktok_prepare_publish` → after the user's explicit
confirmations only, `tiktok_publish` → `tiktok_publish_status`.

## Asking the user

Everything technical is pinned (models, 9:16 1080p, audio on, composite style, N from duration) —
NEVER ask about those, and never offer a full-screen site, scrolling, a generated UI or an animated
screenshot. Ask (one bundled question) only for: the missing URL; the missing duration (offer
10/15/30/45s); the caption style (`Both` default / `Subtitles` / `Hook` — never a "no text" option,
captions are on unless the brief says "no captions"); a capture failure (see the hard rules); and the
TikTok question at the end.

## References

Load via `get_workflow_bundle_file({ workflow: "ugc-website-video", path })`:
- `references/website-capture.md` — capture commands, section map, failure gate
- `references/saas-monologue.md` — arc, hook rules, spoken texture, performed dialogue, density
- `references/ugc-character.md` — creator prompt rules (`soul_2`)
- `references/saas-ugc-character.md` — SaaS framing / setting / accent / delivery / audio carry
- `references/saas-clip-prompt.md` — one continuous clip prompt + the two hard bans
- `references/screen-broll-and-composite.md` — card build + overlay recipe
- `references/subtitles.md` — caption layers and the burn (uses `${HF_WORKFLOWS}/ugc-website-video/scripts/`)


---

## Bundled scripts

This bundle's scripts are ALREADY PRESENT in every sandbox, at
`/home/user/.higgsfield/workflows/ugc-website-video/scripts/`. Run them there with `sandbox_exec`:

```
python3 "$HF_WORKFLOWS/ugc-website-video/scripts/<script>"
```

`$HF_WORKFLOWS` is set inside the sandbox — pass it through
verbatim rather than substituting it. Never read a script's contents into the
conversation, and never write one into the sandbox yourself. Any bare
`scripts/...` path in these instructions means
`$HF_WORKFLOWS/ugc-website-video/scripts/...`.

The directory ships with the sandbox image, so it survives `restart: true`. Write
your own outputs to the working directory, not next to the scripts.

---

## Unlimited generations (`use_unlim`) — applies to every workflow

Free-trial **unlim** makes `generate_image` / `generate_video` / `generate_audio` calls free.
It is **opt-in and the user's call**: pass `use_unlim: true` only when they explicitly ask to
spend their unlimited / free-trial generations. Never add it on your own initiative to save them
credits, and never quietly drop it once they have asked.

When they ask, **send the flag — do not pre-gate on anything.** Neither `unlim.available` nor a
model's `supports_unlim` is a precondition: a request that cannot be served free comes back as a
typed rejection, never as a silent charge, so the backend is the authority and dropping the flag
"to be safe" is what actually bills the user.

What the models tools give you is not a gate but the values to stay inside — one call per model this
run actually uses:

```
models_explore  action: "get"  model_id: "<model this workflow locks>"
```

- the **`Unlim configs`** text at the end of the response — the configurations the grant actually
  covers, one row per covered configuration, keyed by the backend's `job_set_type` (usually but not
  always the model id — match it yourself). A request is free if it satisfies **any one** row of its
  model; a parameter absent from a row has no cap; `max_duration` is a bound in seconds. No rows for
  a model is not a denial — send the flag and let the rejection, if any, tell you why.
- `supports_unlim` and the top-level `unlim` block are context for what you tell the user, not a
  reason to withhold the flag.

Then add `use_unlim: true` to every generate call of the run, staying inside the covered values.
**If this workflow's locked parameters fall outside them** — a resolution the rows don't list, a
duration above `max_duration` — stop and ask: run the covered value, or keep the workflow's value
and pay credits. Never silently downgrade the output, and never silently charge. Swapping models is
not a fix: a workflow's locked models stay locked.

Anything that is not one of the three generate_* tools takes no `use_unlim` — assembly, upscales,
transcription/subtitles and similar are billed as usual, unlim run or not.

Rejections — never retry the same call; each has its own fix:

- `unlim_trial_available` → eligible but the trial is not started. The error carries
  `recovery_tool: show_plans_and_credits` — call it immediately, then wait for the user.
- `unlim_trial_expired` / `unlim_not_eligible` → the allowance is gone. Stop and ask before
  continuing on credits; this can land mid-run, so do not finish the remaining jobs unasked.
- `unlim_not_supported` → that model has no unlim path at all; no plan or trial change fixes it.
- `unlim_config_not_covered` → the model is covered, these parameters are not. Re-read the
  `Unlim configs` rows and retry inside them.

Retries and re-submitted jobs carry the same flag as their original submission.
