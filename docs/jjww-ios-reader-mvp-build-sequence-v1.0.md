# Jesse James and the Widow Whipple
## Swift-Native Reader MVP Build Sequence v1.0

**Status:** proposed build sequence, not yet implementation

## Goal

Build one Swift-native reader that can render the cover plus five deliberately different book experiences from the canonical edition:

1. May 8/9 Albany Argus
2. June 18 Albany Daily Advertiser
3. The Confession
4. Trial of Jesse Strang
5. Farewell Address

The same canonical content must support two synchronized reading bodies:

- **Scroll**: one continuous archival assemblage unspooling vertically
- **Pages**: a found-book / forgotten-manuscript reading mode with physical leaves and native page-curl behavior where appropriate

The five-section prototype is the reader laboratory. We do not populate the full book until this system passes its reader, material, accessibility, and source-apparatus gates.

## Governing rules

- The authored book order is canonical. No renderer may reorder it.
- Historical/source text remains real semantic text, never flattened into decorative images.
- Material treatment sits behind or around the text.
- Historical documents retain their own visual identities; the orange cloth / cream frame / cut-paper language belongs to the JJWW editorial binding.
- Scroll and Pages consume the same `Edition` / `ReadingUnit` model.
- Switching modes preserves reading location.
- Procedural texture values live in profiles, not scattered Swift constants.
- The hidden Material Lab is part of the prototype, not an afterthought.
- Ink Awakening is a section-opening ritual, never a body-text animation.
- Accessibility may reduce or remove material effects without altering content.
- Each stage stops at a review gate. Do not continue automatically.

---

# Stage 0 — Reader Contract + Five-Section Fixtures

### Build

Create the smallest app/package shell needed to represent the five-section prototype without visual design.

Define the runtime types only:

- `Edition`
- `ReadingUnit`
- `DocumentBlock`
- `SourcePresentation`
- `TypographyProfile`
- `MaterialProfile`
- `ReadingAnchor`
- `ReaderLocation`

Create fixture data for the cover and five test experiences using canonical text and stable canonical line/source anchors.

Establish one immutable `sequence` field as the sole source of reading order.

### Do not build yet

No paper textures, page curl, annotation UI, Archive UI, or full-book import.

### Tests

- fixture order exactly matches the authored sequence
- every ReadingUnit has stable ID and canonical anchor
- switching lookup by ID/sequence is deterministic
- no historical assertions exist in Swift view code

### Gate

We can print the ordered five-section edition as plain text and verify that the content model is sufficient for both future renderers.

---

# Stage 1 — Material Engine, No Reader Yet

### Build

Create a reusable `MaterialEngine` that renders source material independently of book content.

Initial procedural layers:

- base tone
- broad mottling
- Core Image grain
- Canvas fibers / flecks
- restrained foxing
- edge variation
- optional cloth weave
- optional scan overlay slot, initially empty

Create exactly six profiles:

- `jjwwEditorial`
- `argus1827`
- `dailyAdvertiser1827`
- `confessionPamphlet1827`
- `trialRecord1827`
- `farewell1827`

Every procedural layer must use a deterministic seed so the same page/unit does not shimmer or change between renders.

### Material-state contract

Every profile supports:

- `full`
- `reduced`
- `clean`

`clean` must remove decorative texture without requiring another reading implementation.

### Tests

- deterministic render for same profile + seed
- different seeds produce different but related surfaces
- no per-frame random regeneration
- reduced/clean states are visually and computationally cheaper
- MaterialEngine can accept a future image/scan without API redesign

### Gate

Review a material specimen sheet showing the six profiles side by side before integrating any text.

---

# Stage 2 — Hidden Material Lab

### Build

Create a DEBUG-only `MaterialLabView` before tuning any profile by hand.

Expose live controls for:

- paper warmth
- brightness
- mottling amount / scale
- grain amount / scale
- fiber density / length / opacity
- flecks
- foxing amount / radius
- edge wear
- scan opacity
- scan crop/scale
- cloth vertical/horizontal thread density
- ink density
- future ink bleed amount

Add deterministic seed controls and a profile picker.

Add **Export Profile** that emits the current values as versioned JSON or plist text suitable for checking into the repo.

### Rule

A visual decision is not final until it can be represented in exported profile data.

### Tests

- round-trip export/import produces the same material
- production builds do not expose the Material Lab
- profile changes do not mutate historical content

### Gate

Tune provisional versions of all six material profiles using the Lab and save them as profile data.

---

# Stage 3 — Typography + Ink Awakening Laboratory

### Build

Before the full reader, create a typography specimen screen for:

- date headings
- newspaper masthead/source header
- body text
- confession first-person prose
- trial witness/counsel/court labels
- verse
- editorial cut-paper labels

Build `InkAwakeningText`, used only for section-opening date/source/title material.

Behavior:

- true SwiftUI text remains the source
- reveal uses a seeded irregular ink-development mask / custom TextRenderer or equivalent
- letters emerge by blot/stroke rather than a left-to-right typewriter
- duration/profile controlled by data
- plays once on natural section entry
- skipped when jumping into the middle of a section
- Reduce Motion resolves immediately or via a short fade

Material Lab gains an **Ink** tab for:

- duration
- irregularity
- blot scale
- reveal threshold
- opacity curve
- optional feather/bleed

### Tests

- Dynamic Type does not break headers
- VoiceOver reads final text normally
- animation never changes text content/order
- Reduce Motion path works
- section header can render instantly for search/jump navigation

### Gate

Approve the entrance ritual on all five section types before it reaches the reader.

---

# Stage 4 — Scroll Reader

### Build

Build the first real reading body as a SwiftUI vertical reader.

Requirements:

- uses only the Stage 0 content model
- each ReadingUnit selects its material/typography profiles through configuration
- visible material transitions between source families
- no bespoke `ArgusView`, `TrialView`, etc.
- source headers use Ink Awakening
- text remains selectable/accessibility-readable
- section/source seams can overlap subtly to preserve the collage language of the cover

Add minimal reading chrome:

- progress
- `Aa`
- Material setting (`Full / Reduced / Clean`)
- mode switch placeholder (`Scroll / Pages`, Pages disabled until Stage 6)

Persist reading location by stable anchor, not screen offset alone.

### Tests

- all five sections render in authored order
- switching material setting does not move the logical reading anchor
- Dynamic Type reflows without clipping
- long trial text remains performant
- canonical text round-trips exactly from model to rendered blocks

### Gate

This is the first major aesthetic review. The five sections must feel like different historical objects assembled by the same JJWW editorial hand.

If this does not work, do not proceed to pagination.

---

# Stage 5 — Pagination Engine

### Build

Build pagination separately from page animation.

Use TextKit/custom text layout to compute `PageSlice` objects from the same ReadingUnits used by Scroll.

Each `PageSlice` must know:

- page index within current layout configuration
- source ReadingUnit IDs represented
- start/end ReadingAnchor
- text ranges / block fragments
- material profile
- recto/verso status
- whether it begins a section/source transition

Pagination cache key must include at least:

- device/page geometry
- Dynamic Type size
- typography profile version
- material margin profile version
- content/edition version

### Rules

- no canonical page numbers are baked into source data
- text-size changes repaginate naturally
- section boundaries may force a new leaf only when presentation rules explicitly say so

### Tests

- no omitted/duplicated text across page boundaries
- first/last anchors of adjacent PageSlices are contiguous
- re-pagination preserves logical ReaderLocation
- huge accessibility sizes still generate valid pages
- rotation/device-size changes invalidate only the needed pagination cache

### Gate

Render static numbered leaves without page turning and compare every transition to Scroll mode.

---

# Stage 6 — Pages Reader + Mode Synchronization

### Build

Embed a native page-reading controller in the SwiftUI shell, using the Stage 5 PageSlices.

Target behavior:

- physical leaf presentation
- subtle gutter/shadow
- page-specific deterministic paper surface
- native `.pageCurl` where platform behavior remains suitable
- no exaggerated glossy 3D book simulation

Build the shared `ReaderLocationCoordinator`.

Switching:

`Scroll -> Pages` resolves the current stable anchor to the containing PageSlice.

`Pages -> Scroll` resolves the visible page's anchor back to the corresponding ReadingUnit/block position.

### Tests

- repeated mode switching does not drift location
- first/last page boundaries are correct
- page curl cannot skip content
- Dynamic Type re-pagination preserves nearest semantic anchor
- Reduce Motion provides a non-curl transition when appropriate

### Gate

A reviewer can begin in Argus Scroll, switch to Pages during Confession, turn leaves into the Trial, switch back, and remain at the same logical place.

---

# Stage 7 — Cover, Editorial Binding, Progress Spine

### Build

Integrate the supplied book cover as the opening threshold.

Initial cover behavior uses the flattened cover honestly:

- restrained whole-cover scale/drag response
- no fake component parallax
- entry gestures into Scroll or Pages

Create reusable JJWW editorial components derived from the cover:

- cream arched frame shape
- orange cloth material
- cut-paper label
- black/cream/orange control language
- narrow cloth progress spine

The progress spine maps major section/source transitions, not every paragraph.

### Tests

- cover transition lands on correct initial ReaderLocation
- Continue Reading bypasses/uses cover appropriately
- editorial components do not override source materials
- no critical controls rely on texture/color alone

### Gate

The app should now feel visually descended from the cover without looking like the cover was wallpapered over every screen.

---

# Stage 8 — Three Annotations + Show Me the Source

### Build

Do not populate the apparatus globally. Prove the pipeline with exactly three annotations:

1. June 18 confession-date discrepancy
2. one trial voice/procedural annotation
3. Farewell attribution/provenance note

Create:

- `AnnotationAnchor`
- restrained gutter marker
- native bottom-sheet note presentation
- `Show Me the Source`
- exact source-span highlighting

The user sees natural language, not registry IDs.

### Tests

- each annotation resolves to correct ReadingAnchor
- Show Me the Source lands on/highlights exact supporting span
- annotation language does not turn a claim/legal result into historical truth
- annotations remain reachable in both Scroll and Pages

### Gate

All three very different apparatus cases work without special-case reader code.

---

# Stage 9 — One Real Facsimile Pipeline

### Input needed

At least one high-resolution source scan from one of the five test sections.

### Build

Create the facsimile asset pipeline:

- archival master is not mutated by the app build
- app derivative generated/imported at appropriate resolution
- asset manifest links scan to Work/Passage/ReadingUnit
- Text / Original toggle
- pinch / pan / zoom
- iPad layout may expose Text | Original side by side later, but iPhone Text/Original switching is enough for MVP

The real scan may also be optionally sampled by a MaterialProfile, but facsimile and decorative paper texture remain separate concepts.

### Tests

- no facsimile is fabricated when an original scan is absent
- original scan mapping opens from the correct passage
- image memory footprint is controlled
- text mode and facsimile mode return to the same source context

### Gate

One real historical object works end to end.

---

# Stage 10 — Accessibility, Performance, Device Stress

### Build / Verify

Stress the completed five-section reader before any full-book population.

Required matrix:

- iPhone compact screen
- current large iPhone
- iPad
- portrait / landscape where supported
- default text size
- largest practical accessibility sizes
- Reduce Motion
- Reduce Transparency / Reduced Material
- VoiceOver
- Light/Dark appearance strategy if supported by the edition

Performance targets are observational first, then measured:

- no continuous noise animation
- cached procedural surfaces
- reused Core Image context
- lazy Scroll rendering
- page cache bounded
- large scans decoded/resized appropriately

### Tests

- no lost reading location
- no clipped text
- no inaccessible controls
- no decorative layer blocks selection/VoiceOver
- Ink Awakening respects accessibility settings
- Scroll remains smooth through dense Trial material
- mode switching remains stable after repeated re-pagination

### Gate

The prototype behaves as a real reader, not a visual demo.

---

# Stage 11 — Reader Freeze + Full-Book Population Plan

### Do not populate yet

First freeze the reader grammar proven by the five sections.

Write a `ReaderProfileRegistry` mapping every remaining Work/Passage family in the canonical book to one of the existing profiles or to a clearly identified missing profile.

Only after reviewing that registry do we add new material profiles such as:

- later nineteenth-century book/history
- broadside
- 1905 newspaper
- modern appendix/editorial paper
- maps/plates

The population phase should mostly be data/profile assignment, not new view code.

### Final MVP acceptance test

Hand someone the phone with no instructions.

They should be able to:

- enter through the cover
- begin reading naturally
- understand that source/material has changed without being told how the system works
- encounter Ink Awakening as a recurring section-opening ritual
- switch Scroll <-> Pages without losing place
- adjust material intensity and type size
- read dense Trial text comfortably
- reach the quiet Farewell treatment
- open one discrepancy/source note
- reveal an exact source span
- view one genuine facsimile

If those actions feel coherent, the reader architecture is ready for the rest of the book.

---

# Recommended implementation order in one line

**Contract -> Materials -> Material Lab -> Typography/Ink -> Scroll -> Pagination -> Pages -> Cover/Binding -> Annotation Proof -> Facsimile Proof -> Accessibility/Stress -> Freeze -> Populate**

The sequence is intentionally front-loaded toward the reader and material system. The scholarly data engine already exists; the prototype's job is to prove that all of that rigor can disappear into a beautiful reading object.
