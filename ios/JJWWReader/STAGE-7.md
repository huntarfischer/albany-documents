# JJWW Reader — Stage 7

Status: `IMPLEMENTED_PENDING_GATE`

Branch: `feature/jjww-reader-stage7`

Stage 7 binds the proven Scroll/Pages reader into the authored book object.

## Scope

### Cover threshold

- supplied portrait cover is treated as the exterior of the book
- whole-cover tap / restrained upward drag enters the manuscript
- no fake component parallax
- first entry lands on the first non-cover canonical reading location
- persisted reading locations expose Continue Reading without moving the reader

The cover asset is expected at:

`Sources/JJWWBookShell/Resources/Gallery/JJWW UPDATED COVER copy.jpeg`

Until the file is added to the repo, the shell renders a clearly provisional cover-derived fallback rather than inventing a replacement image.

### Editorial binding

Reusable cover-derived components:

- cream arch shape
- orange procedural cloth field
- cut-paper label
- black / cream / orange control language
- narrow cloth progress spine

The binding overlays the existing reader rather than changing source materials.

### Progress spine

Progress remains semantic. Milestones are source / ReadingUnit boundaries, not paragraphs or baked page numbers.

### Delayed title rule

The Albany map remains the delayed in-book title plate.

Reserved asset:

`Sources/JJWWBookShell/Resources/Gallery/new ALBANY FIRST MAP BW CROPPED TITLE.jpg`

Its canonical placement is deliberately **unset** in Stage 7. We do not guess the authored title position from its semantic role. The exact anchor will be assigned when the full manuscript image sequence is populated.

### Publisher mark

Reserved asset:

`Sources/JJWWBookShell/Resources/Gallery/SYMBOL NAVY.png`

It is an imprint mark, not a repeated navigation decoration.

## Editorial Gallery

Stage 7 adds a low-friction image intake system.

Drop any supported image into:

`Sources/JJWWBookShell/Resources/Gallery/`

Supported image extensions:

- png
- jpg / jpeg
- heic
- tif / tiff

Any image not yet named in the manifest is automatically discovered and appears as `NEW · UNPLACED` in the developer Gallery.

Manifest:

`Sources/JJWWBookShell/Resources/editorial-gallery-manifest-v0.1.json`

A manifest entry can add:

- stable ID
- role
- title
- caption
- credit
- alt text
- insertion style
- exact canonical placement `{ canonicalLine, edge }`

The gallery therefore separates two acts:

1. **collect the research image**
2. **place it in the manuscript deliberately**

No filename silently determines historical or narrative placement.

## Tests

Stage 7 verifies:

- cover opens to first non-cover canonical location
- Continue Reading preserves saved semantic location
- progress spine uses source boundaries
- known cover / publisher / delayed-title assets are reserved
- delayed Albany title plate has no invented placement
- gallery placement resolver requires exact canonical line + before/after edge
- all earlier canonical / typography / pagination / synchronization tests remain green

## Visual gate

Four portrait 390 × 844 phone states in one row:

1. exterior cover threshold
2. bound Scroll reader
3. bound Pages reader
4. editorial Gallery

The visual gate must show that the app descends from the supplied cover without wallpapering the cover language over the historical documents.
