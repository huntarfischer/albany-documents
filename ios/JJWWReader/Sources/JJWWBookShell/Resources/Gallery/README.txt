JJWW EDITORIAL GALLERY

This directory is the app's image library.

For ordinary research collection, put images in:

Gallery/Research/

The Gallery scanner is recursive. Supported images anywhere under Gallery, including Research subfolders, are bundled with the app and automatically appear in the developer Gallery as UNPLACED research images unless they already have a manifest entry.

Supported extensions:
- png
- jpg / jpeg
- heic
- tif / tiff

To promote an image into the authored manuscript flow, add a manifest entry to editorial-gallery-manifest-v0.1.json with:
- stable id
- Gallery-relative filename
- role
- title / caption / credit / alt text
- insertionStyle
- optional placement { canonicalLine, edge }

Examples of Gallery-relative filenames:
- Research/cherry-hill-exterior.jpg
- Research/maps/albany-1827.png

Do not infer historical placement from a filename or research folder. Placement is explicit because the manuscript order is authored evidence/pacing. Research images may remain unplaced indefinitely.

Known Stage 7 asset filenames already reserved by the manifest:
- JJWW UPDATED COVER copy.jpeg
- SYMBOL NAVY.png
- new ALBANY FIRST MAP BW CROPPED TITLE.jpg

Those three reserved production assets may remain at the Gallery root so their existing manifest filenames continue to resolve.

The Albany map is the delayed in-book title plate. It must not be moved to the front simply because its role is a title.
