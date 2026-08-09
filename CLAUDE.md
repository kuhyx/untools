# CLAUDE.md — untools

Guided thinking tools. 25 frameworks that *run* the method — sequence the
prompts, enforce the structure, compute what can be computed — rather than
describing it and leaving you a blank canvas.

Flutter, targets **Android + web**. The **desktop app is the web build**, shown
in a Chrome `--app` window, following `~/todo`: Flutter's Linux embedder is
markedly slower at 4K than the same Dart code in Chrome. Do not run
`flutter create --platforms linux` — it would silently add the slow path back.

- Package name: `untools`, application id `com.kuhy.untools` (Dart `^3.12.2`).
- Flutter is pinned to **3.44.8** in both `.github/workflows/ci.yml` and
  `scripts/ci_mirror.sh`. A drift between them is the exact green-local/red-CI
  failure the mirror exists to prevent.

## Git workflow (repo-specific)

- **Never open pull requests. Commit directly to `main` and push to
  `origin/main`.** No feature branches for normal work.
- Ask before `git commit` and `git push`. Never `--no-verify`.

## Commands

- Tests + coverage: `flutter test --coverage`; summary `lcov --list coverage/lcov.info`.
- Static analysis: `flutter analyze --fatal-infos --fatal-warnings` (must be clean).
- Format: `dart format lib/ test/`.
- **Before pushing: `./scripts/ci_mirror.sh`** — reproduces CI exactly
  (clean build, analyze, format, tests, both coverage gates, web build).
- Release APK: `flutter build apk --release`.

## Architecture

The load-bearing idea: **the 25 tools are not 25 screens.** They collapse into
8 interaction patterns, so each pattern gets one generic widget and each tool
is a `const` data config. A 26th tool is a config file, not a feature.

- `model/` — `tool_config.dart` holds the **sealed** `ToolConfig` and its 8
  variants; `pattern_specs.dart` the small const value types; `session.dart`
  the user's answers; `tool_registry.dart` the catalogue and its queries.
- `tools/` — one `const` config per tool, grouped by category. **Const values,
  not getters:** a const declaration emits no executable lines, so the whole
  catalogue stays out of the coverage denominator instead of padding it.
- `patterns/` — one directory per pattern. Inside each, the geometry/logic
  lives in a **Flutter-free** file (`scoring.dart`, and later `layout.dart`,
  `cycles.dart`, `tree_model.dart`) separate from the widget. That split is
  what makes the 100% gate reachable on a canvas-heavy app; if it erodes, the
  gate becomes unmeetable.
- `data/` — local-only persistence. **No network, no accounts, no sync**: not
  crdt_sync, not http, not secure_storage. IndexedDB on web, a JSON file on
  Android, behind a conditional-export triple.
- `export/` — `session_markdown.dart` renders any session to Markdown.

### Two exhaustive switches, and why

`screens/session_screen.dart` and `export/session_markdown.dart` are the only
places that switch over `ToolConfig`. Because the type is sealed and neither
has a `default:` arm, **adding a ninth pattern fails to compile in both places
until it is handled.** Keep it that way — list new patterns explicitly rather
than adding a catch-all.

### Sessions are keyed by slot id, never by index

`Session.slots` maps a stable string slot id to its answer. That one rule is
the whole schema-versioning story: reordering wizard steps, inserting a
fishbone rib or renaming a prompt can never shift a saved answer onto the wrong
question. Unknown keys are **preserved** on round-trip, so a session written by
a newer build survives an older one. `model/session_migrations.dart` is the
escape hatch for a genuine value-shape change; it should stay empty.

## Attribution (not optional)

These frameworks are long-standing public methods, but the prose on any
particular website is not. **Every description and example here is written
fresh, and every tool names its original author** — Ishikawa, Meadows, Boyd,
Snowden, Minto, Argyris, Goldratt, Zwicky, Hurson, Munger/Jacobi, Novak &
Cañas, Covey/Eisenhower, and so on. `attribution` is required on the sealed
base class, so this is enforced by the compiler, and asserted again by the
registry test.

Two trademarks need care: **Six Thinking Hats®** (de Bono) and **SBI™** (Center
for Creative Leadership). Implement the methods; name the features generically
("Perspective Lenses", "Feedback Framer") and carry an attribution line.

## Design system

Tokens come from `~/utils/unified-design-system/tokens.md` — `ui/theme.dart`
builds explicit `ColorScheme.light`/`.dark`, **never** `ColorScheme.fromSeed`.
Two requirements from that document are easy to break and are gated by tests:

- **Pointer-free operability.** Every action must be keyboard-reachable. A drag
  has no keyboard analogue, so the matrix's "move to quadrant" menu is the
  load-bearing path, not a convenience — build the keyboard path *alongside*
  any new drag affordance, never afterwards.
- **1366x768 fully usable, 1024x600 scrolls rather than clips.** Both sizes are
  in the widget-test matrix explicitly; phone-portrait sizes exercise neither.

## Known limitation

On desktop, sessions live in the Chrome profile's IndexedDB. **Wiping that
profile loses them, and the Markdown export is the only backup.** This is the
honest cost of being local-only. The wrapper port must stay fixed: IndexedDB is
origin-keyed, so a moving port silently presents an empty app.

## Testing

- Pure-Dart logic (`scoring.dart`, `session_codec.dart`, `session_markdown.dart`,
  registry queries) is unit-tested exhaustively — no pump, fast.
- Widget tests inject `FakeSessionStore` rather than touching a real store.
- `tool_registry_test.dart` walks the whole catalogue: unique ids, non-empty
  attribution, resolvable guide links. It is what stops a 26th tool being added
  wrong.
- `// coverage:ignore-file` is for genuinely unreachable code only (bootstrap
  wiring, a platform intent that cannot run on the Linux test host), with a
  one-line reason. Anything else gets a test.
