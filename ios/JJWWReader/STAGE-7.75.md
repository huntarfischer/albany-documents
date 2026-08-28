# JJWW Reader — Stage 7.75

Status: `IMPLEMENTED_PENDING_GATE`

Branch: `feature/jjww-reader-stage7-75`

Stage 7.75 turns the proven package reader into a runnable iOS application and gives the editorial team a live composing table for the production reader. It does not expand the five-section fixture into the complete edition; that is Stage 8.

## iOS host

A thin native application target now lives at:

`ios/JJWWApp/JJWWApp.xcodeproj`

The app:

- boots the sealed canonical Layer 0 v1.1 fixture
- loads the bundled material and editorial-gallery stores
- creates the existing `BookShellSession`
- presents the production `JJWWBookView`
- keeps the existing Scroll / Pages synchronization and saved semantic reading location
- exposes the Reader Lab from a DEBUG-only floating workshop button

### Run in Xcode

1. Open `ios/JJWWApp/JJWWApp.xcodeproj`.
2. Select the shared `JJWWApp` scheme.
3. Choose an iPhone Simulator.
4. Press Run.
5. In a Debug build, tap the sliders button at the lower-right to open the Reader Lab.

The application target uses the local `../JJWWReader` Swift package. The canonical v1.1 JSON is copied into the app bundle as a resource; the app does not maintain a second text copy.

## Reader Workshop

The Reader Lab now brings together five development surfaces:

- `Workshop` — live material, typography, composition and print tuning against a real production `ReadingUnitSurface`
- `Staging` — live periodical paper-object geometry, deckle, backing, shadow and interval tuning
- `Material` — the existing detailed material laboratory
- `Ink` — the existing Ink Awakening laboratory
- `Pages` — the existing Page Composition laboratory

The Workshop preview deliberately renders the same production reading surface used by the app. There is no parallel specimen renderer whose appearance can drift away from the reader.

## Live profile overrides

Stage 7.75 adds temporary DEBUG-time tuning registries for:

- material profiles
- typography profiles
- shared reader-composition profiles
- periodical staging profiles

When no override exists, the original bundled/catalog profile remains authoritative. Reset removes the draft override. Approved values can be exported as JSON and later checked into the normal profile catalogs.

No Workshop operation mutates Canonical Layer 0.

## Typography + print controls

The Workshop exposes the variables repeatedly discovered during the Stage 7.5 Argus passes, including:

- font family by typography role
- text style and weight
- tracking and line spacing
- alignment and hyphenation
- header scale and spacing
- date / masthead / title role-specific scales
- role-specific tracking adjustments
- rule geometry
- body leading and paragraph rhythm
- print wear, stroke starvation, edge erosion and dark deposit
- print opacity and paper-multiply behavior
- opening insets

The Stage 7.5b/c Argus finish values are now profile data rather than hidden renderer constants.

## Physical staging controls

The periodical Staging lab exposes:

- sheet horizontal inset
- deterministic sheet drift
- sheet rotation
- backing-paper layer count
- backing drift
- deckle roughness
- editorial interval exposure
- stack vertical padding
- contact shadow opacity / radius / offset
- ambient shadow opacity / radius / offset

Default values reproduce the Stage 7.5 production appearance. Editing them changes the actual periodical production surface.

## Canonical and V1 boundary

Stage 7.75 intentionally keeps the current five-section edition fixture. It does not yet solve the known prototype modeling mismatch in which canonical lines 1–5 are represented as a `.cover` ReadingUnit. Stage 8 will separate the exterior app cover from the complete canonical interior and map all 2,069 canonical lines into the V1 edition.

The Stage 7.75 gate therefore proves the app host and composing tools without pretending full-book mapping has already happened.

## Gate

Stage 7.75 passes when:

- all existing Swift package tests pass
- the real `JJWWApp` iOS application target builds for iOS Simulator
- the existing Stage 7.5 snapshot product still builds in Release
- default live-tuning profiles preserve the Stage 7.5 reader grammar
- Reader Workshop changes flow through production renderers rather than a mock preview

CI workflow:

`.github/workflows/jjww-reader-stage7-75.yml`

Once this gate is green, Stage 8 can begin the full canonical edition rebase and mapping with a runnable book and a live composing environment already in hand.
