# JJWW Reader Stage 5
## Pagination Engine

**Status:** implementation gate

Stage 5 builds pagination as a separate layout engine. It does **not** build the page-turning reader yet.

## Scope

The engine consumes the same `Edition` / `ReadingUnit` model used by Stage 4 Scroll and produces static `PageSlice` records.

Each PageSlice carries:

- global page index
- recto / verso status
- represented ReadingUnit IDs
- start / end canonical anchors
- start / end semantic ReaderLocation
- exact block/line fragments with UTF-16 offsets
- material profile
- section/source-transition flag
- exact TextKit segment character range

No canonical page number is written back into source data.

## Native layout

Stage 5 uses Apple TextKit (`NSTextStorage`, `NSLayoutManager`, `NSTextContainer`) to flow attributed canonical text through page-sized text containers.

Pagination is therefore driven by:

- page geometry
- text scale
- typography profile
- paragraph spacing / line spacing
- presentation break rules

The current five-section prototype explicitly begins a new leaf when the source work, material profile, or typography profile changes. The rule is data/configuration, not a hard-coded source-name switch.

## Cache contract

`PaginationCacheKey` includes:

- page width / height
- all margins
- text scale
- typography profile version
- margin profile version
- presentation-rules version
- edition version
- canonical line-sequence SHA
- cover inclusion state

Changing device geometry or Dynamic Type therefore invalidates pagination without changing the logical ReaderLocation.

## Cover boundary

The cover remains outside the paginated reading body for Stage 5. That matches the opening-flow contract: cover is the exterior threshold, while Pages-mode reading begins in the authored document flow. Stage 7 will integrate the finished cover behavior.

## Tests

Stage 5 must prove:

- every canonical character appears exactly once across PageSlices
- no text is omitted or duplicated at page boundaries
- TextKit segment ranges are contiguous
- compact-screen accessibility pagination remains complete
- semantic ReaderLocation resolves after re-pagination
- cache keys change for geometry / type changes
- prototype source transitions begin on explicit new leaves
- recto / verso alternates without changing content

## Visual gate

The gate is **not widescreen reader UI**.

It renders portrait **390 × 844 iPhone leaves**, four across. Each pair shows:

`last leaf of source A → first leaf of source B`

Across two rows this exposes all four prototype transitions:

1. Argus → Daily Advertiser
2. Daily Advertiser → Confession
3. Confession → Trial
4. Trial → Farewell

There is no page curl in Stage 5. These are static leaves only.

## Stop condition

Do not begin Stage 6 until:

1. tests are green,
2. the static pagination visual gate is reviewed,
3. text coverage is exact,
4. transitions look believable at real portrait-iPhone proportions.
