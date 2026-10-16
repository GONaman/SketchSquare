# Decisions log

One line of reasoning per decision. Items marked **needs owner confirmation** are business gaps from Part 3 of `AGENTS.md`.

| # | Decision | Reasoning |
|---|----------|-----------|
| D1 | Work happens via small feature branches merged by squash PR; `main` is never pushed to directly. | Owner requirement. |
| D2 | Old Firebase-based prototype (local, uncommitted) is not carried over; the spec mandates our own NestJS backend. | Spec Part 1 stack is fixed. |
| D3 | Generated Dart code (`*.g.dart`, `*.freezed.dart`) is committed. | Keeps `flutter analyze`/`test` reproducible without a codegen step in CI. |
