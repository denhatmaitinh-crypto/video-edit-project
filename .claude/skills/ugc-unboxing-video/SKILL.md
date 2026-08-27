---
name: ugc-unboxing-video
version: 1.0
description: |
  A UGC-style unboxing video — a creator opens a package on camera with the product reveal as the
  climax (first-reaction / haul / PR-drop energy).
  Triggers only with ALL of: (a) unboxing / reveal / first-reaction intent, (b) UGC framing (UGC /
  creator / tiktok / "haul" / "PR drop" / "video of me unboxing" / "opening the box"), (c) a specific product (photo,
  URL, or "this/our/my X").
  A product URL is fine here as the SOURCE of the product (the page itself is never shown on
  screen); a brief about showing the site / app / page itself goes to ugc-website-video.
  NOT for: a talking-head review with no unboxing arc (ugc-review-video), product-only with no creator
  (ugc-product-video), step-by-step how-to (ugc-tutorial-video), wearing / fitting
  (ugc-try-on-video), a site or app URL (ugc-website-video).
---

# ugc-unboxing-video

The unboxing pipeline: a creator opens a package and the reveal is the climax. Each **board** is a
21:9 sheet of 4 vertical 9:16 slots — four beats inside ONE Seedance clip, rendered as 4 internal
hard cuts. Deliverable: a hosted 9:16 MP4 (`output/final.mp4`, or `output/final_captioned.mp4` when
the user opts into on-video text).

**Hard rules (apply everywhere):**
- Board 1 slot 1 ALWAYS shows the sealed delivery box with the product NOT visible. The reveal
  lands in slot 2.
- Box disappearance is one-way: slot 1 sealed, slot 2 just-emptied at the frame edge or already
  gone, slots 3-4 gone. Never re-introduce the box.
- One creator identity: the same `character_media_id` seeds every board and clip; never regenerate
  it mid-run except through the re-roll protocol below.
- The de-slop pass (step 6) runs for EVERY board. Never feed a raw `gpt_image_2` board to Seedance.
- Never bake text into a generation. On-video text is a post-render burn the user asked for.
- English speech, American accent, unless the user explicitly asks otherwise.
- No greetings or re-introductions after board 1 — the monologue continues mid-thought.

## Media plumbing

- Generated outputs chain forward by their `job_id` into the next call's `medias[].value`
  (`role: "image"`). No download, no re-upload.
- ONE exception: Seedream i2i (`role: "image_references"`) rejects a `job_id`. Import the board's
  hosted URL with `media_import_url` first and use the returned `media_id`.
- User files (person photo, product photo, real package photo) come in via `media_upload_widget`
  (Apps-UI clients) or `media_upload` → `curl PUT` → `media_confirm`; a product page image via
  `media_import_url`.
- Shell work (ffmpeg, python) runs in the E2B sandbox via `sandbox_exec`, never locally. The sandbox
  is EPHEMERAL for your OWN files — every call curls its inputs in and PUTs its outputs out inside
  the same command. The bundle scripts are the exception: they are preinstalled at
  `${HF_WORKFLOWS}/ugc-unboxing-video/scripts/` and are always there, so just run them from that path.
- You cannot re-inspect a generated image later; the text you wrote about the creator, product, and
  location IS the continuity contract.

## Duration to boards

| Total D | N | Clip durations |
|---|---|---|
| 4-15 | 1 | D |
| 16-19 | 2 | balance to >=4s each (18 -> 14+4) |
| 20-30 | 2 | 15, D-15 |
| 31-45 | 3 | 15, 15, D-30 |
| 46-60 | 4 | 15, 15, 15, D-45 |
| >60 | ceil(D/15) | 15 each, last >=4s |

## The canonical 4-slot arc

Board 1 always carries it; boards 2..N continue past the reveal (exploring, using, demonstrating),
conditioned on the previous board's last slot.

| Slot | Role | Frame |
|---|---|---|
| 1 | PACKED | Creator with the sealed delivery box in front of them — closed, taped, untouched. Product NOT visible. |
| 2 | REVEAL | Product just out of the box, held or set beside the creator. Box may sit at the frame edge (just emptied) or be gone. Peak surprise. |
| 3 | PRODUCT-FOCUS | The product alone as the hero (close in hands or extended toward the lens). Box gone. |
| 4 | SATISFACTION | Creator settled with the product — confident pose, warm grin, product in hand or beside them. Box gone. |

Arc role passed downstream: `BOARD_1_CANONICAL_UNBOXING` for K == 1, `BOARD_K_POST_REVEAL` for K > 1.

## Pipeline

**1. Parse.** Product (photo or URL), duration, creator gender, an optional real package/box photo,
and any explicit overrides (location, hair, ethnicity, outfit register, mood, props). Compute N and
the per-clip durations. Classify the brief's specificity for the board and clip prompts: `auto`
(1-5 words, no scenario) = full autopilot; `guided` (1-3 sentences of idea, tone, or rough flow) =
preserve the user's tone; `director` (4+ sentences with scenario, shot list, or location sequence) =
map the user's beats 1:1 onto slots.

**2. Product intake** — `references/product-intake.md`. Ends in `product_media_id`, the canonical
`product_description`, `tier`, and `category`, decided once and reused verbatim.

If the user supplied a real package photo, bring it in the same way and keep `package_media_id` —
it becomes the slot-1 PACKED reference. With no package photo, the board prompt falls back to a
generic plain brown taped delivery box; nothing else changes.

**3. Creator.** A person photo attached by the user IS the creator: bring it in, keep
`(character_media_id, character_url)`, skip the generation. Hard gate — do not ask to confirm.

Otherwise generate the creator per `references/ugc-character.md` (beauty floor, variety roll,
wardrobe matrix, modesty, safety): `generate_image`, model `soul_2`, `aspect_ratio: "3:4"`,
`quality: "2k"`; poll `job_status`;
`(character_media_id, character_url)` = `(job_id, result.url)`. MANDATORY when no photo was
attached — boards need a real identity image to lock against, so never describe the creator inline
instead. Wardrobe stays fixed across boards unless the story explicitly changes context.

Accent and quirk are OPT-IN: if the brief names an origin for the creator or asks for "weird" /
"viral" energy, offer it inside the single intake question. Default is neutral English, no quirk. If
opted in, write the persona sentence ONCE and restate it VERBATIM in the character prompt, every
board prompt, and every clip prompt. Text-only accent enforcement lands about one render in three;
if the user can drop a 5-10s voice sample, attach it to the clip generation as an audio reference
("accent and vocal delivery reference only — do not copy words, only the accent, melody, and
timbre"). Offer once, never block.

**4. Write the monologue.** Density: <=10s ~ 12-20 words, 11-12s ~ 20-28, 13-15s ~ 28-35. Split into
N board segments; the slot-level split is the clip prompt's job. Greetings and product introduction
only in board 1.

Craft: the package IS the premise, so there is no product delay to engineer — sharpen instead with
the caved-in confession frame ("I saw this fourteen times on my feed. I caved."), genuine surprise
scripted as a BODY event at the reveal, ONE "but then" beat, and the CTA riding inside the
resolution. The default opener is an impact action landing mid-event over the box; alternate flavors
that still fit a sealed-box first cut are a mid-sentence confession opened on word four, a hostile
open aimed at the viewer, a result-first line that refers backwards to what made them cave, or one
short performed hold (<=0.7s) locked on the box before the first line.

Anti-slop on every line: never open with `Okay wait / Okay so / OMG / Hey guys / So basically / Stop
scrolling / You NEED this / Story time`; never use "literally", "obsessed", "game-changer", "holy
grail", "changed my life", "hits different", or corporate words (elevate / seamless / effortless).
Friction openers beat enthusiasm ("I almost returned this."). Every claim carries one concrete —
unless the user supplied an approved-claims list, in which case only those exact strings are allowed
and nothing is invented to satisfy this rule. At most ONE peak reaction per clip in the monologue.
Cut echoes and repeats first.

**First-word constraint (every board segment):** the literal first word must be hook content — never
`OK / Okay / Okay so / Alright / Alright so / So / Yeah so / Right so / Um / Well / Like / Wait /
Wait what / Hold on`. Those read as recording warmup; they are fine mid-sentence later.

Save the full monologue verbatim to `output/script.txt`, and the hook headline to `output/hook.txt`
if a plate might be burned later.

**5. Generate boards sequentially** — `references/ugc-unboxing-board.md`. `generate_image`, model
`gpt_image_2`, `aspect_ratio: "21:9"`, `resolution: "2k"`, `quality: "high"`. Medias in this order,
matching the `@ImageN` declarations the prompt opens with: `[product, character]`, plus
`package_media_id` when a real package photo exists, plus `previous_board_job_id` when K > 1. Drop
entries that do not apply and shift the numbering. Pass K, N, the arc role, the clip duration,
`tier`, the specificity tier, and the product description. Poll `job_status`; keep
`(board_K_media_id, board_K_url)` = `(job_id, result.url)`.

**6. De-slop every board (MANDATORY)** — two calls, in this order:

1. `media_import_url` on `board_K_url` -> `board_K_input_id`.
2. `generate_image` with model `seedream_v5_pro`, `aspect_ratio: "21:9"`, `resolution: "2k"`,
   `medias: [{ value: board_K_input_id, role: "image_references" }]`, and this exact prompt:

> KEEP EXACTLY the framing, composition, slot layout, camera distances, poses, subjects and product of this horizontal storyboard sheet and every one of its side-by-side vertical slots — no reframe, no zoom, no crop, no re-layout, no change to the scene, to any person's face / hair / body, or to the product design. CHANGE ONLY micro-realism, applied identically in every slot: true-to-life pore-level skin with natural texture and fine vellus hair, real material detail, even natural daytime light with gentle highlight roll-off and faint true sensor noise, a flat authentic iPhone photo, deep focus. PRESERVE each face's exact shape / width / proportions 1:1 — do NOT squeeze / narrow / slim / stretch any face. AVOID AI-slop: waxy plastic skin, airbrushed poreless skin, beauty-filter smoothing, over-saturation, HDR glow / bloom / halos, oversharpening, teal-orange grade, shallow depth of field, bokeh, cinematic / DSLR look. Keep the product blank / unbranded, no added text, no watermark, no baked slot labels.

The de-slopped output OVERWRITES `(board_K_media_id, board_K_url)`; for K>1 the `previous_board` fed
into step 5 is the cleaned board K-1. Moderation block → retry once on `seedream_v5_lite`; still
failing → continue with the raw board rather than stalling.

**7. Write the clip prompts** — `references/ugc-unboxing-clip.md`, one per board, all written before
any submission. Give it K, N, the clip duration, the arc role, this board's monologue segment
verbatim, the specificity tier, and the board / character / product references.

**8. Submit the clips.** `generate_video`, model `seedance_2_5`, `aspect_ratio: "9:16"`,
`resolution: "1080p"`, the per-clip `duration`, `mode: "omni_reference"`,
`generate_audio: true`, `medias: [board_K, character, product]`. One call per board, all in ONE
parallel batch. Seedance renders the speech natively — no separate `generate_audio` call.

**Frozen-frame QA on every clip, before stitching or showing anything.** Evenly spaced stills, every
product close-up, plus 2-3 mid-word frames: exactly ONE hero product; hands <=2 per person (mirrors
and edges included); the box follows the disappearance rule and never returns; absent features
stayed absent; prop states consistent (a cap is ON or OFF, never both); the label is not gibberish,
mirrored, or another real brand; product scale matches the holding hand; lips free of doubled edges
or smears on mid-word frames; the face matches the character reference; no baked text. Staging
failure → fix the prompt and re-roll THAT clip; lip slop → cut spoken words first.

**9. Stitch and deliver.**
- N == 1: the clip is the deliverable — show its hosted URL, no sandbox needed.
- N >= 2: pre-create a `media_upload` slot, then ONE `sandbox_exec` call that curls the N clips in
  board order, concatenates with stream copy (`ffmpeg -f concat -safe 0 -i clips.txt -c copy
  output/final.mp4`, hard cuts only, no transitions), and PUTs the result to the slot; then
  `media_confirm`. Use `background: true` and poll at least every 60s — and if that call comes back
  `deadline_exceeded`, detaching is broken on that build: split the work into FOREGROUND calls that
  each finish inside `timeout_seconds` (max 120). Do NOT fall back to `nohup … &`; the sandbox waits
  for the whole process tree, so a shell-backgrounded command times out the same way.

Report the hosted URL and the total duration. Hide job ids and intermediate steps.

**10. On-video text (opt-in, at the end).** Ask ONE bundled question unless the brief answered it:
on-video text (`Subtitles` / `Hook` / `Both` / `No text`, default No text) and whether they want a
post package. Text runs through `references/subtitles.md` — timing from a word-level transcript of
the FINAL audio, never planned beats. Deliverable becomes `output/final_captioned.mp4`, with
`output/final.mp4` kept alongside.

**Post package (only if asked):** chat text, never burned — one comment-bait caption line, 3-5
hashtags (2 niche + 1-2 broad), a pinned first comment, and a one-line loop note.

## Asking the user

Everything technical is pinned — models per step, 9:16 output, 21:9 boards, 1080p, audio on,
`medias` shape, N from duration, hard cuts, the canonical 4-slot arc, no identity training. NEVER ask
about those and never offer an "alternative arc" fork. Bundle the real gaps into ONE question:

- **Duration** — offer 10s / 15s / 30s / 45s.
- **Product** — the URL or a photo.
- **Real package photo** — offer "I'll attach a photo of the package" / "use a generic plain brown
  delivery box". A bare "yes" is an INCOMPLETE state: ask once more for the actual attachment and
  WAIT — do not start the creator step on a promise. If they change their mind, set no package
  reference and continue silently with the generic box.
- The optional accent/quirk offer.

The step-10 delivery question is the one sanctioned extra ask.

## Failure handling — character re-roll

If board generation or clip submission fails twice in a row on the same call, assume the Soul
character render was rejected. Re-submit the SAME character prompt from step 3 (new seed, same
described person), capture fresh `(character_media_id, character_url)`, discard every
`board_K_media_id` (they referenced the rejected character), and re-run from step 5. Cap at 2
re-rolls per session, then stop and report — never fall through to `generate_video` with an empty
`medias` array, which silently becomes text-to-video of the wrong thing.

## Critical rules

- Product analysis happens ONCE; `tier`, `category`, and the product description are reused verbatim.
- The `@ImageN` declarations that open a board prompt must match the `medias` order exactly.
- `Hard cut to.` markers belong only in clip prompts, never in board prompts.
- Never write a `@voice` or audio-reference note into a prompt string — audio references are attached
  to the generation, not described in the prompt.
- Weight and grip physics: heavy items need two hands plus visible strain; light items one relaxed
  hand; paired products are never balanced on one palm.

## References

Load with `get_workflow_bundle_file({ workflow: "ugc-unboxing-video", path })`:
- `references/product-intake.md` — product normalization, both input paths, staging contract
- `references/ugc-character.md` — creator prompt rules (`soul_2`)
- `references/ugc-unboxing-board.md` — the 4-slot board prompt rules (`gpt_image_2`), box logic
- `references/ugc-unboxing-clip.md` — the Seedance clip prompt rules (4 internal hard cuts)
- `references/subtitles.md` — the opt-in caption burn (uses `${HF_WORKFLOWS}/ugc-unboxing-video/scripts/`)

Do NOT reach for a sibling flow's references — the rules here are self-contained and the sibling
files (talking-head, product-only, tutorial, try-on) contradict them.


---

## Bundled scripts

This bundle's scripts are ALREADY PRESENT in every sandbox, at
`/home/user/.higgsfield/workflows/ugc-unboxing-video/scripts/`. Run them there with `sandbox_exec`:

```
python3 "$HF_WORKFLOWS/ugc-unboxing-video/scripts/<script>"
```

`$HF_WORKFLOWS` is set inside the sandbox — pass it through
verbatim rather than substituting it. Never read a script's contents into the
conversation, and never write one into the sandbox yourself. Any bare
`scripts/...` path in these instructions means
`$HF_WORKFLOWS/ugc-unboxing-video/scripts/...`.

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
