# JJWW Reader Stage 6
## Pages Reader + Mode Synchronization

**Branch:** `feature/jjww-reader-stage6`

## Purpose

Turn the Stage 5/5.5 static `PageSlice` leaves into the second real reading body while keeping Scroll and Pages anchored to the same semantic `ReaderLocation`.

Stage 6 does not alter canonical content, authored order, material profiles, or the Stage 5.5 page-composition grammar.

## Build

- `JJWWPagesReader` target
- `ReaderLocationCoordinator`
- `SynchronizedReaderView`
- `PagesReaderView`
- native iOS `UIPageViewController`
- `.pageCurl` when motion is allowed
- horizontal non-curl transition when Reduce Motion is enabled
- `PagesLeafView` using the existing composed `PageSlice`
- subtle recto/verso gutter treatment
- Pages chrome for progress, type size, material intensity, and mode switching
- precise Scroll restoration through stable line IDs

## Location contract

### Scroll → Pages

Resolve the current exact `ReaderLocation` to the containing `PageSlice`. Preserve the exact pre-switch location while no leaf has been turned.

### Pages → Scroll

If no leaf was turned, return to the exact pre-switch location.

If a leaf was turned, return to the visible leaf's semantic start location.

A mode switch must never use screen pixel offsets as historical reading identity.

## Pagination contract

Stage 6 consumes Stage 5.5 pagination. Type-size changes may repaginate, but the nearest semantic location remains the authority.

Newspaper body typography enters Stage 6 fully justified with layout-only hyphenation. No canonical characters are inserted, removed, or rewritten.

## Motion contract

- standard: native page curl
- Reduce Motion: horizontal non-curl page transition
- no glossy 3D book simulation
- no animation is allowed to reorder or skip `PageSlice`s

## Tests

- exact Scroll location maps to containing leaf
- repeated no-turn mode switching does not drift
- completed turn advances exactly one PageSlice
- first/last page boundaries cannot overflow
- accessibility repagination preserves semantic anchor
- Reduce Motion selects non-curl transition
- paginated canonical text remains exact

## Visual gate

Render four portrait 390 × 844 leaves across:

1. Argus with justified newspaper body
2. Confession
3. Trial
4. Farewell

The static CI gate cannot demonstrate the live curl itself; it verifies the actual leaves and semantic handoff mappings. iOS runtime owns the finger-following curl.

## Out of scope

- cover integration
- delayed Albany map/title plate integration
- progress cloth spine
- annotations
- facsimiles
- final font selection

Those remain later stages.
