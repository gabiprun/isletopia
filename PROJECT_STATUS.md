# Isletopia — project status

_Last reviewed: 2026-09-03._

`README.md` is the design doc, controls reference and code map. This file answers a
different question: **what is actually shipped, versus what only exists in this
working copy.** Reconstructing that from `git log` / `git status` / `git show HEAD:`
is what this file exists to save you.

## Islands: 4 built, 4 committed, 3 shipped

| Island       | Script                             | Built | In `main` | In the Play release |
| ------------ | ---------------------------------- | ----- | --------- | ------------------- |
| Ember Isle   | `scripts/islands/ember_isle.gd`    | yes   | yes       | yes                 |
| Frost Peak   | `scripts/islands/frost_peak.gd`    | yes   | yes       | yes                 |
| Harbor Flats | `scripts/islands/harbor_flats.gd`  | yes   | yes       | yes                 |
| Royal Oak    | `scripts/islands/royal_oak.gd`     | yes   | yes       | **no**              |

All four pass the headless suite end to end:

```
$ godot --headless -- --smoke
SMOKE: ember complete / rooftops reachable / frost complete
SMOKE: harbor complete (smokes ending) + (gum ending)
SMOKE: royal oak complete (paid ending) + (exposed ending)
SMOKE OK
```

### Royal Oak is committed now — but not released

`6a35b8e` *"Fix the duplicate-script class cache and add coverage"* (2026-09-03)
committed the island: `scripts/islands/royal_oak.gd` (583 lines) and the five files
that wire it in, plus the README update. The work-loss risk this section used to
describe — the island existing only in one working copy, one `git checkout -- .`
away from gone — **is closed.**

What is still true is the release gap:

- The Play build (`1.0.1`, versionCode 2) and the web build in `docs/` are both
  pre-Royal-Oak. Anyone playing either one sees three islands.
- Shipping it means a new versionCode and a fresh Web export; neither has been done.

That is a deploy decision, not an outstanding piece of work.

## Releases

- **Play (Android)** — `1.0.1`, versionCode 2, internal track, `com.Isletopia`,
  shipped by `dcfbfa6` (2026-08-01). **Ember / Frost / Harbor only.** Royal Oak was
  written later (2026-08-26) and has never been in a release build.
- **Web (GitHub Pages)** — served from `docs/` on `main`. Still the same
  three-island build: `6a35b8e` committed Royal Oak's *source* but did not re-export,
  so `docs/` has not been rebuilt since. See the domain note below for the URL
  situation.
- **iOS** — never built. `export_presets.cfg` has a preset but no signing team; this
  is deferred pending an Apple Developer account, not a bug.

## Why there is no `CNAME` (custom domain is off on purpose)

Pages currently serves off the default `github.io` URL. That is deliberate, not an
oversight or a lost file.

`65d4681` (2026-07-31) *"Detach custom domain until GitHub issues its TLS cert"*
deleted `docs/CNAME`, which contained `isletopia.prundaru.ca`. The reason, from the
commit body:

> Pages was 301-redirecting the working github.io URL to isletopia.prundaru.ca,
> whose cert never provisioned, leaving no reachable HTTPS URL. Godot's web runtime
> requires a secure context, so http-only is not usable.

So the custom domain was strictly worse than no custom domain: it took a working
HTTPS URL and redirected it to one that could not serve HTTPS at all, and Godot's
web export refuses to run outside a secure context.

**To re-attach**, in this order — do not restore the file first:

1. Confirm the DNS record for `isletopia.prundaru.ca` points at Pages
   (`gabiprun.github.io`), via the Cloudflare token at `~/.config/cloudflare/token`.
2. Add the domain in the repo's Pages settings and **wait for GitHub to report the
   certificate as issued.** This is the step that failed last time; it is time-gated
   on GitHub and nothing local can force it.
3. Only then restore `docs/CNAME` containing `isletopia.prundaru.ca` and enable
   "Enforce HTTPS".
4. Verify `https://isletopia.prundaru.ca` actually loads the game — not just that it
   resolves — before considering it done.

If step 2 stalls again, delete `docs/CNAME` again. A reachable `github.io` URL beats
a pretty dead one.

## Repo hygiene

`tools/check_no_dupes.sh` fails the build if Finder/browser `"(2)"` duplicates
(`index 2.pck`, and worst case a ` 2.gd` script, which breaks Godot's class-name
cache) appear in the tree. It runs as the first gate inside
`tools/verify_web_build.sh`. If it fires, the cause is unzipping a browser-renamed
`... (2).zip` into place — export straight into `docs/` instead.

## Verification before any deploy

- `godot --headless -- --smoke` — runs the project directory.
- `bash tools/verify_web_build.sh` — runs the **exported pack**, which is the one
  that matters: the editor's GDScript parser is more permissive than the exported
  build's, and `fe12506` / `f99fec4` are both fixes for scripts that passed the
  former and blank-screened in the latter.

`.github/workflows/smoke.yml` now runs the first two automatically on every push to
`main`, on pull requests, and on demand: the duplicate-file gate, then a
`godot --headless --import` (a fresh checkout has no `.godot/`, and without the
import every `class_name` in the project is undeclared), then the smoke suite —
failing on `SMOKE OK` being absent *or* on any parse/script error in the log, since
the suite exits 0 either way.

`verify_web_build.sh` is deliberately **not** in CI yet, and it is the check that
matters most. It needs the ~1 GB export templates and a Web export on the runner;
the workflow file carries a comment saying exactly what a second job would have to
do. Until that exists, run it by hand before every deploy.
