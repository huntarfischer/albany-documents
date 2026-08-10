# Jesse James and the Widow Whipple
## Layer 1 Double-Check Audit

**Status: NOT SEALED**

The existing Layer 1 files are mechanically sound, but the audit found specification-level issues that should be corrected before Layer 1 is considered canonical.

## What passed

- Layer 0 remains exactly **2,069 lines**.
- The Layer 0 SHA-256 still matches: `735edd6b4b60fdf1d019ac9baa0644ed21ce71bdf48018ef42634e38eef9fba7`.
- All **82** Layer 0 structural blocks are covered with **0 gaps** and **0 overlaps**.
- The **4** explicit continuation blocks resolve correctly, producing **78** logical objects.
- IDs are unique and all internal references resolve.
- Every stored marker range points to the exact Layer 0 text.
- Every stored source-occurrence range points to the exact Layer 0 text.
- The ZIP package passes integrity testing.

## What needs correction before Layer 1 can be sealed

### 1. Structural granularity is incomplete

The current index faithfully mirrors Layer 0 blocks, but Layer 1 was supposed to index the manuscript at a finer structural level too.

Examples that need promotion into explicit structural units include:

- the nested **Friday, August 3, 1827 / The Troy Sentinel / THE TRIAL OF MRS. WHIPPLE** item;
- the 1775 letter, 1789 advertisement, and 1815 hotel advertisement embedded in the Cherry Hill material;
- testimony spans rather than witness-call markers alone;
- legal arguments and rulings where the manuscript clearly marks them;
- poems, advertisements, and other embedded documents.

The 82 Layer 0 blocks should remain as immutable containers. Layer 1 needs a second hierarchical unit layer inside them.

### 2. The Source Registry model is too coarse

The line addresses are correct, but the current registry sometimes treats the first line of an attribution cluster as though it were necessarily the source identity.

That causes several classification problems:

- `Colonial Days And Ways` is being used as the source label for a cluster that explicitly contains `The Strang Family Genealogy` and `Josephine Frost, 1915`.
- `Broadside` is being used as a source identity when it is better preserved as a document type, with *The Pictorial Life and Adventures of Mrs. Whipple & Jesse Strang, 1848* recorded separately as the reproduction source.
- `Albany County Sheriff` is being used as the source identity for *The Voluntary Examination Of Elsie Whipple*, when it is institutional attribution metadata.
- `Sent to his daughter Margaret Elizabeth Butler` is being treated as a source identity instead of recipient metadata for *The Testimony of Robert Wynkoop Lansing*.

### 3. Some documents are missing from the Source Registry

At minimum, explicit document/source records still need to be created for:

- *The Last Will and Testament of Philip Van Rensselaer*
- *The Testimony of Robert Wynkoop Lansing*
- *Farewell Address / The final words of Jesse James Strang*

### 4. Trial source context needs inheritance

The trial source headers are present, but subsequent trial-day blocks often have no source association.

Layer 1 should distinguish:

- `direct_attribution`
- `inherited_source_context`

That lets the manuscript structure carry a source forward without pretending that every trial-day block repeats a source label that is not actually printed there.

### 5. The validation needs one more dimension

The existing validation proves that the addresses are correct.

It does **not** yet prove that each address was classified as the correct manuscript object type.

The final Layer 1 audit should therefore include both:

1. address/provenance validation; and
2. reverse structural completeness validation.

## Required repair pass

Before sealing Layer 1:

1. Keep the 82 Layer 0 blocks unchanged as containers.
2. Add hierarchical structural units inside them.
3. Rebuild the Source Registry with separate fields for title, type, author, date, publication, institution, recipient, and occurrence role, all preserved as written.
4. Separate passage attribution, inherited source context, front-matter credits, archive acknowledgments, and bibliography entries.
5. Add the missing embedded-document source records.
6. Run the reverse Layer 0 completeness audit.
7. Seal Layer 1 only after that audit is green.

No Layer 2 entity, event, claim, evidence, or trial modeling should begin before these corrections are complete.
