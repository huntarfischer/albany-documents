# Jesse James and the Widow Whipple
## Layer 1: Canonical Structural Index + Source Registry

**Status: SEALED**

Layer 1 is derived from the frozen Layer 0 canonical transcription. It adds structure and source provenance without correcting, normalizing, reconciling, or historically interpreting the manuscript.

## Architecture

Layer 1 now has two structural levels:

- **Containers:** the 82 exact Layer 0 blocks. These cover all 2,069 lines with zero gaps and zero overlaps.
- **Units:** finer manuscript objects inside or across those containers, including dated items, source sections, embedded documents, witness testimony segments, procedural labels, advertisements, letters, images, appendix entries, timeline entries, and bibliography entries.

Nested units may overlap because one passage can simultaneously belong to a source context and a documentary or testimony structure. The immutable container layer remains the gapless coverage proof.

## Source Registry repair

The Source Registry no longer assumes that the first line of an attribution cluster is automatically the source identity. It now stores separate fields for source title, type, publication, author, date, institution, recipient, and occurrence role.

It also distinguishes:

- `direct_attribution`
- `direct_source_context`
- `inherited_source_context`
- `archive_acknowledgment`
- `bibliography_entry`
- `embedded_document_attribution`

Where the manuscript does not state an immediate source, Layer 1 leaves the passage unattributed rather than guessing.

## Validation

- Layer 0 lines: **2069**
- Layer 0 SHA-256: `735edd6b4b60fdf1d019ac9baa0644ed21ce71bdf48018ef42634e38eef9fba7`
- Exact Layer 0 containers: **82**
- Container gaps: **0**
- Container overlaps: **0**
- Hierarchical structural units: **468**
- Source records: **67**
- Source occurrences: **82**
- Source contexts: **44**
- Inherited trial source contexts: **13**

### Reverse completeness audit

- `all_internal_datelines_represented`: **true**
- `all_witness_calls_have_segments`: **true**
- `all_images_represented`: **true**
- `all_appendix_people_entries_represented`: **true**
- `all_timeline_entries_represented`: **true**
- `all_bibliography_entries_represented`: **true**
- `all_required_documents_represented`: **true**
- `all_required_document_sources_represented`: **true**

## Explicit repairs confirmed

- The nested August 3 **Troy Sentinel** article has its own structural unit.
- The 1775 letter, 1789 reward advertisement, and 1815 Columbian Hotel advertisement have their own structural units and source/document records.
- *The Last Will and Testament of Philip Van Rensselaer* has its own structural and source record.
- *The Testimony of Robert Wynkoop Lansing* has its own structural and source record, with `Sent to his daughter Margaret Elizabeth Butler` retained as recipient metadata rather than source identity.
- *Farewell Address* has its own structural and source record.
- `Broadside` is retained as document-type metadata rather than treated as the source title.
- `Albany County Sheriff` is retained as institutional attribution for *The Voluntary Examination Of Elsie Whipple* rather than treated as the document title.
- Trial-day spans inherit source context only from an explicitly attributed trial-source span.

## Layer 1 boundary

Layer 1 answers: **where is the manuscript object, how is it structurally presented, and what source attribution or source context does the manuscript explicitly provide?**

Layer 1 still does not resolve aliases, determine which claims are true, reconcile dates, identify historical events as fact, or interpret evidence. Those operations remain reserved for Layer 2.
