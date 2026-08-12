---
name: web-research
description: Research current external facts with primary sources, citations, and a portable CLI fallback.
---

# Web research

Use native harness search and fetch tools first. Search from several angles, inspect result metadata, then fetch the strongest primary sources. Prefer official documentation, specifications, source repositories, release notes, and direct measurements over summaries or SEO pages.

When native tools are unavailable and the active role permits shell execution,
use the pinned harness-neutral CLI (Spartan intentionally cannot use this shell
fallback):

```sh
open-websearch search "query" --json
```

Use `open-websearch --help` to discover version-specific fetch or daemon operations rather than guessing flags.

For every research result:
- cite URLs next to the claims they support;
- distinguish live web evidence from cached snippets, repository evidence, and prior knowledge;
- include publication or retrieval dates when freshness matters;
- corroborate consequential claims and call out conflicts or gaps;
- do not claim that a snippet proves content you did not fetch;
- report failed searches and access limitations briefly.
