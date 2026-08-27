---
name: ugc-tutorial-video
version: 1.0
description: |
  A UGC-style tutorial video — a creator demonstrates step-by-step use of a specific product, with
  on-screen "Step N" captions baked into the frames.
  Triggers only with ALL of: (a) tutorial / how-to / step-by-step intent, (b) UGC framing (UGC /
  creator / tiktok / "video of me"), (c) a specific product (photo, URL, or "this/our/my X").
  A product URL is fine here as the SOURCE of the product (the page itself is never shown on
  screen); a brief about showing the site / app / page itself goes to ugc-website-video.
  NOT for: a talking-head review with no step structure (ugc-review-video), unboxing as the climax
  (ugc-unboxing-video), wearing / fitting (ugc-try-on-video), product-only with no creator
  (ugc-product-video), a site or app URL (ugc-website-video).
---

# ugc-tutorial-video

One pipeline for UGC tutorial videos, every duration. Each **board** is a 21:9 sheet of 4 vertical
9:16 slots — four tutorial STEPS inside ONE Seedance clip, rendered as 4 internal hard cuts. Every
slot carries a baked `Step N — Heading` caption. Deliverable: a hosted 9:16 MP4
(`output/final.mp4`, or `output/final_captioned.mp4` when the user opts into extra on-video text).

**Hard rules (apply everywhere):**
- Steps must be physically real for the actual product. Never invent a step the product cannot do.
- Step numbering is GLOBAL across the video: board J covers steps 4*(J-1)+1 .. 4*J. Total steps =
  4 * N.
- Each slot shows exactly ONE caption, `"Step N — Heading"`, English Title Case, en-dash, with
  identical typography across all four slots of a board. No other on-image text anywhere.
- One creator identity: the same `character_media_id` seeds every board and clip; never regenerate
  it mid-run.
- CTA tail is video-level and only on the LAST cut of the LAST board: ~0.5-1s talking-head selfie +
  downward hand gesture + a short English CTA. Never a fifth step, never a board caption.
- English everywhere — captions, monologue, CTA, prompts.
- No greetings after Board 1 / slot 1; later slots continue mid-thought.

## Media plumbing

- Generated outputs chain forward by their `job_id` into the next call's `medias[].value`
  (`role: "image"`). No download, no re-upload.
- ONE exception: Seedream i2i (`role: "image_references"`) rejects a `job_id`. Import the board's
  hosted URL with `media_import_url` first and use the returned `media_id`.
- User files come in via `media_upload_widget` (Apps-UI clients) or `media_upload` → `curl PUT` →
  `media_confirm`; a product page image via `media_import_url`.
- Shell work (ffmpeg, python) runs in the E2B sandbox via `sandbox_exec`, never locally. The sandbox
  is EPHEMERAL for your OWN files — every call curls its inputs in and PUTs its outputs out inside
  the same command. The bundle scripts are the exception: they are preinstalled at
  `${HF_WORKFLOWS}/ugc-tutorial-video/scripts/` and are always there, so just run them from that path.

## Duration to boards and steps

| Total D | N | Clip durations | Total steps |
|---|---|---|---|
| 4-15 | 1 | D | 4 |
| 16-19 | 2 | balance to >=4s each (18 -> 14+4) | 8 |
| 20-30 | 2 | 15, D-15 | 8 |
| 31-45 | 3 | 15, 15, D-30 | 12 |
| 46-60 | 4 | 15, 15, 15, D-45 | 16 |
| >60 | ceil(D/15) | 15 each, last >=4s | 4 * ceil(D/15) |

## Pipeline

**1. Parse.** Product (photo or URL), duration, plus any instructions / manual / usage notes the
user pasted. Compute N, the per-clip durations, and `total_steps = 4 * N`.

**2. Product intake** — `references/product-intake.md`. Ends in `product_media_id`, the canonical
`product_description`, `tier`, and `category`, decided once.

**3. Usage analysis (mandatory, before any board).** Build `total_steps` chronological, physically
real usage steps from the product category, its container / applicator, the user's notes, and the
brief. Fewer natural steps than needed → pad with setup steps at the front and finishing steps at
the end. More → merge adjacent micro-actions. An explicit user step list maps 1:1 in their order,
no re-derivation.

Output: `step_captions[1..total_steps]`, each `"Step N — Heading"` where the heading is 1-4 words
of Title Case English ("Step 1 — Apply Primer", "Step 5 — Pat It In"). Slice it into per-board
groups of four.

**4. Creator.** A person photo attached by the user IS the creator: bring it in
(`media_upload_widget` or `media_upload` → `media_confirm`), keep
`(character_media_id, character_url)`, and skip the generation. This is a hard gate, not a
question — do not ask to confirm, and the photo's framing quality is the user's own call.

Otherwise generate once per `references/soul-v2-ugc-character.md`: `generate_image`, model `soul_2`,
`aspect_ratio: "3:4"`, `quality: "2k"`; poll `job_status`;
`(character_media_id, character_url)` = `(job_id, result.url)`. Wardrobe stays fixed across boards
unless the story explicitly changes context. Record the traits you wrote — you cannot re-inspect
the image later, so that text is the continuity contract.

Accent and quirk are OPT-IN: if the brief names an origin for the creator or asks for "weird" /
"viral" energy, offer it inside the single intake question (accent consent + one quirk). Default is
neutral English, no quirk. If opted in, write the persona sentence ONCE and restate it VERBATIM in
the character prompt, every board prompt, and every clip's delivery framing — there are no
enhancers here to carry it for you. Text-only accent enforcement lands roughly one render in three;
if the user can drop a 5-10s voice sample, attach it to the clip generation as an audio reference
("accent and vocal delivery reference only — do not copy words, only the accent, melody, and
timbre"). Offer that once, never block on it.

**5. Write the monologue.** Density: <=10s ~ 12-20 words, 11-12s ~ 20-28, 13-15s ~ 28-35. Split into
N board segments, then into 4 step beats each. A step beat says WHAT the creator is doing, concise
and conversational ("Now I press the pump twice.", "I rub it in like this."). Tutorial steps are the
spine — do not impose a story shape. Anti-slop: no "Okay wait / Okay so / OMG / Hey guys" openers,
and never "literally / obsessed / game-changer / holy grail / changed my life / hits different" or
corporate words (elevate / seamless / effortless). Every claim carries one concrete — unless the
user supplied an approved-claims list, in which case only those exact strings are allowed and
nothing is invented to satisfy this rule. Reserve ~0.5-1s at the very end of the final board for the
CTA ("Link in bio." / "Follow me." / "Subscribe!"); if time is tight, cut monologue and use the
shortest. Save the full monologue verbatim to `output/script.txt`.

**6. Generate boards sequentially** — `references/ugc-tutorial-boards.md`. `generate_image`, model
`gpt_image_2`, `aspect_ratio: "21:9"`, `resolution: "2k"`, `quality: "high"`. Board 1 medias:
`[product, character]`. Boards 2..N: `[product, character, previous_board_job_id]`, plus an explicit
instruction to preserve identity, location, lighting, wardrobe, and product state from the reference
board and to continue chronologically from its last slot. Pass this board's four `step_captions`.
Poll `job_status`; keep `(board_K_media_id, board_K_url)` = `(job_id, result.url)`.

**7. De-slop every board (MANDATORY)** — two calls, in this order:

1. `media_import_url` on `board_K_url` -> `board_K_input_id`.
2. `generate_image` with model `seedream_v5_pro`, `aspect_ratio: "21:9"`, `resolution: "2k"`,
   `medias: [{ value: board_K_input_id, role: "image_references" }]`, and this exact prompt — note
   it preserves the baked Step captions:

> KEEP EXACTLY the framing, composition, slot layout, camera distances, poses, subjects, product AND any on-frame step captions of this horizontal storyboard sheet and every one of its side-by-side vertical slots — no reframe, no zoom, no crop, no re-layout, no change to the scene, to any person's face / hair / body, to the product design, or to existing on-frame text. CHANGE ONLY micro-realism, applied identically in every slot: true-to-life pore-level skin with natural texture and fine vellus hair, real material detail, even natural daytime light with gentle highlight roll-off and faint true sensor noise, a flat authentic iPhone photo, deep focus. PRESERVE each face's exact shape / width / proportions 1:1 — do NOT squeeze / narrow / slim / stretch any face. AVOID AI-slop: waxy plastic skin, airbrushed poreless skin, beauty-filter smoothing, over-saturation, HDR glow / bloom / halos, oversharpening, teal-orange grade, shallow depth of field, bokeh, cinematic / DSLR look. Keep the product blank / unbranded, no NEW added text, no watermark.

The de-slopped output OVERWRITES `(board_K_media_id, board_K_url)`; for K>1 the `previous_board`
fed into step 6 is the cleaned board K-1. Moderation block → retry once on `seedream_v5_lite`;
still failing → continue with the raw board rather than stalling.

**8. Write the clip prompts** — `references/ugc-tutorial-clip-prompt.md`, one per board, all written
before any submission. Give it the board's step captions, the monologue segment, the product
description, K, N, the clip duration, and `is_last_board` (true only for K == N — that flag is what
adds the CTA tail). Arc role is `BOARD_TUTORIAL_STEPS` for every board.

**9. Submit the clips.** `generate_video`, model `seedance_2_5`, `aspect_ratio: "9:16"`,
`resolution: "1080p"`, the per-clip `duration`, `mode: "omni_reference"`,
`generate_audio: true`, `medias: [board_K, character, product]`. One call per board, all in ONE
parallel batch. Seedance renders the speech natively — no separate `generate_audio` call.

**Frozen-frame QA on every clip, before stitching or showing anything.** Evenly spaced stills, every
product close-up, plus 2-3 mid-word frames: exactly ONE hero product; hands <=2 per person (mirrors
and edges included); absent features stayed absent; prop states consistent (cap ON or OFF, never
both); label not gibberish, mirrored, or another real brand; product scale matches the hand; lips
free of doubled edges or smears on mid-word frames; the face matches the character reference; the
baked Step captions still read correctly and no NEW text appeared. Staging failure → fix the prompt
and re-roll THAT clip; lip slop → cut spoken words first.

**10. Stitch and deliver.**
- N == 1: the clip is the deliverable — show its hosted URL, no sandbox needed.
- N >= 2: pre-create a `media_upload` slot, then ONE `sandbox_exec` call that curls the N clips in
  board order, concatenates with stream copy (`ffmpeg -f concat -safe 0 -i clips.txt -c copy
  output/final.mp4`, hard cuts only, no transitions), and PUTs the result to the slot; then
  `media_confirm`. Use `background: true` and poll at least every 60s — and if that call comes back
  `deadline_exceeded`, detaching is broken on that build: split the work into FOREGROUND calls that
  each finish inside `timeout_seconds` (max 120). Do NOT fall back to `nohup … &`; the sandbox waits
  for the whole process tree, so a shell-backgrounded command times out the same way.

Report the hosted URL and the total duration. Hide job ids and intermediate steps.

**11. Extra on-video text (opt-in, at the end).** The Step captions are already baked in at the top
of every slot, so extra text is rarely needed. Ask ONE bundled question unless the brief answered
it: on-video text (`Subtitles` / `Hook` / `Both` / `No text`, default No text) and whether they want
a post package. Prefer **Subtitles** here — `references/subtitles.md` keeps them in the bottom
safe-zone, while a top Hook plate would collide with the baked Step captions; only add a Hook if it
visibly clears them. Timing comes from a word-level transcript of the FINAL audio, never planned
beats. Deliverable becomes `output/final_captioned.mp4`, with `output/final.mp4` kept alongside.

**Post package (only if asked):** chat text, never burned — one comment-bait caption line, 3-5
hashtags (2 niche + 1-2 broad), a pinned first comment, and a one-line loop note.

## Asking the user

Everything technical is pinned — models per step, 9:16 output, 21:9 boards, 1080p, audio on,
`medias` shape, N and step count from duration, hard cuts. NEVER ask about those and never offer a
fork ("21:9?", "with or without audio?", "which model?", "train a Soul identity?" — Soul training
takes longer than the whole video and buys nothing here). Bundle the real gaps into ONE question:
duration (offer 10s / 15s / 30s / 45s), product (URL or photo), and the optional accent/quirk offer.
The step-11 delivery question is the one sanctioned extra ask.

## Critical rules

- Product Angle Lock in every board prompt — only the side visible in the reference.
- `Hard cut to.` markers belong only in clip prompts, never in board prompts.
- Two-handed actions force a static camera; a selfie POV leaves only one hand free.
- Weight and grip physics: heavy items (appliance, >=1L bottle, toolbox-class) need two hands plus
  visible facial strain; bulky-but-light needs two hands without strain; light items one relaxed
  hand; tiny items pinched between thumb and index close to the lens.
- Never skip the usage analysis, and never let a step contradict the product's real mechanics.

## References

Load with `get_workflow_bundle_file({ workflow: "ugc-tutorial-video", path })`:
- `references/product-intake.md` — product normalization, both input paths, staging contract
- `references/soul-v2-ugc-character.md` — creator prompt rules (`soul_2`)
- `references/ugc-tutorial-boards.md` — the 4-slot board prompt rules, including Step caption
  rendering and the per-category font matrix
- `references/ugc-tutorial-clip-prompt.md` — the Seedance clip prompt rules, including the CTA tail
- `references/subtitles.md` — the opt-in caption burn (uses `${HF_WORKFLOWS}/ugc-tutorial-video/scripts/`)

Do NOT reach for a sibling flow's references — the board and clip rules here are self-contained and
the sibling files (talking-head, unboxing, try-on, product-only) contradict them.


---

## Bundled scripts

This bundle's scripts are ALREADY PRESENT in every sandbox, at
`/home/user/.higgsfield/workflows/ugc-tutorial-video/scripts/`. Run them there with `sandbox_exec`:

```
python3 "$HF_WORKFLOWS/ugc-tutorial-video/scripts/<script>"
```

`$HF_WORKFLOWS` is set inside the sandbox — pass it through
verbatim rather than substituting it. Never read a script's contents into the
conversation, and never write one into the sandbox yourself. Any bare
`scripts/...` path in these instructions means
`$HF_WORKFLOWS/ugc-tutorial-video/scripts/...`.

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
