# Jesse James and the Widow Whipple
## Canonical Data Architecture Plan

This document defines the post-transcription architecture for the canonical machine-readable edition of *Jesse James and the Widow Whipple*.

The governing principle is simple:

> Preserve the book first. Derive structure second. Interpret only after provenance is secure.

Layer 0 is now complete and should be treated as immutable source data. All later layers must derive from it without silently rewriting it.

---

# Layer 0: Book

## Purpose

Layer 0 is the canonical transcription of the manuscript.

It preserves the corrected RTF as a machine-readable line sequence and structured JSON representation.

## Status

Complete.

## Canonical requirements

- Layer 0 is immutable.
- No later process may silently alter Layer 0 wording.
- Every derived object in later layers should be traceable back to Layer 0.
- The canonical line sequence remains the ultimate provenance anchor.
- Historical corrections, normalization, interpretation, and reconciliation belong in later layers only.

## Canonical manifest

Create and preserve a small manifest containing:

- canonical title
- source filename
- source extraction method
- total source line count
- canonical version
- canonical JSON filename
- canonical Markdown filename
- SHA-256 checksum
- creation date
- rule that derived layers may reference Layer 0 but may not overwrite it

This manifest functions as the checksum and identity record for the canonical book.

---

# Layer 1: Structure

Layer 1 describes what already exists in the book without interpreting its historical meaning.

Its purpose is to answer:

- Where is something in the book?
- What kind of manuscript object is it?
- What source does the manuscript attribute it to?
- What exact Layer 0 lines contain it?

Layer 1 should remain conservative and noninterpretive.

## 1. Structural Index

Create a stable structural index for the complete manuscript.

Index every identifiable manuscript object, including:

- dated entries
- newspaper items
- pamphlet sections
- trial sections
- confessions
- testimony blocks
- legal rulings
- family-history extracts
- genealogy
- retrospective historical accounts
- poems
- advertisements
- image placeholders
- interstitial material
- appendix sections
- source lists
- acknowledgments
- copyright and back matter

Each structural object should receive:

- stable ID
- object type
- heading or dateline as written
- parent section if applicable
- Layer 0 start line
- Layer 0 end line
- source attribution text as written
- sequence position

The index must preserve manuscript hierarchy without inventing historical conclusions.

## 2. Source Registry

Create a registry of every source represented in the manuscript.

Examples include:

- Albany Argus & City Gazette
- Poughkeepsie Journal
- Albany Daily Advertiser
- The Evening Post
- trial pamphlets
- Strang confession pamphlets
- Elsie Whipple's voluntary examination
- *A Legacy of Historical Gleanings*
- *The Pictorial Life and Adventures of Mrs. Whipple & Jesse Strang*
- *The Record Of Crimes in the United States*
- 1905 newspaper retrospective
- 1967 *Knickerbocker News* retrospective
- archival documents
- book editorial/interstitial material

The Source Registry records what the manuscript says the source is.

It does not yet determine whether an attribution is historically correct.

Each source should receive:

- stable source ID
- source name as written
- author as written, when present
- date as written, when present
- publication as written, when present
- source category
- first Layer 0 occurrence
- all Layer 0 occurrences
- structural objects associated with the source

## Layer 1 validation

Before moving to Layer 2:

- every structural object must point to valid Layer 0 lines
- every source attribution must point to the text where it appears
- no Layer 0 text may be altered
- no historical claim should be introduced
- no alias resolution should be performed unless the manuscript itself explicitly establishes it
- no dates should be normalized
- no contradictory source statements should be reconciled

Layer 1 should be capable of answering structural queries without historical interpretation.

Examples:

- Where are the three Strang confessions?
- Show every Albany Argus item.
- Which manuscript objects fall between May 7 and May 17?
- Where does the Elsie trial begin and end?
- Which passages come from *A Legacy of Historical Gleanings*?
- Where are image placeholders located?

---

# Layer 2: Chronicle

Layer 2 derives historical and case structure from Layer 0 and Layer 1.

Unlike Layer 1, Layer 2 may identify relationships between statements, people, evidence, and events.

Every Layer 2 object must preserve provenance back to Layer 0.

## 3. Entity Registry

Begin with people and places.

Extract names exactly as they appear, then resolve aliases separately.

Examples:

- Jesse Strang
- Jesse James Strang
- Joseph Orton
- Doctor

These may eventually resolve to one entity, but the original textual forms must remain preserved.

The same applies to:

- Elsie D. Whipple
- Elsie Douw Lansing Whipple
- Cherry Hill
- Columbian Hotel
- Hamilton Hollow
- Albany County jail
- courts
- roads
- taverns
- residences

Each entity should include:

- stable entity ID
- canonical display label
- entity type
- textual forms
- aliases
- mentions
- Layer 0 provenance
- source-specific forms
- unresolved ambiguity where applicable

Do not begin with biographies.

The first job of the Entity Registry is simply to answer:

> Who or what is being referred to?

## 4. Event Ledger

Extract discrete occurrences rather than prose summaries.

Examples:

- John Whipple returns home
- John Whipple is shot
- the scene is examined
- witnesses are questioned
- Strang is committed
- Strang's true identity is disclosed
- Strang confesses
- the rifle is recovered
- a grand jury indicts
- Elsie is arrested
- Strang's trial opens
- a witness testifies
- a ruling is issued
- a verdict is returned
- a sentence is pronounced
- Strang is executed

Each event should include:

- stable event ID
- date or time as stated
- normalized date only in a separate derived field
- participants
- location
- event type
- source or sources
- supporting claims
- supporting Layer 0 passages
- confidence or certainty appropriate to the evidence

The event object must never claim more certainty than its sources justify.

## 5. Claim Registry

Claims must be modeled separately from events.

This is one of the most important rules in the system.

A source saying something does not automatically make that statement a canonical historical fact.

Examples:

- Strang says Elsie urged him to murder Whipple.
- Elsie denies involvement.
- a witness reports a conversation.
- a newspaper repeats an accusation.
- a later historian offers a retrospective judgment.

Each claim should record:

- claim ID
- claimant or source
- subject
- predicate
- object or proposition
- date of claim
- source
- Layer 0 provenance
- related event
- whether firsthand, reported, inferred, retrospective, or editorial
- contradiction links
- corroboration links

This allows contradictory accounts to coexist without forcing false reconciliation.

## 6. Evidence Registry

Physical and documentary evidence should receive its own identity.

Likely evidence objects include:

- rifle
- bullet
- $20 Phoenix Bank bill
- arsenic
- socks
- letters
- glass
- tracks
- coat
- bullet mould
- written notes
- pamphlets
- jail papers
- museum objects

Each evidence object should include:

- evidence ID
- object label
- object type
- descriptions as stated by sources
- first known appearance
- custody or possession events
- discovery or recovery events
- witness identifications
- courtroom use
- later archival or museum reference
- Layer 0 provenance

Where possible, model an evidence chain rather than collapsing all references into one summary.

The rifle is a strong test case because the manuscript contains material about:

- purchase
- payment
- concealment
- recovery
- identification
- trial presentation
- later museum reference

## 7. Knowledge States

Build a time-sensitive knowledge model.

For a given date or moment, distinguish:

- what had happened
- what investigators knew
- what a particular witness knew
- what newspapers had published
- what the public had been told
- what a defendant had admitted
- what remained unknown
- what appears only in later retrospective material

This prevents later information from leaking backward into earlier chronology.

For example, an interface showing May 8 should not reveal Jesse Strang's identity merely because the completed book later establishes that Joseph Orton was Jesse Strang.

Time therefore becomes a permissions system.

## 8. Trial Model

Model the Strang and Whipple trials explicitly.

Trial data should include:

- trial ID
- defendant
- charge
- court
- judges
- counsel
- jury
- dates
- witnesses in order
- testimony
- exhibits or evidence
- objections
- legal arguments
- rulings
- admitted evidence
- excluded evidence
- verdict
- sentence
- trial-specific knowledge state

Courtroom knowledge must remain distinct from general historical knowledge.

The system should eventually be able to answer:

> What information was legally before the jury when it reached its decision?

This is especially important for Elsie Whipple's trial and the exclusion of Strang as a witness.

---

# Provenance and Completeness Audit

Before presentation features are built, audit all derived data.

## Forward provenance test

Every Layer 2 object should point back to Layer 0.

No person, event, claim, evidence object, trial fact, or relationship should exist without source provenance.

## Reverse completeness test

Inspect substantive Layer 0 passages that produced no derived object.

Determine whether omission was intentional.

This catches passages that may have been overlooked during extraction.

## Additional audits

Check for:

- duplicate entities
- unresolved aliases
- contradictory dates
- overlapping events
- duplicate events
- source attribution ambiguity
- unattributed claims
- unsupported conclusions
- evidence objects without custody provenance
- claims without source provenance
- events based only on later retrospective material
- later knowledge leaking into earlier chronology

Only after this audit should Layer 2 be considered canonical enough for application use.

---

# Layer 3: Views

Layer 3 presents Layers 0-2 without changing them.

Possible views include:

- Chronology
- Case
- People
- Albany
- Archive
- evidence board
- people graph
- location map
- trial reconstruction
- source comparison
- source lens
- what-was-known-on-this-date mode
- conventional narrative view
- documentary reading view

All views should be generated from canonical data rather than maintained as separate hand-written databases.

---

# Layer 4: Interpretation

Layer 4 is optional and explicitly interpretive.

Possible functions include:

- historiographical comparison
- competing narratives
- pattern analysis
- unresolved questions
- source reliability analysis
- narrative construction
- historical argument
- editorial commentary

Layer 4 must always know that it is interpreting canonical data.

It must never overwrite Layers 0-3.

---

# Architecture Summary

## Layer 0: Book

Immutable canonical transcription.

## Layer 1: Structure

Structural Index + Source Registry.

Answers:

> Where is it, and what kind of manuscript object is it?

## Layer 2: Chronicle

Entities + Events + Claims + Evidence + Knowledge States + Trials.

Answers:

> What is being described, who says it, what happened, and what was known when?

## Layer 3: Views

Chronology, case file, people graph, maps, archive, trial mode, source lens, and other interfaces.

Answers:

> How should the canonical data be explored?

## Layer 4: Interpretation

Historiography, analysis, conclusions, and narrative argument.

Answers:

> What might the evidence mean?

---

# Immediate Next Step

Begin Layer 1.

The first Layer 1 deliverable should contain:

1. a Structural Index of the complete manuscript
2. a Source Registry derived from that index
3. stable IDs
4. exact Layer 0 line provenance
5. no historical interpretation
6. validation proving that every Layer 1 reference resolves to canonical Layer 0

Layer 1 should be completed and audited before Entity, Event, Claim, Evidence, or Trial extraction begins.
