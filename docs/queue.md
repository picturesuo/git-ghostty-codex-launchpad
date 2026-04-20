# Queue

## Now
- [ ] Enforce automatic per-file commit and push wording across the launcher docs.

## Next
- [ ] Regenerate the prompt docs so the generated output matches the source wording.
- [ ] Update the README and durable knowledge notes so they match the automatic per-file publish rule.
- [ ] Review the launcher wrapper text for any remaining manual-approval phrasing.

## Later
- [ ] Revisit the commit helper docs if any additional guidance is needed for file-sized publish batches.

## Blocked
- [ ] Waiting on the prompt-source and generated-docs sync pass.

## Discovered While Working
- [ ] Edge case: verify the publish wording still says to skip private or personal files even when a prompt mixes doc and code work.
- [ ] Edge case: verify repeated file batches still produce separate commit messages instead of one merged message.
- [ ] Edge case: verify the generated docs stay in sync if the role prompt bodies are regenerated after the wording change.
- [ ] Cleanup: remove any now-redundant hand-written phrasing once the helper behavior becomes the single source of truth.
