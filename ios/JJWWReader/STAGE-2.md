# JJWW Reader Stage 2

**Status:** implementation candidate / visual tuning gate

Stage 2 builds the hidden Material Lab. It does not integrate materials into the book reader and it does not freeze final material values.

## Scope

Stage 2 adds:

- a separate `JJWWMaterialLab` developer target
- `MaterialLabView`, compiled only in DEBUG
- live profile and material-state selection
- deterministic seed editing
- live controls for paper, mottling, grain, fibers, flecks, foxing, edge wear, scan crop/opacity, cloth weave, and ink
- versioned material-profile export/import
- a static Material Lab snapshot generator for CI review
- Stage 2 tests for round-trip serialization, value semantics, determinism, profile selection, and debug availability

The Material Lab depends on `JJWWMaterials`. `JJWWReaderCore` and the canonical historical content do not depend on the Lab.

## Tuning controls

### Lab

- profile picker
- `full / reduced / clean`
- deterministic `UInt64` seed
- reset to bundled Stage 1 values

### Paper

- warmth
- brightness

### Mottling

- amount
- scale
- count

### Grain

- amount
- scale
- resolution

### Fibers

- density
- minimum/maximum length
- opacity
- width

### Flecks

- density
- minimum/maximum radius
- opacity

### Foxing

- amount
- minimum/maximum radius
- count

### Edges

- wear amount
- edge width

### Scan slot

- opacity
- scale/crop
- X/Y offset

The scan asset itself remains empty until a real source image is supplied.

### Cloth

- enabled
- vertical/horizontal density
- opacity
- thread width

### Ink

- density
- future bleed amount

Ink bleed is persisted now so Stage 3 can use the same profile data for Ink Awakening. Stage 2 intentionally does not distress body glyphs.

## Export contract

`Export Profile` emits a deterministic JSON document with format:

`0.2-material-profile`

The export contains the entire tuned `MaterialProfileDefinition`, including paper and ink tuning. No timestamp is inserted, so identical values produce identical exported text.

Imported JSON must round-trip to the same profile.

A visual decision is not considered durable until it exists in exported profile data.

## Production boundary

`MaterialLabView` exists only under `#if DEBUG` in the separate `JJWWMaterialLab` target.

The future production reader target should depend on `JJWWMaterials`, not `JJWWMaterialLab`.

Stage 2 CI also builds the production `JJWWMaterials` target in Release configuration as a boundary check.

## Gate commands

From `ios/JJWWReader`:

```bash
swift test
swift run jjww-stage0-print > /tmp/jjww-stage0-print.txt
swift run jjww-material-lab-snapshot \
  --output /tmp/jjww-material-lab-stage2.png \
  --export-dir /tmp/jjww-material-profile-exports
swift build -c release --target JJWWMaterials
```

## Gate

Review the Material Lab itself before Stage 3.

The six bundled Stage 1 profiles remain provisional starting points. The next visual action is to tune them in the Lab and commit exported profile values. Do not hand-tune scattered Swift constants.

Stage 2 contains no Scroll reader, page reader, Ink Awakening animation, pagination, annotations, facsimile reader, or full-book population.
