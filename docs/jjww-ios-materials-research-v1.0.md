# Jesse James and the Widow Whipple
## iOS Reader Materials + Interaction Research v1.0

Status: RESEARCH COMPLETE, PRE-BUILD

Purpose: establish the material, motion, accessibility, and implementation principles for the five-section Swift-native reader prototype before the detailed build sequence is written.

The prototype sections remain:

1. May 8/9 Albany Argus
2. Monday June 18 Albany Daily Advertiser
3. The Confession
4. Trial of Jesse James Strang
5. Farewell Address

The supplied book cover is the visual north star. The app should feel assembled from historical objects rather than like a generic sepia archive.

---

# 1. Core design conclusion

The strongest precedents do not suggest making a screen imitate paper everywhere. They suggest keeping the authored text central, letting facsimile/materiality deepen the experience, and keeping apparatus available without forcing it over the reading surface.

The Waste Land iPad app is the clearest precedent. Its designers explicitly kept the poem at the center while annotations, facsimiles, performances, and commentary lived around it. Contemporary criticism of digital scholarly editions similarly emphasizes the value of linking transcriptions to scans, annotations, variants, and contextual information without letting interface complexity displace the primary text.

For JJWW this means:

- The book remains the center.
- Material changes signal source changes.
- Historical objects keep their own visual identities.
- JJWW's orange cloth, cream frames, clipped labels, black-and-white imagery, and visible seams act as the editorial binding.
- Scroll and Pages are two renderers of one canonical reading sequence.
- Archive, facsimile, notes, provenance, and discrepancies remain secondary layers invoked by curiosity.

Important caution from the literature on skeuomorphism: use physical metaphors when they carry meaning or provide a familiar interaction, not simply as ornament. The page mode is justified because the user explicitly chooses a codex-like reading form. The scroll mode should remain honestly digital rather than pretending to be a book page that happens to scroll.

---

# 2. Material principles derived from the cover

## 2.1 Editorial material versus historical material

Separate the two visually.

Historical materials:
- newspaper stock
- pamphlet stock
- legal/trial stock
- broadside stock
- later newspaper/book stock
- facsimile scans

Editorial binding:
- vermilion/orange cloth
- cream cut-paper frames
- black and white
- clipped title strips
- occasional acid yellow/ochre
- rare green archival/mottled accent

Rule: do not make every historical source wear the JJWW orange. Orange belongs primarily to the binding, navigation, transitions, annotation marks, and moments where the present edition reveals itself.

## 2.2 Visible construction

The cover is visibly layered. Preserve that idea in the interface:

- source transitions can have seams
- labels can look placed rather than digitally fused
- facsimile boundaries remain visible
- editorial notes should look editorial
- archival photos remain monochrome unless the source itself is color

This supports the scholarship: the reader can feel when a historical object ends and the compiler's apparatus begins.

## 2.3 Materiality should not damage legibility

Historical atmosphere is background. Text remains real Swift text.

Never rasterize the book's readable transcription just to make it look printed.

Keep:
- Dynamic Type
- VoiceOver
- text selection where appropriate
- searchability
- predictable line wrapping
- clean reading mode

Texture can change. Meaningful text must remain semantic text.

---

# 3. Design precedents and lessons

## 3.1 The Waste Land iPad app

Useful lessons:
- keep the primary text visually central
- keep interface chrome sparse
- let annotations and facsimile be optional layers
- use good screen typography rather than over-literal print simulation
- rich media is strongest when it deepens the text rather than replacing it

For JJWW: a user should be able to read the entire book without opening the apparatus, but one touch should open the source world beneath the passage.

## 3.2 Digital scholarly editions

Recent interface research identifies core DSE functions including:
- annotation/commentary
- linking scan regions to transcription fragments
- variants/discrepancies
- indexing/querying
- contextual background

For JJWW: exact source spans and Work/Passage structure are not backstage excess. They directly support Compare Accounts, Show Me the Source, facsimile linking, and later archive exploration.

## 3.3 Facsimile versus transcription

The best pattern is not "make transcription look exactly like the scan." Treat them as related but distinct modes.

Text mode:
- highly readable
- source-aware material treatment
- accessible
- annotatable

Original/facsimile mode:
- faithful image
- zoom/pan
- source metadata

Future iPad comparison mode:
- transcription beside original
- ideally aligned at passage level

## 3.4 Skeuomorphism

Use the physical metaphor only when the interaction keeps the promise.

Good uses for JJWW:
- optional page curl in Pages mode
- visible paper leaves/gutter in Pages mode
- tactile-looking cover threshold
- paper/cloth as meaningful source/editorial material

Avoid:
- fake page edges in Scroll mode
- slow animations that delay reading
- decorative leather/wood/book furniture unrelated to the actual book
- fake physical constraints that make search, notes, accessibility, or navigation worse

The reader can choose Pages because the physical metaphor is part of the pleasure. Scroll should exploit continuity and source transitions instead.

---

# 4. Swift-native material stack

Build materials as layers, not flattened images.

Suggested stack:

1. base color field
2. broad color variation
3. micrograin
4. fibers/flecks
5. stains/foxing, restrained
6. edge treatment where appropriate
7. source scan overlay, optional
8. print/ink treatment, extremely restrained
9. text, always semantic and crisp

## 4.1 SwiftUI Canvas

Use Canvas for noninteractive decorative drawing:
- fibers
- flecks
- sparse stains
- cloth threads
- edge abrasions

Apple explicitly notes that Canvas is appropriate for rich drawing and can improve performance for complex noninteractive graphics, but individual Canvas contents do not provide their own accessibility. That makes Canvas ideal behind text, not as the text itself.

## 4.2 Core Image random/noise generation

CIRandomGenerator can supply procedural noise. Generate deterministic/cacheable texture derivatives rather than running expensive random generation continuously during reading.

Recommended uses:
- paper micrograin
- print density variation mask
- stain mask seed
- subtle nonrepeating modulation over scanned texture

Do not animate paper noise while the user reads. The page should feel material, not alive.

## 4.3 SwiftUI image tiling

ImagePaint and GraphicsContext tiled-image shading can repeat source regions. Use carefully because obvious tiling is fatal to material illusion.

For real scans:
- prefer large source scans
- select deterministic subregions per page/reading unit
- combine with procedural low-frequency variation
- avoid repeating the same tiny patch across the full screen

## 4.4 Metal shaders

SwiftUI supports colorEffect, distortionEffect, and layerEffect using stitchable Metal functions.

Reserve shaders for effects that genuinely need per-pixel behavior:
- subtle ink bleed
- nonrepeating mottling
- section ink reveal
- minute print registration/ink variation
- later page-lighting during curl if needed

Do not start the MVP with a shader-heavy material system. The first implementation should prove the aesthetic with gradients, Canvas, Core Image, scans, and blend modes. Add Metal where simpler tools cannot produce the right result.

Important Apple caveat: layerEffect rasterizes the view layer and UIKit/AppKit-backed content may not participate correctly in the filtered layer. Keep shader effects scoped to decorative layers or SwiftUI-native text/elements that have been tested.

## 4.5 TextRenderer

TextRenderer is the best native foundation for the section-heading ink reveal because it changes drawing behavior while keeping SwiftUI's text layout.

Use it for short section-open text only:
- date
- newspaper/source name
- chapter/section title
- perhaps a one-line deck

Do not animate every body-text glyph for long passages. Per-frame custom glyph work scales with text length and can become unnecessarily expensive.

---

# 5. Section "ink awakening" effect

Design inspiration: the Marauder's Map idea of writing becoming visible on apparently blank material, without copying the film's exact graphics.

JJWW version: INK AWAKENING.

At the top of every major section, the header appears as though ink is developing into the paper.

Sequence target, approximately 0.9 to 1.4 seconds total:

1. faint warm/dark ghost appears irregularly
2. strokes resolve in an uneven left-to-right plus blot-by-blot progression
3. tiny ink halo/spread becomes visible around some glyph edges
4. final crisp text settles

The motion should feel chemical/capillary rather than typed.

Implementation path:

- semantic SwiftUI Text
- custom TextRenderer with one animatable progress value
- deterministic seeded noise function based on glyph/run position
- reveal threshold varies slightly by location to avoid a mechanical wipe
- optional low-opacity shader or blurred secondary draw for an ink halo
- final state is standard readable text

Best practice:
- precompute or cheaply derive reveal thresholds
- animate one scalar progress value
- never run expensive image/filter generation inside KeyframeAnimator content every frame
- effect plays only when entering a section at its top, not every time a previously read header glances back into view
- user can replay it later from a Material Lab if desired

Accessibility:
- if accessibilityReduceMotion is true, show final text immediately or use a short crossfade
- if Reduce Transparency is true, avoid depending on translucent layering for legibility
- VoiceOver receives the complete text immediately, independent of visual reveal
- Clean material mode can disable the effect entirely

This is a section-opening flourish, not body-text behavior.

---

# 6. Page mode best practice

UIKit UIPageViewController still supports the pageCurl transition, and with a data source the curl follows the user's finger. It also supports spine location and double-sided behavior.

Use it as an optional Pages renderer, wrapped in SwiftUI.

Do not let page curl control the content architecture. Content is paginated from the same canonical ReadingUnits used by Scroll.

TextKit 2 should own pagination. NSTextLayoutManager is designed for custom text layout through NSTextContainer geometry.

Rules:
- page numbers are derived, never canonical data
- Dynamic Type changes pagination
- reader position is anchored to canonical passage/text location, not page number
- mode switching lands on the same canonical anchor
- Reduce Motion replaces curl with a crossfade/instant page transition

The visual page can feel aged; the navigation should still be responsive.

---

# 7. Scan/master asset policy

The app needs two distinct image classes:

ARCHIVAL MASTER
- preserved outside app-delivery optimization
- highest useful resolution
- embedded/known color profile
- unmodified master retained
- metadata retained

APP DERIVATIVE
- device-appropriate size
- cropped/downsampled from master
- optimized/compressed for delivery
- never becomes the archival authority

FADGI's 2023 cultural-heritage imaging guidance emphasizes explicit imaging objectives, quality measurement, color management, and master-file practice. Library of Congress format guidance likewise prefers highest available resolution/bit depth and embedded or specified color profiles for master digital images.

Practical JJWW rule: never overwrite the good scan to make the app faster. Generate derivatives.

For Xcode delivery, use asset catalogs so app thinning and asset optimization can work. Apple recommends asset catalogs for image/texture resources and supports metadata/device targeting and compression choices.

For Core Image processing:
- reuse CIContext rather than creating one per render
- downsample before expensive filtering where full source resolution is unnecessary
- cache stable material derivatives
- do not repeatedly push huge scans through the GPU during scrolling

---

# 8. Material tuning system

This should be designed into the MVP from the beginning even if users do not initially see all controls.

There are two control layers.

## 8.1 Reader-facing Material control

Material:
- Full
- Reduced
- Clean

Full = intended art direction
Reduced = lighter grain/stains/edge effects, same source identity
Clean = high-legibility paper color with nearly all material effects off

This is a preference, not a different edition.

## 8.2 Developer/editorial Material Lab

A hidden/internal tuning panel should be available in debug/test builds and easy to promote into an editor tool later.

Per MaterialProfile sliders/toggles:

Paper
- base hue
- warmth
- brightness
- contrast
- broad mottling amount
- broad mottling scale
- grain amount
- grain scale
- fiber density
- fiber opacity
- fleck density
- foxing amount
- foxing scale
- edge wear
- vignette/edge darkening

Scan
- generated only / scan only / hybrid
- scan opacity
- scan crop seed
- scan contrast
- scan saturation
- scan tint strength

Ink
- ink density
- ink warmth
- print noise
- bleed radius
- bleed amount
- registration drift, later

Cloth
- thread density X
- thread density Y
- weave contrast
- irregularity
- grain

Section reveal
- enabled
- duration
- turbulence/noise amount
- edge softness
- blot size
- halo amount
- reveal direction bias

Global
- animation on/off
- Reduce Motion simulation
- Reduce Transparency simulation
- Dynamic Type preview

The important architectural decision: tuning values live in data, not scattered Swift constants.

Suggested structure:

MaterialProfile defaults
+
MaterialTuningOverrides
=
ResolvedMaterialProfile

During development, Material Lab writes/exports a JSON or plist profile that can later become the new default. That lets the team tune visually on device without rewriting view code.

Profiles for the prototype:
- jjwwEditorial
- argus1827
- dailyAdvertiser1827
- confessionPamphlet1827
- trialRecord1827
- farewell

The Material Lab should be able to switch among all six on one screen for side-by-side tuning.

---

# 9. Accessibility requirements are material requirements

Treat accessibility states as part of the material engine rather than as cleanup.

SwiftUI exposes:
- accessibilityReduceMotion
- accessibilityReduceTransparency
- DynamicTypeSize and accessibility sizes
- VoiceOver state
- crossfade preference

Rules:

Reduce Motion:
- no 3D page curl
- no ink-development animation
- crossfade or immediate state

Reduce Transparency:
- opaque controls/backgrounds where needed
- do not depend on translucent cream/orange overlays for text contrast

Dynamic Type:
- body text scales through the complete accessibility range
- custom fonts must be configured relative to semantic text styles
- ScaledMetric for margins/padding that must grow with type
- page mode repaginates rather than clipping

VoiceOver:
- decorative Canvas layers ignored
- text exists in semantic reading order immediately even during visual reveal
- texture names are not announced unless materially meaningful

Clean Material:
- always available regardless of system accessibility settings

---

# 10. Five-section material laboratory

## Albany Argus, May 8/9
Purpose: establish early newspaper family.

Test:
- warm-gray cream newsprint
- low contrast grain
- tight text measure
- masthead/date hierarchy
- subtle uneven ink
- section Ink Awakening for date + masthead

## Albany Daily Advertiser, June 18
Purpose: prove two 1827 newspapers can be related without being visually identical.

Change:
- slightly different base tint
- different masthead/header rhythm
- modestly different grain/ink profile
- same broad 1827 newspaper family

## Confession
Purpose: shift from public newsprint to intimate pamphlet/book stock.

Test:
- warmer stock
- quieter background
- narrower text block
- longer paragraph rhythm
- letters/reconstructed documents can become inset objects later
- section Ink Awakening becomes more bookish and slower

## Trial
Purpose: solve the densest text and multiple voices.

Test:
- cooler/cleaner legal stock
- witness/counsel/court hierarchy
- material restrained so density stays legible
- source-voice typography is more important than visual aging
- annotation marker prototype lives here

## Farewell
Purpose: test restraint.

Test:
- quiet cream leaf
- almost no stains
- spacious verse
- apparatus visually suppressed by default
- Ink Awakening can be slowest and most delicate here

If Farewell feels as visually loud as the newspaper, the material system has failed.

---

# 11. Performance budget principles

- Generate/cook stable paper textures once and cache them.
- Reuse CIContext.
- Keep body text out of Canvas/shader rasterization.
- Limit animated TextRenderer use to short section headers.
- Never animate paper grain continuously.
- Downsample high-res scans for screen use while retaining archival masters separately.
- Use asset catalogs for shipping assets.
- Profile shaders on real devices before promoting them from experimental to default.
- KeyframeAnimator content is evaluated every frame, so expensive filtering/generation does not belong there.
- Page curl is optional and disabled/replaced under Reduce Motion.

---

# 12. Decisions to carry into the detailed build sequence

1. One edition model, two renderers: Scroll and Pages.
2. Cover is the art-direction source, not a generic historical-app theme.
3. MaterialProfile is data-driven from Stage 0.
4. Material Lab exists from the first material prototype.
5. Generated textures are placeholders/companions for later real scans, not throwaway code.
6. Real scans are preserved as masters and shipped through derivatives.
7. Section headers use the Ink Awakening effect.
8. Ink Awakening is semantic TextRenderer-based, short, deterministic, and accessibility-aware.
9. Text remains real text at all times.
10. Canvas is decoration only.
11. Metal is optional escalation, not the baseline material engine.
12. Page curl is user-chosen Pages behavior, never forced on Scroll.
13. The five-section prototype must prove visual transitions before full-book population.
14. Material tuning values must be exportable so visual iteration does not become code editing.
15. The detailed build sequence should stop for approval after each stage rather than running ahead.

---

# 13. Research sources

Apple Developer Documentation
- Canvas: https://developer.apple.com/documentation/swiftui/canvas
- Shader: https://developer.apple.com/documentation/swiftui/shader
- TextRenderer: https://developer.apple.com/documentation/swiftui/textrenderer
- KeyframeAnimator: https://developer.apple.com/documentation/swiftui/keyframeanimator
- accessibilityReduceMotion: https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion
- accessibilityReduceTransparency: https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducetransparency
- DynamicTypeSize: https://developer.apple.com/documentation/swiftui/dynamictypesize
- Applying custom fonts to text: https://developer.apple.com/documentation/swiftui/applying-custom-fonts-to-text
- UIPageViewController pageCurl: https://developer.apple.com/documentation/uikit/uipageviewcontroller/transitionstyle-swift.enum/pagecurl
- NSTextLayoutManager / TextKit 2: https://developer.apple.com/documentation/uikit/nstextlayoutmanager
- ImagePaint: https://developer.apple.com/documentation/swiftui/imagepaint
- Core Image random generator: https://developer.apple.com/documentation/coreimage/cifilter-swift.class/randomgenerator()
- CIContext: https://developer.apple.com/documentation/coreimage/cicontext
- Xcode app-size / asset-catalog optimization: https://developer.apple.com/documentation/xcode/doing-basic-optimization-to-reduce-your-app-s-size

Digital-book and scholarly-edition design
- Hilary Kenna, "Touching the text of T. S. Eliot's The Waste Land": https://intellectdiscover.com/content/journals/10.1386/btwo.1.2.207_1
- 100 Archive, The Waste Land iPad: https://www.100archive.com/projects/the-waste-land-ipad
- International Journal of Digital Humanities, "User interfaces of digital scholarly editions: a proposal for an evaluative framework": https://link.springer.com/article/10.1007/s42803-025-00102-y
- Digital Humanities Quarterly, "Distributed reading: Literary reading in diverse environments": https://www.digitalhumanities.org/dhq/vol/12/2/000389/000389.html
- Digital Scholarly Editions as Interfaces: https://kups.ub.uni-koeln.de/9085/1/SIDE_12_digital_scholarly_editions_as_interfaces.pdf

Cultural-heritage imaging
- FADGI 2023 Technical Guidelines: https://www.digitizationguidelines.gov/guidelines/digitize-technical.html
- Library of Congress Recommended Formats, Still Image Works: https://wwws.loc.gov/preservation/resources/rfs/stillimg.html

Implementation/inspiration references, non-authoritative
- Per-glyph TextRenderer animation example: https://swiftloop.dev/per-glyph-text-animation-swiftui-textrenderer/
- SwiftUI shader collection with ink-bleed experimentation: https://github.com/krispuckett/SwiftUIShaders

These implementation references are inspiration only. The production app should own its material system rather than importing visual identity wholesale from a third-party effects package.
