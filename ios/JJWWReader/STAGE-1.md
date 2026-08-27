# JJWW Reader Stage 1

**Status:** implementation candidate

Stage 1 builds the material engine only. It does not integrate materials into the book reader.

## Scope

The Stage 1 package adds:

- `MaterialEngine`
- deterministic seeded material recipes
- six provisional material profiles
- `full / reduced / clean` material states
- procedural mottling, grain, fibers, flecks, foxing, edge variation, and optional cloth weave
- a future-compatible scan-overlay slot
- a reusable `MaterialSurfaceView`
- a non-reader specimen sheet renderer
- material-engine tests

## Six profiles

1. `jjwwEditorial`
2. `argus1827`
3. `dailyAdvertiser1827`
4. `confessionPamphlet1827`
5. `trialRecord1827`
6. `farewell1827`

These values are provisional. Stage 2 provides the Material Lab used to tune and export final profile values.

## Determinism contract

The material surface is resolved from:

`profile + profile version + material state + UInt64 seed`

The renderer receives an immutable resolved recipe. SwiftUI `Canvas` never calls a random generator during drawing.

Core Image grain begins from a deterministic byte field and is cached by seed/resolution through one reused `CIContext`.

This prevents shimmer and keeps the same unit/page visually stable across re-renders.

## Material states

### full
All configured decorative layers are available.

### reduced
Fewer marks, reduced opacity, no foxing, lower-resolution grain, lighter cloth/edge/scan work.

### clean
The base material tone remains, but decorative texture, grain, edge treatment, cloth, foxing, and scan overlays are removed. This uses the same renderer and content path rather than a parallel clean-reader implementation.

## Scan overlay contract

Every profile already carries a `ScanOverlayProfile` with an optional asset name, opacity, scale, and offset. All bundled Stage 1 profiles leave the asset name empty.

A future real paper scan can therefore enter the material system without changing the `MaterialEngine` or reader API.

## Gate commands

From `ios/JJWWReader`:

```bash
swift test
mkdir -p /tmp/jjww-materials
swift run jjww-material-specimens --state full --output /tmp/jjww-materials/full.png
swift run jjww-material-specimens --state reduced --output /tmp/jjww-materials/reduced.png
swift run jjww-material-specimens --state clean --output /tmp/jjww-materials/clean.png
```

The Stage 1 GitHub Actions workflow runs the tests on macOS and uploads the three specimen sheets as an artifact.

## Gate

Do not begin Stage 2 until the six-profile specimen sheet has been visually reviewed.

Stage 1 deliberately contains no book reader integration, Ink Awakening, pagination, annotations, facsimile reader, or full-book population.
