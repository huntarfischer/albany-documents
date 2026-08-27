# JJWW Reader Stage 4 — Scroll Reader

**Branch:** `feature/jjww-reader-stage4`

**Status:** implementation gate

## Scope

Stage 4 turns the Stage 0 five-section edition into the first real reading body: one SwiftUI vertical Scroll reader using the existing material and typography systems.

It does not build pagination or Pages mode.

## Built

- `JJWWScrollReader` production library target
- one generic `ScrollReaderView`
- one generic `ReadingUnitSurface`
- line-role resolver for canonical source lines
- Ink Awakening at section/source openings
- source-aware material and typography profile lookup
- negative section spacing plus deterministic seam treatment
- selectable semantic text
- Dynamic Type reader control
- Full / Reduced / Clean material control
- Scroll / Pages mode control with Pages intentionally disabled until Stage 6
- stable `ReaderLocation` persistence by ReadingUnit ID, DocumentBlock ID, and canonical line
- lazy vertical unit rendering
- Stage 4 contact-sheet renderer using the actual reading-unit surface

## Architectural rule

There are no `ArgusView`, `ConfessionView`, `TrialView`, or `FarewellView` implementations.

All five sections use the same reader surface. Their differences come from the Stage 0 `ReadingUnit` configuration plus Material and Typography profiles.

## Canonical text rule

Stage 4 renders the exact selected Layer 0 v1.1 lines carried by Stage 0. Reader styling may classify a line for presentation, but it does not rewrite, normalize, or replace canonical text.

## Reader-location rule

Scroll position is not historical state.

The persisted location is semantic:

- ReadingUnit ID
- DocumentBlock ID
- canonical line
- UTF-16 offset slot reserved for later precision

Material and type-size changes therefore do not alter the logical reading location.

## Gate

Stage 4 passes only if:

1. Stage 0 through Stage 4 tests are green.
2. The canonical plain-text gate remains green.
3. `JJWWScrollReader` builds in Release configuration.
4. The Stage 4 contact sheet renders successfully.
5. The six reader surfaces visibly belong to one editorial object while retaining distinct source materials.
6. The dense Trial remains readable rather than becoming a decorative poster.

Do not start Stage 5 pagination until the visual gate is reviewed.
