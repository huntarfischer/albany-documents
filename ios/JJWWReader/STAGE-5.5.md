# JJWW Reader Stage 5.5
## Typography + Page Composition Pass

**Status:** implementation gate

Stage 5.5 exists because the Stage 5 pagination engine proved text flow, but the reference material showed that the leaves themselves still needed stronger architecture before page turning.

## Reference-derived goals

The Albany reference pages and supplied title/page screenshots establish five governing ideas:

1. headers should alter page geometry, not merely use a slightly larger body face
2. opening pages may spend substantial negative space on ceremony
3. continuation pages should become quieter and denser
4. rules and running heads are structural printing devices, not decoration stickers
5. worn printing should come from uneven ink condition while the underlying text stays semantic and legible

## Build

Stage 5.5 adds:

- `PageCompositionKind`
- one tunable `PageCompositionProfile` for each of the five prototype source families
- distinct opening and continuation margins
- profile-controlled body leading, paragraph rhythm, header scale/tracking/spacing, rule geometry, and running-head size
- `PrintWearProfile` and deterministic `PrintWearText`
- first-page composition integrated into TextKit pagination
- page-composition identity in the pagination cache key
- DEBUG `PageCompositionLabView`
- versionable JSON export/import of tuned profiles
- a portrait review gate with four opening leaves above four continuation leaves

## Review screens

The primary Stage 5.5 sheet compares:

- Argus opening / continuation
- Confession opening / continuation
- Jesse trial opening / continuation
- Farewell opening / continuation

All review leaves remain 390 x 844 portrait iPhone frames.

## Non-goals

Stage 5.5 does not build page curl, mode synchronization, final historical fonts, facsimiles, or full-book population.

The current typeface remains provisional. Print wear is intentionally restrained and data-driven so it can survive a later font change.

## Gate

Stage 5.5 passes only if:

- canonical text remains exact after repagination
- opening pages and continuation pages resolve different composition states
- profile tuning round-trips through JSON
- print condition is deterministic
- source openings feel materially more substantial without harming reading pages
- the production Pagination and Typography targets build in Release

If the leaves feel right, Stage 6 may make them turn.
