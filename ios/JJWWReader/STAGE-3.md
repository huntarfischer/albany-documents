# JJWW Reader Stage 3
## Typography + Ink Awakening Laboratory

**Branch:** `feature/jjww-reader-stage3`

## Scope

Stage 3 proves typography and the section-opening Ink Awakening ritual before either enters the Scroll reader.

It deliberately does not build the reader, pagination, page curl, annotations, Archive UI, or full-book population.

## Typography profiles

The Stage 0 profile IDs now resolve to reusable typography definitions for:

- JJWW editorial binding
- 1827 newspaper
- confession pamphlet
- trial record
- Farewell Address

The profiles use semantic Dynamic Type styles rather than fixed body-text point sizes. Roles include date/source/title, body prose, confession first-person prose, witness/counsel/court labels, verse, and editorial cut-paper labels.

## Ink Awakening

`InkAwakeningText` keeps real SwiftUI text as the source and reveals it through a deterministic seeded mask.

Rules:

- section-opening date/source/title only
- irregular blot/stroke reveal, never typewriter order
- deterministic seed
- data-controlled duration, irregularity, blot scale, threshold, curve, feather, and trace count
- natural section entry animates once
- jump/search entry resolves instantly
- Reduce Motion uses a short fade
- final text content and accessibility label are unchanged

Five provisional Ink profiles exist for:

- Argus
- Daily Advertiser
- Confession
- Trial
- Farewell

The Farewell profile is intentionally slower and less agitated than the newspaper entrance.

## Material Lab extension

The hidden development lab now has a Material/Ink wrapper with an Ink tuning view. Ink profile values can be exported/imported as versioned `0.3-ink-profile` JSON.

## Stage 2 feedback carried forward

The user approved the orange color and fibers but did not want the visible large circles in the paper treatment. Stage 3 replaces circular broad mottles with blurred elongated washes while preserving the existing color/fiber language.

## Tests

Stage 3 tests cover:

- five typography profiles
- five prototype Ink profiles
- semantic Dynamic Type roles
- Reduce Motion behavior
- jump/search instant rendering
- natural-entry animation policy
- Ink profile Codable round trip
- Material Lab Ink profile round trip
- draft tuning isolation

The CI gate also reruns all earlier tests and the canonical Stage 0 plain-text gate.

## Visual gate

CI renders:

1. a typography/Ink specimen sheet showing 25%, 58%, and 100% reveal states for all five prototype sections
2. a revised full material sheet verifying that broad paper mottling no longer reads as circular spots

## Stop condition

Do not start Stage 4 Scroll Reader until the Stage 3 CI gate is green and the visual specimen is reviewed.
