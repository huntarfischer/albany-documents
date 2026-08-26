# JJWW Reader Stage 0

**Status:** implementation candidate

This Swift package is the Stage 0 reader contract for the five-section JJWW iOS prototype.

## Scope

It contains only:

- runtime reader model types
- a small fixture manifest for the cover + five test experiences
- a development loader that reconstructs the selected text from the repository canonical corpus
- deterministic lookup/order behavior
- a plain-text gate executable
- contract tests

It intentionally contains **no SwiftUI view layer**, paper/material renderer, page curl, annotations, Archive UI, or full-book import.

## Canonical handling

The Albany repository currently stores the canonical Layer 0 v1.0 JSON. The current project canon is v1.1.

For Stage 0 only, the fixture manifest transparently applies the one known compiler correction:

- `EDCOR-0011`
- line 119
- `Monday June 16, 1827`
- becomes `Monday June 18, 1827`

The loader checks the old text before applying the correction. It changes no other line.

The resulting runtime edition declares:

- Canonical Layer 0 version: **1.1**
- line count: **2069**
- SHA-256: `106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e`

Layer 1 source anchors are from **v2.5**.

## Fixture sequence

1. Cover / front matter, canonical lines 1-5
2. May 8/9 Albany Argus, lines 6-23
3. Monday June 18 Albany Daily Advertiser, lines 119-127
4. The Confession of Jesse James Strang, lines 173-228
5. Trial of Jesse James Strang, lines 229-584
6. Farewell Address, lines 1892-1958

The immutable `sequence` field is the sole reading-order authority.

## Gate commands

From `ios/JJWWReader`:

```bash
swift test
swift run jjww-stage0-print
```

The print executable also accepts an explicit canonical JSON path:

```bash
swift run jjww-stage0-print /path/to/jesse-james-and-the-widow-whipple-canonical.json
```

Stage 0 is complete only when the tests are green and the plain-text printout is manually reviewed before Stage 1 begins.
