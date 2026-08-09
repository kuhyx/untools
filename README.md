# untools

Guided thinking tools for Android and the desktop. Twenty-five frameworks that
**run** the method — sequence the prompts, enforce the structure, and compute
what can be computed — instead of describing it and handing you a blank page.

Reference sites explain the Eisenhower matrix and leave you to fill one in
somewhere else. Whiteboards give you an infinite canvas and a starter template,
but they never sequence a step, enforce the seven rungs of a ladder of
inference, total a weighted decision matrix, or tell you which tool you need in
the first place. That gap is what this app is.

## What it does

- **Starts from "where are you stuck?"**, not an alphabetical list. A catalogue
  only helps someone who already knows which tool they want, and someone in the
  middle of a problem usually does not.
- **Runs the method.** Wizards keep earlier answers visible so a later one can
  send you back to revise them. Grids total themselves and refuse to name a
  winner on a tie. Quadrants take items by drag *or* keyboard.
- **Saves your sessions locally** and exports any of them to Markdown.
- **Never goes online.** No account, no sync, no telemetry, no network code at
  all.

## Status

Three tools so far — Inversion, the Eisenhower matrix and a decision matrix —
one per interaction pattern, proving the config-driven engine end to end. The
remaining twenty-two land pattern by pattern.

## Running it

```bash
flutter test --coverage          # 100% line coverage is the bar
flutter build apk --release      # phone
flutter build web --release      # desktop is the web build, in a Chrome --app window
./scripts/ci_mirror.sh           # everything CI runs, locally, before pushing
```

## A note on where your sessions live

On Android, sessions are a JSON file in the app's private storage. On desktop
they live in the browser profile's IndexedDB — so **wiping that profile loses
them, and the Markdown export is the only backup.** That is the honest cost of
having no server; it is stated here rather than discovered later.

## Attribution

These frameworks are long-standing public methods and this app credits their
originators — Kaoru Ishikawa, Donella Meadows, John Boyd, Dave Snowden, Barbara
Minto, Chris Argyris, Eliyahu Goldratt, Fritz Zwicky, Tim Hurson, Carl Jacobi
and Charlie Munger, Joseph Novak and Alberto Cañas, Dwight Eisenhower and
Stephen Covey, among others. Every description and worked example here is
written for this app.

Two methods are trademarked by others and are implemented under generic
feature names: Six Thinking Hats® (Edward de Bono) and SBI™ (Center for
Creative Leadership).
