# JJWW Reader — Stage 7.5

Status: `IMPLEMENTED_PENDING_GATE`

Branch: `feature/jjww-reader-stage7-5`

Stage 7.5 is a real Swift implementation pass, not a visual mockup. It keeps the Stage 7 binding and the Stage 5.5/6 typography baseline, then adds authored physical pacing between documentary objects and a closer live-text reconstruction of the Farewell broadside.

## Source pacing

The Scroll reader no longer treats every source or article as one continuous feed.

### Article boundaries

Periodical ReadingUnits may contain multiple source blocks. Each block is rendered as its own paper sheet with:

- deckled paper edge
- subtle deterministic drift / rotation
- shadow and overlap
- the existing source material profile
- the existing shared typography / print-wear profile
- full justification where the newspaper typography profile requires it

Between those sheets, `EditorialIntervalCatalog` inserts explicit authored intervals rather than generic padding.

Prototype interval types:

- `articleOrangeOverlap`
- `articlePaperBreath`
- `sourcePaperBridge`
- `orangeSequenceBreak`
- `dramaticVoid`

Orange is punctuation, not wallpaper. Major sequence changes may expose more orange cloth; smaller article changes may use mostly paper and negative space.

The three Argus blocks in the five-section fixture therefore read as three archival objects:

1. May 8 proclamation
2. May 9 assassination article
3. May 9 funeral notice

## Farewell broadside

The surviving Farewell printing is treated as a designed artifact, but the phone does not squeeze its two historical columns side-by-side.

Canonical live text remains unchanged.

Serial phone structure:

- canonical lines `1892–1894`: opening metadata / title hierarchy
- canonical lines `1895–1926`: historical left column, presented first at full phone reading measure
- canonical lines `1927–1958`: historical right column, presented second at full phone reading measure

The first historical column carries a restrained ornament at its trailing edge. The second carries the corresponding ornament at its leading edge. The ornament records the original facing-column relationship, but remains subordinate to the text.

The broadside's prose coda visible in the surviving artifact is not present in the sealed Stage 0 canonical fixture and is therefore **not added** by Stage 7.5.

Farewell typography changes:

- substantially stronger `FAREWELL ADDRESS` hierarchy
- subordinate metadata beneath the title
- leading-aligned verse rather than centered verse
- stanza rhythm in quatrains
- stronger but still restrained print wear
- no heavy ornamental perimeter border

## Shared identity

Stage 7.5 does not fork Scroll and Pages into separate design systems.

Both continue to use the shared `ReaderCompositionCatalog` for source identity. Pages adapt it into `PageCompositionProfile`; Scroll consumes it directly. Farewell's broadside profile therefore remains the same source identity in both modes even though the two modes lay the material out differently.

## Canonical guarantees

Stage 7.5 does not edit Canonical Layer 0 v1.1.

- article intervals are layout only
- deckled edges / overlaps are layout only
- orange sequence fields are layout only
- Farewell historical-column serialization is layout only
- source text order remains canonical
- Scroll ↔ Pages semantic locations remain canonical line based

## Tests

Stage 7.5 adds checks that:

- the two intra-Argus article boundaries resolve explicit, different interval treatments
- major source transitions resolve the intended paper / orange / dramatic interval classes
- Farewell serial ranges are exactly `1895–1926` then `1927–1958`
- stanza rhythm follows four-line groups
- Farewell verse is one leading-aligned readable column
- all earlier canonical, typography, pagination, and synchronization tests remain green

## Visual gate

Four portrait `390 × 844` phone states:

1. Argus May 8 → May 9 article transition
2. Argus assassination article → funeral notice transition
3. Farewell opening
4. Farewell historical second column

The gate uses production Swift renderers. It must not substitute a hand-built concept mockup for the reader under review.
