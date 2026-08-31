# JJWW Reader — Stage 7.8 Native Host Finish

Status: `IMPLEMENTED_PENDING_LOCAL_GATE`

Branch: `feature/jjww-reader-stage7-75`

Stage 7.8 is a bounded hardening pass between the Stage 7.75 Simulator Host / Reader Workshop and Stage 8 full-edition mapping. It does not change canonical text, expand the five-section fixture, rebase Layer 1, or begin the 2,069-line Edition map.

## Production reader chrome

The compact reader toolbar is reduced to the controls that need to remain visible while reading:

- `JJWW` — return to exterior cover
- current reading-unit label
- `Aa` — text size
- one current-mode menu for Scroll / Pages
- overflow menu for material appearance and hiding chrome

The developer Editorial Gallery is removed from production reader chrome. The horizontal progress rule now measures the actual available toolbar width rather than assuming a 390-point phone.

## Reader Lab

Editorial Gallery moves into the DEBUG Reader Lab. Reader Lab now owns the development surfaces for:

- Workshop
- Staging
- Material
- Ink
- Pages
- Gallery

The app passes the same live bundled `EditorialGalleryStore` used by the cover into Reader Lab. There is no second Gallery implementation or second asset index.

Workshop keeps the production preview and existing controls; its compact segmented control shortens `Composition` to `Comp.` so all five Workshop panes remain legible on phone width.

## Gallery semantics

Gallery continues to discover research images recursively under `Resources/Gallery/Research/`.

Stage 7.8 distinguishes shell assets from manuscript-flow placement:

- exterior cover → `SHELL`
- publisher mark → `SHELL`
- delayed Albany title plate → `UNPLACED` until its authored canonical position is assigned
- automatically discovered research image → `NEW · UNPLACED`

The Gallery title is rendered as part of the Gallery surface so it remains legible against the dark editorial background.

## Cover finish

The supplied production cover remains fit-to-viewport with no new crop behavior. The publisher mark receives a modest size/opacity increase only; Stage 7.8 does not redesign the cover.

## Gate

Before Stage 8 begins, verify locally on the iPhone 17 Pro Simulator:

1. Production cover and publisher mark resolve.
2. OPEN BOOK enters the reader.
3. Compact chrome fits without clipping.
4. `Aa` changes text scale.
5. Scroll / Pages can be switched from the single mode menu.
6. Material appearance is available from overflow.
7. Chrome can hide and return.
8. DEBUG Reader Lab opens and can dismiss back to the book.
9. Gallery is reachable from Reader Lab and no longer from production chrome.
10. Cover and publisher mark show `SHELL`; Albany title plate remains `UNPLACED`.
11. Workshop's five-pane segmented control fits at compact width.
12. Existing package tests and the native simulator build remain green.

Once this gate passes, freeze the host and begin Stage 8 at the approved canonical ownership/mapping architecture.
