# JJWW iOS Opening Flow Spec v1.0

**Status:** Product pacing contract

This spec freezes the opening rhythm of the iOS edition before pagination and cover integration continue.

## Governing rule

**The app may add an exterior cover, but it must not move the book's title sequence forward.**

The authored manuscript is paced like a film with a cold open. The reader enters the historical/documentary material first. The title reveal arrives later, at the place where the Albany map/title plate occurs in the book's actual sequence.

The app must preserve that dramatic order.

## Product metaphor

- **Cover = exterior of the book / poster.**
- **Early canonical material = cold open.**
- **Albany map/title plate = delayed opening titles.**
- **Everything after the map continues in canonical book order.**

The map is therefore not an app splash screen, home-screen illustration, or conventional frontispiece moved to the beginning. It is an authored in-book reveal.

## Opening sequence

### 0. App launch: Cover threshold

Use the supplied portrait cover artwork as the exterior object.

The cover may include restrained interaction or motion, but the artwork itself remains primary. Do not rebuild its title, collage, photographs, or frames in Swift unless a later layered source asset explicitly calls for it.

Permitted chrome is minimal: Continue Reading / Begin, accessibility controls if needed, and the REAL GOOD stories + stuff publisher mark where appropriate.

The cover does **not** count as a canonical ReadingUnit from Layer 0. It is the threshold into the edition.

### 1. Enter the book: cold open

Beginning the book enters the canonical manuscript at its true beginning.

All material before the Albany map/title plate remains in the exact authored sequence. No generated title page, app-branded title card, table of contents, explainer, timeline, or map is inserted ahead of it.

In Scroll mode this material simply begins to unspool.

In Pages mode it begins on the first interior leaf after the cover.

### 2. Pre-title visual behavior

The pre-title section should feel intentionally underway before the book formally announces itself.

- Source/document materials receive their normal source-aware treatments.
- Section/date Ink Awakening may operate normally.
- Do not add a large `JESSE JAMES AND THE WIDOW WHIPPLE` in-app heading.
- Do not use the Albany map as a persistent background or navigation ornament before its authored appearance.
- Navigation chrome stays quiet and functional.

The reader should feel that they have been dropped into events rather than escorted through introductory UI.

### 3. Delayed title reveal: Albany map plate

At the map's actual position in the canonical book sequence, the supplied Albany map/title artwork becomes a dedicated **TitlePlate ReadingUnit**.

This is the opening-title moment.

The artwork should be presented largely as designed rather than re-typeset. Its existing title treatment is the title treatment.

#### Scroll mode

The plate occupies a strong vertical beat in the continuous reader. The preceding document clears, the map/title plate arrives with enough breathing room to register as a cinematic interruption, and the canonical material continues beneath it.

It must still belong to the scroll. Do not turn it into a modal screen requiring dismissal.

#### Pages mode

The title plate receives its own leaf/page whenever pagination permits. It should feel like a tipped-in plate or frontispiece encountered after the cold open.

Do not force the reader backward or forward to a conventional title-page position.

### 4. Title reveal motion

The map/title reveal may receive slightly more ceremony than an ordinary source transition, but it should not become an animation showcase.

Preferred direction:

- subtle settling/reveal of the finished map artwork
- restrained fade or paper-placement transition
- no artificial typewriter re-creation of title text already baked into the artwork
- no forced wait before the reader can continue
- Reduce Motion resolves immediately or by simple crossfade

The delayed placement is already the dramatic effect. Animation supports it rather than manufacturing a second effect on top.

### 5. After the titles

After the map/title plate, the reader returns directly to the canonical sequence.

No post-title menu, cast screen, chapter selector, or explanatory interstitial appears.

The title moment should feel like a film returning to its scene after opening credits.

## Reading-location rules

The map/title plate gets a stable reading anchor so Scroll and Pages resolve to the same authored position.

### First read

A user beginning at the cover encounters the delayed title naturally and exactly once in sequence.

### Resume

A returning reader resumes at the saved canonical location. The app must not replay the title plate merely because the app relaunched.

### Search / Explore / Archive jumps

Jumping to material after the map does not replay the title sequence.

Jumping directly to the map opens the plate normally but without pretending it is a first-run cinematic event.

### Switching Scroll ↔ Pages

Switching modes around the title reveal preserves the nearest canonical reading anchor. The title plate does not migrate to a different place because pagination changed.

## Asset roles

### Updated portrait cover

Role: exterior cover / launch threshold.

It may appear again in Archive or edition metadata, but not as an inserted canonical page unless the manuscript itself later includes it.

### Albany map/title plate

Role: in-book delayed opening titles at its actual authored position.

It should not be reused before that position as decorative branding.

### REAL GOOD stories + stuff symbol

Role: publisher/editorial imprint.

Use sparingly on cover threshold, colophon, development review sheets, or edition apparatus. It is not a repeating reading-screen watermark.

## Reader-model implication

The content model should distinguish three things:

```text
AppExteriorAsset
    cover

Canonical ReadingUnits
    exact Layer 0 sequence before titles
    exact Layer 0 sequence after titles

EditorialPlate ReadingUnit
    Albany map/title plate
    anchored at its authored canonical position
```

The title plate may use an editorial image asset while still carrying a stable canonical sequence position.

No UI renderer is allowed to sort it to the front simply because its semantic role is `title`.

## Visual-review gate

Future Stage gates must show the opening in **portrait iPhone proportions**.

A useful review sheet may place four portrait phone frames across, but each individual preview remains phone-shaped. Widescreen source cards are not accepted as the primary aesthetic gate.

The opening-flow review should eventually include four consecutive states:

1. Cover threshold
2. Early cold-open document
3. Later pre-title document
4. Albany map/title reveal

A second row can show the first post-title reading screen and mode-switch/resume cases.

## Explicit non-goals

The opening MVP does not include:

- conventional title page inserted immediately after cover
- table of contents before the cold open
- map preview before its canonical position
- cinematic video intro
- automatic title replay on every launch
- title text duplicated over the supplied map artwork
- reordering manuscript material to satisfy normal ebook conventions

## Acceptance test

Stage integration passes this pacing contract when a new reader can:

1. see the finished cover
2. enter the book immediately
3. read the early documentary material in authored order
4. spend meaningful time inside the story before the formal title reveal
5. encounter the Albany map/title plate at its true manuscript position
6. continue directly into the next canonical material
7. switch Scroll/Pages or resume later without changing that sequence

The intended feeling is simple:

**The cover tells you what book you picked up. The book itself waits to roll its opening titles until it is ready.**
