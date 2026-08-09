---
name: linear-release
description: Wire a repository into a Linear Release Pipeline, or report a release into one. Run when the user asks to set up, onboard, or fix Linear releases for a repo, to sync or complete a release in Linear, or asks why a Linear release looks wrong.
---

# Linear releases

Linear's Releases feature models a shipping pipeline. CI reports a release
(version + commit + the pull requests it carried); Linear resolves which issues
those PRs closed and moves the release through the pipeline's stages. The
tooling is [`linear-release`](https://github.com/phall1/.github/tree/main/actions/linear-release),
which is one codebase serving both a composite GitHub Action and a uv tool.

## Ground truth before you touch anything

Run these first. They are read-only and they answer most questions.

```sh
linear-release doctor          # config + credential + connectivity, in this repo
linear-release status          # the pipeline and its recent releases
linear-release admin list      # every pipeline in the workspace, with stages
```

If the tool is missing:

```sh
uv tool install "git+https://github.com/phall1/.github#subdirectory=actions/linear-release"
```

**Python here is always uv.** Never `python3 foo.py`, never `pip install`,
never a hand-rolled venv. Single-file scripts get PEP 723 metadata and a
`#!/usr/bin/env -S uv run --script` shebang; anything with an entry point is a
package run through `uv tool install` / `uv run`.

## The two credentials

Mixing these up produces a 401 that looks like a revoked key. It usually isn't.

| Credential | Prefix | Authorises | Header |
|---|---|---|---|
| Release pipeline access key | `lin_accesskey_` | `sync`, `complete`, `status` | raw `Authorization`, **no** `Bearer` |
| Personal API key | `lin_api_` | `admin` subcommands, everything else | raw `Authorization` |

Three things that will waste your time if you don't know them:

- An access key returns **401 on any operation that isn't `*ByAccessKey`** —
  including `{ __typename }`. A 401 is not evidence the key is bad; test it with
  `linear-release doctor`, which calls a permitted operation.
- A `Bearer` prefix on either credential fails.
- Access keys are **not readable through the API**. There is no `accessKey`
  field on `ReleasePipeline`. The user must copy it from
  Linear → Settings → Releases → *pipeline* → Access key. Ask them; do not go
  hunting for a programmatic route.

The personal API key comes from `linear auth token` (the CLI keychain) when
`$LINEAR_API_KEY` is unset, so `admin` subcommands usually just work.

## Onboarding a repo

The full manual reference is
[`docs/ONBOARDING.md`](https://github.com/phall1/.github/blob/main/docs/ONBOARDING.md).
Do it in this order, and stop at step 2 to ask the user for the key.

1. **Create the pipeline and its stages.**

   ```sh
   linear-release admin create <repo> --team PHA
   linear-release admin add-stage <Stage> --pipeline <repo> \
     --type started --position -1 --color '#F2994A'
   ```

   A new pipeline has one `Released` stage of type `completed`, so every synced
   release is marked done on arrival. The `started` stage in front of it is what
   makes an in-flight release visible. **Name it after the real gap**, and only
   add it if a real gap exists:

   - iOS app: tag means "on TestFlight", public availability comes later →
     `TestFlight (started) -> Released (completed)`.
   - CLI where the tag triggers a binary build → `Building -> Released`.
   - Repo where tagging *is* publication → leave the single `Released` stage
     and never call `complete`.

2. **Ask the user for the access key.** You cannot read it. Tell them the exact
   path: Linear → Settings → Releases → *pipeline* → Access key.

3. **Store it in both places.**

   ```sh
   # shell secrets (~/.zsh_secrets), for local use
   export LINEAR_ACCESS_KEY_<REPO>='lin_accesskey_...'
   # CI
   gh secret set LINEAR_RELEASE_ACCESS_KEY --repo phall1/<repo> --body '...'
   ```

   Never write the key into a repo file, a commit, or a log line.

4. **Configure the repo and verify.**

   ```sh
   cd <repo>
   linear-release init --pipeline <repo> --env LINEAR_ACCESS_KEY_<REPO>
   linear-release doctor
   ```

   Commit `.linear/release.toml`; it names the pipeline and env var, never the key.

5. **Wire CI.** Hang `sync` off whatever cuts the tag and `complete` off
   whatever makes it publicly available. Pin the reusable workflow by SHA —
   `git ls-remote https://github.com/phall1/.github main`:

   ```yaml
     linear-release:
       needs: [release_please]
       if: needs.release_please.outputs.release_created == 'true'
       uses: phall1/.github/.github/workflows/linear-release.yml@<sha> # phall1/.github main
       with:
         mode: sync
         tag: ${{ needs.release_please.outputs.tag_name }}
         prs-since-previous-tag: true
       secrets:
         access-key: ${{ secrets.LINEAR_RELEASE_ACCESS_KEY }}
   ```

   Then `actionlint` the edited workflows.

6. **Backfill the latest shipped release** and show the user the Linear URL.
   This proves auth, PR resolution, links and notes before a real release
   depends on it.

   ```sh
   linear-release sync --tag <latest> --prs-since <previous> \
     --link "https://github.com/phall1/<repo>/releases/tag/<latest>=GitHub release"
   ```

## Reporting a release by hand

```sh
linear-release sync --tag v1.2.3 --prs-since v1.2.2 --notes-file notes.md
linear-release complete --version 1.2.3
```

`sync` is an upsert keyed on the release, so re-running it is safe and is the
right recovery move after a CI job failed partway.

Add `--dry-run` to print the exact payload and send nothing. Use it whenever you
are unsure — it is free and it settles arguments about what will be attached.

## When PR references come back empty

`--prs-since REF` parses `(#N)` out of commit subjects first, then falls back to
asking the GitHub API which PRs each commit in `REF..HEAD` belongs to. Empty
results almost always mean one of:

- **Shallow checkout.** The range needs full history: `fetch-depth: 0`.
- **Missing tags.** `git fetch --tags --force`.
- **`gh` unavailable or unauthenticated**, so the fallback couldn't run. The
  tool warns on stderr rather than failing.

## Scope discipline

Release *pipelines* are not the same thing as launch planning. Hardening
sweeps, App Store milestones and release checklists live in the Linear
**project** for that repo, per the repo's own AGENTS.md. Do not invent issues
in the tracker as part of wiring a pipeline — a pipeline reports what shipped.
