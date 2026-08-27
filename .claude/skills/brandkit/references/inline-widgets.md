# Inline reviews in chat

Show every Brandkit review stage directly inside chat as rendered images with download links. Editable HTML/SVG files remain downloads; the inline image is the immediate review surface.

## Publishing a review board

`${HF_WORKFLOWS}/brandkit/scripts/brandkit.py preview` returns sandbox-local HTML paths. In the SAME `sandbox_exec` batch (the sandbox is discarded seconds after each call):

1. Screenshot each board to PNG with the preinstalled Playwright CLI:

   ```bash
   npx playwright screenshot --viewport-size=1200,900 --full-page \
     "file://$PWD/brandkit/reviews/<board>.html" "brandkit/reviews/<board>.png"
   ```

2. Request presigned URLs with `media_upload` for every PNG and HTML file (PNG → image, HTML → file), run the returned `curl` PUT commands inside the sandbox, then call `media_confirm` (`type: "image"` for PNGs, `type: "file"` for HTML).

Because `media_upload` runs before the `curl` step, order one batch as: render boards + screenshots first, then `media_upload`, then a second `sandbox_exec` immediately after with the `curl` uploads (back-to-back calls reuse the live sandbox), then `media_confirm`.

## Rules

- Present each option as a markdown image of its board PNG followed by its “Download editable HTML” link:

  ```markdown
  ### Option 1 — <name>
  ![<name> board](<confirmed PNG url>)
  [Open full board](<confirmed HTML url>) · [Download editable HTML](<confirmed HTML url>)
  ```

- Replace every placeholder with the actual confirmed URL. For 2–3 options, repeat the complete block, stacked vertically in one message.
- The PNG is a faithful screenshot of the deterministic HTML board — never a generated image, collage, or re-drawn approximation.
- Do not create fake buttons or selection controls. Ask for feedback in normal chat after the review and STOP.
- Never print filenames or bare URLs without rendering the associated visual, except final brandbook delivery, which intentionally contains only PPTX and PDF links.
- Do not make the user open each file to understand it.

Before writing a preview input, load [exact preview payloads](preview-payloads.md) and copy the complete shape for that stage.

## Recraft logo review

The HTML preview script does not handle logo creation or comparison. Show the three Recraft results directly. This review remains mandatory in explicit auto/no-question mode; never replace it with a prose list of bare SVG URLs:

```markdown
### Candidate 1 — <short name>
![Logo candidate 1](<recraft result url>)
[Download SVG](<recraft result url>)
```

Repeat for candidates 2 and 3. If your client does not render the SVG result URL inline, rasterize a preview in the sandbox with `rsvg-convert` (2048×2048 PNG), upload it as the review image, and keep the original SVG URL as the download link.

Do not redraw, normalize, recolor, or otherwise modify the returned Recraft SVGs; a rasterized copy is a review preview only, never the asset.

## Logo color-revision/export review

When `${HF_WORKFLOWS}/brandkit/scripts/brandkit.py logo-export` returns the color pair and any explicitly requested monochrome/reverse or single-color SVG/2048 PNG pairs, upload only the files intended for the user (SVGs keep exact bytes as `type: "file"`; PNGs confirm as `type: "image"`):

- With `delivery: "internal"`, show only the selected full-color preview and do not link the internal files.
- With `delivery: "user"`, show each PNG inline and link every returned SVG and PNG variant.
- State that geometry is unchanged and the PNG is a review/export preview.
- Never show only PNG filenames or hide the SVG variants.

## Review messages

After palette review:

> Take your time. Reply with the palette you prefer and any colors you want changed.

After logo review:

> Take your time reviewing the three marks. Reply with the direction you prefer and any shape or balance changes.

After typography review:

> Review how each type pair works with the selected mark and palette. Reply with your preferred direction or changes.

After showing the combined Essential Kit review:

> Does the complete logo, palette, and typography system feel right together? Approve it or tell me which element should change.

Each message ends the turn. Never continue to the next stage until the user responds.
