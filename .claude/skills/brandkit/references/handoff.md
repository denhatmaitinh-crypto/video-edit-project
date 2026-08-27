# Brandkit state routing

Brandkit approval state lives in `.brandkit/state.json` inside the sandbox working directory. Drafts never enter it. The script writes atomically and preserves independent logo, palette, typography, visual-axis, and downstream-element revisions.

Run every operation through `sandbox_exec`:

```bash
python3 ${HF_WORKFLOWS}/brandkit/scripts/brandkit.py state --action ACTION [--input INPUT.json]
```

Create payload files with a quoted heredoc (`cat > brandkit/input.json <<'JSON' … JSON`); never interpolate JSON or user text into the shell command arguments.

Before the first state write, load [exact state payloads](state-payloads.md) and copy only the matching complete object shape. Replace values, not keys or nesting.

## State carry protocol (ephemeral sandbox)

The sandbox is discarded seconds after each `sandbox_exec` call finishes. `.brandkit/state.json` does NOT survive between turns. The latest exported state JSON in this conversation is the canonical copy.

- **Restore before use.** Start every batch that reads or writes state by re-creating the file from the last exported copy:

  ```bash
  mkdir -p .brandkit && cat > .brandkit/state.json <<'JSON'
  <latest exported state JSON, verbatim>
  JSON
  ```

  Skip the restore only at the very start of a conversation with no prior exported state (the script then starts from an empty ledger).

- **Chain, don't split.** Combine restore, state actions, script runs, and export into ONE `sandbox_exec` command joined with `&&`. Never assume a file written by a previous call still exists.

- **Export after every write.** End every state-mutating batch with:

  ```bash
  echo '--- BRANDKIT STATE ---' && cat .brandkit/state.json
  ```

  Treat that printed JSON as the new canonical copy and restore from it next time. Never edit the exported JSON by hand; only the state script mutates it.

- **Durable references only.** Store permanent hosted URLs (confirmed uploads, generation result URLs) in state assets — never sandbox-local paths.

## Call moments

### Start of any Brandkit turn

```bash
python3 ${HF_WORKFLOWS}/brandkit/scripts/brandkit.py state --action get_status
```

(after the restore step above when exported state exists)

### Lock user-supplied official assets

Immediately after asset analysis, write one input object with the matching top-level slot, then call only its action:

```text
lock_authoritative_logo       {"source_summary": "...", "logo": {...}}
lock_authoritative_palette    {"source_summary": "...", "palette": {...}}
lock_authoritative_typography {"source_summary": "...", "typography": {...}}
```

These actions preserve official assets the user already owns. They do not approve generated work, and an authoritative slot cannot be replaced by a later generated choice.

### Persist visual axes

```json
{
  "visual_axes": {
    "restrained_expressive": 50,
    "geometric_organic": 50,
    "familiar_experimental": 50
  }
}
```

Call `set_visual_axes`; later read with `get_visual_axes`.

### Read only the required slot

- `get_logo` before logo placement, export, or logo-dependent revisions.
- `get_palette` for color-dependent work.
- `get_typography` for type-dependent work.
- `get_essential_kit` only when logo, palette, and typography are all genuinely required.

Never use `get_essential_kit` as a universal gate for partial outputs.

### Browse approved downstream elements

Call `list_brandbook_elements`, then use `get_brandbook_element` with:

```json
{ "key": "exact-element-key" }
```

### Approve generated elements independently

After an explicit user selection, write the exact selected object under its slot and call:

```text
approve_logo       {"approval_summary": "...", "logo": {...}}
approve_palette    {"approval_summary": "...", "palette": {...}}
approve_typography {"approval_summary": "...", "typography": {...}}
```

The script assigns the next revision. Do not put generated-but-unapproved work into state.

### Approve a downstream element

Only after explicit approval:

```json
{
  "approval_summary": "User approved the primary mockup.",
  "required_slots": ["logo", "palette"],
  "brandbook_element": {
    "key": "mockup-primary",
    "kind": "mockup",
    "name": "Primary packaging mockup",
    "asset": { "id": "...", "url": "..." }
  }
}
```

Call `approve_brandbook_element`. Declare exactly the foundation slots the output used.

## Recovery

The latest exported state JSON in this conversation is the durable source of truth. If this chat previously had approvals but no exported state can be found in the conversation, do not infer or silently recreate approvals. Stop and report the recovery failure. An explicit user request to restart may use `clear`.

## Never

- Never load the entire state file directly when a narrow read action is enough (the end-of-batch export is the one exception).
- Never put drafts into an authoritative lock.
- Never delay locking a user-declared official asset.
- Never store generated-but-unapproved assets.
- Never require or request approval for an unrelated missing slot.
- Never ask for combined approval after independent selections.
- Never use this state outside Brandkit.
- Never use user memory or any cross-chat store as a substitute.
