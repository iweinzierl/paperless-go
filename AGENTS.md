# Paperless Go

Flutter mobile client (Android, iOS) for self-hosted
[paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) servers. See
`README.md` for features and `.github/copilot-instructions.md` for the coding
rules (Riverpod, Retrofit/Dio, shared_preferences, Hive, `log()` not `print()`).

## Setup

A fresh checkout needs only:

```bash
flutter pub get
```

No env files are needed to build or test. `scripts/screenshot-env.sh` (copied
from `scripts/screenshot-env.sh.example`) is only for the Fastlane screenshot
lanes.

Generated code is committed:

- Retrofit / json_serializable (`*.g.dart`): after changing an annotated model
  or API, run `dart run build_runner build --delete-conflicting-outputs` and
  commit the result.
- Localizations (`lib/l10n/generated/`): add strings to `lib/l10n/app_en.arb`
  and the de, fr, it and es files, then run `flutter gen-l10n` and commit the
  result.

## Dev server

There is none. This is a mobile-only app (no `web/` platform), so there is no
dev server to start on a port. `flutter run` needs a device or simulator and a
reachable paperless-ngx server. Review UI changes through the widget code and
the widget tests in `test/`.

## Validation

The same commands as `factory/checks.sh`:

```bash
flutter pub get
flutter analyze
flutter test
```

## Software factory

`/factory run` builds every open GitHub issue labeled `factory` through
intake → spec → build → gate → review → approve, one PR per issue. State is in
`factory/jobs/` (gitignored); `factory/bin/job` is its only writer. Checks:
`factory/checks.sh`. Dashboard: `cd factory && python3 -m http.server`, then
open http://localhost:8000/dashboard.html.

Each job works in its own git worktree, a full checkout of the repo at
`.worktrees/<job-id>` (gitignored). A tool run from the repo root that doesn't
read `.gitignore` sees those copies too; exclude `.worktrees/` in its config.
