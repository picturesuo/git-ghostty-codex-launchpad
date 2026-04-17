# Queue

## Now
- [ ] Update the prompt source and launcher docs so each task in a multi-task prompt gets its own commit and push.

## Next
- [ ] Regenerate the prompt docs and verify the per-task publish rule is present in the generated output.
- [ ] Update the README and durable knowledge notes so they match the new publish boundary wording.
- [ ] Run the available shell syntax and prompt-drift checks after the wording update.

## Later
- [ ] Revisit the commit helper docs if any additional guidance is needed for task-sized publish batches.

## Blocked
- [ ] Waiting on validation of the updated prompt source and generated docs.

## Discovered While Working
- [ ] Edge case: verify the publish wording still says to skip private or personal files even when a prompt mixes doc and code work.
- [ ] Edge case: verify repeated task batches still produce separate commit messages instead of one merged message.
- [ ] Edge case: verify the generated docs stay in sync if the role prompt bodies are regenerated after the wording change.
- [ ] Cleanup: remove any now-redundant hand-written phrasing once the prompt source becomes the single source of truth.
