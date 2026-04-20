# Repo Layering

Use this pattern when you manage more than one repo and want shared agent rules without duplicating a large `AGENTS.md` everywhere.

## Pattern

- Keep shared guardrails in one canonical `AGENTS` source.
- Keep each repo-local `AGENTS.md` tiny.
- Put only repo-specific rules, paths, tools, or exceptions in the repo-local file.
- Use local additions under the pointer when a repo truly needs them.

## What To Avoid

- Do not mirror large policy files byte-for-byte across unrelated repos unless you actively maintain that sync.
- Do not force every repo to inherit rules that only make sense for one workflow or one environment.
- Do not hide repo-specific behavior in the shared layer if the local repo needs to state it plainly.

## Good Local `AGENTS.md` Shape

1. A pointer to the shared or canonical guardrails.
2. A short list of repo-specific additions.
3. Links to local `tools.md`, `skills/`, or workflow docs when they exist.

## Fit For This Repo

This repo still keeps a meaningful local `AGENTS.md` because the launcher workflow, local helper scripts, and documentation structure are part of the repo contract. Use pointer-style layering as the default pattern for other repos, not as a requirement to centralize everything here.
