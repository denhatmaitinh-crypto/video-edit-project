---
name: ugc-product-video
version: 1.0
description: |
  A UGC-style product-only video — the product is the sole focus, voiceover only, no creator
  speaking on camera (a person appears only as auxiliary hands / POV). Fire only on an explicit
  product-only / no-creator brief; any ambiguity goes to ugc-review-video.
  Triggers: "only the product", "product-only video", "no talking head", "no creator on camera",
  "product is the hero", "remove the model", "just the product on screen".
  A product URL is fine here as the SOURCE of the product (the page itself is never shown on
  screen); a brief about showing the site / app / page itself goes to ugc-website-video.
  NOT for: a creator speaking on camera (ugc-review-video), unboxing as the climax (ugc-unboxing-video),
  step-by-step how-to (ugc-tutorial-video), wearing / fitting (ugc-try-on-video), a site or app URL
  (ugc-website-video).
---

# ugc-product-video

One pipeline for product-focused UGC, every duration. Each **board** is a 21:9 sheet of 4 vertical
9:16 slots — four beats inside ONE Seedance clip, rendered as 4 internal hard cuts. Deliverable:
a hosted 9:16 MP4 (`output/final.mp4`, or `output/final_captioned.mp4` when the user opts into
on-video text).

**Hard rules (apply everywhere):**
- The product is the hero of every slot. A person, when in frame at all, is auxiliary — cropped,
  hands-only, partial body, or first-person POV — never the focal subject, never identity-locked.
- Voiceover ONLY. No on-camera dialogue, no lip-sync, no greetings — ever, not even on Board 1.
- English speech, American accent, unless the user explicitly asks otherwise.
- A product reference is REQUIRED. No product photo and no usable product page means this flow
  cannot run — ask for one, do not invent, generate, or borrow a product image.
- Never bake text into a generation. Any on-screen text is a post-render burn the user asked for.
- The de-slop pass (step 5) is mandatory for every board. Never feed a raw `gpt_image_2` board to
  Seedance.

## Media plumbing

- Generated outputs chain forward by their `job_id`: pass it straight into the next call's
  `medias[].value` (`role: "image"`). No download, no re-upload.
- ONE exception: Seedream i2i (`role: "image_references"`) rejects a `job_id`. Import the board's
  hosted URL with `media_import_url` first and use the returned `media_id`.
- User files come in via `media_upload_widget` (Apps-UI clients) or `media_upload` → `curl PUT` →
  `media_confirm`. A product page image comes in via `media_import_url`.
- Shell work (ffmpeg, python) runs in the E2B sandbox through `sandbox_exec`, never locally. The
  sandbox is EPHEMERAL — your files do not survive between calls, so each call must curl its inputs
  in and PUT its outputs out inside the same command. The bundle scripts are the exception: they are
  preinstalled at `${HF_WORKFLOWS}/ugc-product-video/scripts/` and are always there.

## Duration to boards

| Total D | N | Clip durations |
|---|---|---|
| 4-15 | 1 | D |
| 16-19 | 2 | balance to >=4s each (18 -> 14+4) |
| 20-30 | 2 | 15, D-15 |
| 31-45 | 3 | 15, 15, D-30 |
| 46-60 | 4 | 15, 15, 15, D-45 |
| >60 | ceil(D/15) | 15 each, last >=4s |

## The 4-slot arc

Board 1 always carries the canonical arc; boards 2..N continue with further demo angles,
conditioned on the previous board's last slot.

| Slot | Role | Frame |
|---|---|---|
| 1 | PRODUCT-INTRO | Product in its native context, not yet in use. Person absent, or a hand at the edge. |
| 2 | PRODUCT-DEMO-A | Product in active use, first demonstration angle (pick from the product's real mechanic). |
| 3 | PRODUCT-DEMO-B | Active use again, materially different from slot 2 — different action, scale, or context. |
| 4 | PRODUCT-RESULT | The visible outcome, or a hero shot in a clearly different framing from slot 1. |

## Pipeline

**1. Parse.** Pull the product (photo or URL) and the duration. Compute N and the per-clip
durations from the table. Missing duration or product goes into the single intake question below.

**2. Product intake** — `references/product-intake.md`. Both paths (attached photo / page URL) end
in `product_media_id`, the canonical `product_description`, `tier`, and `category`. Decide them
once here; nothing downstream re-detects them.

Also derive `voice_gender` from the product: female-coded (women's cosmetics, apparel, tailored
fragrance) -> `female`; male-coded -> `male`; unisex or neutral (electronics, food, kitchen,
fitness, cars, home) -> pick one at random. It drives BOTH the off-screen voice AND the gender of
any auxiliary person in frame — never mix the two inside one prompt.

**3. Write the voiceover.** Density: <=10s ~ 12-20 words, 11-12s ~ 20-28, 13-15s ~ 28-35. Sum
across clips, then split into N board segments and mentally into 4 slot beats each. Sensory and
functional language ("the cordless lift is stupid easy", "holds even on shag"), never generic
praise. Anti-slop: no "literally / obsessed / game-changer / holy grail / changed my life / hits
different", no corporate words (elevate / seamless / effortless), no "Hey guys"-class opener. Every
claim carries one concrete — unless the user supplied an approved-claims list, in which case only
those exact strings may be used and nothing gets invented to satisfy this rule. Save the full
voiceover verbatim to `output/script.txt` (the caption step reads it).

**4. Generate boards sequentially** — `references/ugc-product-boards.md`. `generate_image`, model
`gpt_image_2`, `aspect_ratio: "21:9"`, `resolution: "2k"`, `quality: "high"`. Board 1 medias:
`[product]`. Boards 2..N: `[product, previous_board_job_id]` plus an explicit instruction to
preserve product, location, and lighting from the reference board and pick the action up from its
last slot. Poll `job_status`; keep `(board_K_media_id, board_K_url)` = `(job_id, result.url)`.

**5. De-slop every board (MANDATORY)** — two calls, in this order:

1. `media_import_url` on `board_K_url` -> `board_K_input_id`.
2. `generate_image` with model `seedream_v5_pro`, `aspect_ratio: "21:9"`, `resolution: "2k"`,
   `medias: [{ value: board_K_input_id, role: "image_references" }]`, and this exact prompt:

> KEEP EXACTLY the framing, composition, slot layout, camera distances, poses, subjects and product of this horizontal storyboard sheet and every one of its side-by-side vertical slots — no reframe, no zoom, no crop, no re-layout, no change to the scene, to any person's face / hair / body, or to the product design. CHANGE ONLY micro-realism, applied identically in every slot: true-to-life pore-level skin with natural texture and fine vellus hair, real material detail, even natural daytime light with gentle highlight roll-off and faint true sensor noise, a flat authentic iPhone photo, deep focus. PRESERVE each face's exact shape / width / proportions 1:1 — do NOT squeeze / narrow / slim / stretch any face. AVOID AI-slop: waxy plastic skin, airbrushed poreless skin, beauty-filter smoothing, over-saturation, HDR glow / bloom / halos, oversharpening, teal-orange grade, shallow depth of field, bokeh, cinematic / DSLR look. Keep the product blank / unbranded, no added text, no watermark, no baked slot labels.

The de-slopped output OVERWRITES `(board_K_media_id, board_K_url)` — steps 6 and 7 must chain the
cleaned board, and for K>1 the `previous_board` fed into step 4 is the cleaned board K-1. On a
moderation block retry once on `seedream_v5_lite`; if it still fails, continue with the raw board
rather than stalling the run.

**6. Write the clip prompts** — `references/ugc-product-clip-prompt.md`, one prompt per board, all
written before any submission. Pass it the board's slot intents, the product description, the
board's voiceover segment, `voice_gender`, K, N, and the clip duration. Arc role is
`BOARD_1_PRODUCT_DEMO` for K=1 and `BOARD_K_PRODUCT_DEMO` for K>1 — no HOOK / MAIN / CLOSER values
in this flow.

**7. Submit the clips.** `generate_video`, model `seedance_2_5`, `aspect_ratio: "9:16"`,
`resolution: "1080p"`, the per-clip `duration`, `mode: "omni_reference"`,
`generate_audio: true`, `medias: [board_K, product]`. One call per board, all issued in ONE
parallel batch. Seedance renders the voiceover natively — no separate `generate_audio` call.

**Frozen-frame QA on every clip, before stitching or showing anything.** Step through evenly
spaced stills plus every product close-up and check by eye: exactly ONE hero product (no clones);
hands <=2 per person, mirrors and frame edges included; absent features stayed absent (no cord or
button on a product sold on not having one); prop states consistent (a cap is ON or OFF, never
both); the label is not gibberish, mirrored, or a real other brand; product scale matches the
holding hand; no baked text. A staging failure means fixing the prompt and re-rolling THAT clip.

**8. Stitch and deliver.**
- N == 1: the clip is already the deliverable. No sandbox needed — show its hosted URL.
- N >= 2: pre-create a `media_upload` slot, then ONE `sandbox_exec` call that curls the N clips in
  board order, concatenates with stream copy (`ffmpeg -f concat -safe 0 -i clips.txt -c copy
  output/final.mp4`, hard cuts only, no transitions), and PUTs the result to the slot; then
  `media_confirm`. Use `background: true` and poll at least every 60s — and if that call comes back
  `deadline_exceeded`, detaching is broken on that build: split the work into FOREGROUND calls that
  each finish inside `timeout_seconds` (max 120). Do NOT fall back to `nohup … &`; the sandbox waits
  for the whole process tree, so a shell-backgrounded command times out the same way.

Report the hosted URL and the total duration. Hide job ids and intermediate steps.

**9. On-video text (opt-in, at the end).** Once `output/final.mp4` exists, ask ONE bundled question
— unless the brief already answered it: on-video text (`Subtitles` / `Hook` / `Both` / `No text`,
default No text) and whether they want a post package. Text runs through
`references/subtitles.md`, whose timing comes from a word-level transcript of the FINAL audio —
never planned beats. Deliverable becomes `output/final_captioned.mp4`, with `output/final.mp4` kept
alongside.

**Post package (only if asked):** chat text, never burned — one comment-bait caption line, 3-5
hashtags (2 niche + 1-2 broad), a pinned first comment answering the caption's loop, and a one-line
loop note.

## Asking the user

Everything technical is pinned — models per step, 9:16 output, 21:9 boards, 1080p, audio on,
`medias` shape, N from duration, hard cuts. NEVER ask about those, and never offer a fork
("21:9?", "with or without audio?", "which video model?", "train a Soul identity?" — this flow has
no character at all). Bundle the real gaps into ONE question: the duration (offer 10s / 15s / 30s /
45s) and the product (URL or photo). The step-9 delivery question is the one sanctioned extra ask.

## Critical rules

- Product Angle Lock in every board prompt — only the side visible in the reference.
- Any person in frame stays auxiliary and silent; identity is not preserved across boards.
- `Hard cut to.` markers belong only in clip prompts, never in board prompts.
- Weight and grip physics: heavy items (appliance, >=1L bottle, toolbox-class) need two hands plus
  visible facial strain; bulky-but-light needs two hands without strain; light items one relaxed
  hand; tiny items pinched between thumb and index close to the lens. Never balance heavy or paired
  items on one palm.
- Two-handed actions force a static camera; a selfie POV leaves only one hand free.

## References

Load with `get_workflow_bundle_file({ workflow: "ugc-product-video", path })`:
- `references/product-intake.md` — product normalization, both input paths, staging contract
- `references/ugc-product-boards.md` — the 4-slot board prompt rules (`gpt_image_2`)
- `references/ugc-product-clip-prompt.md` — the Seedance clip prompt rules
- `references/subtitles.md` — the opt-in caption burn (uses `${HF_WORKFLOWS}/ugc-product-video/scripts/`)

Do NOT reach for a sibling flow's references — the board and clip rules here are self-contained and
the sibling files (talking-head, unboxing, tutorial, try-on) contradict them.


---

## Bundled scripts

This bundle's scripts are ALREADY PRESENT in every sandbox, at
`/home/user/.higgsfield/workflows/ugc-product-video/scripts/`. Run them there with `sandbox_exec`:

```
python3 "$HF_WORKFLOWS/ugc-product-video/scripts/<script>"
```

`$HF_WORKFLOWS` is set inside the sandbox — pass it through
verbatim rather than substituting it. Never read a script's contents into the
conversation, and never write one into the sandbox yourself. Any bare
`scripts/...` path in these instructions means
`$HF_WORKFLOWS/ugc-product-video/scripts/...`.

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
