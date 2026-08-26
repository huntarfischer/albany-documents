#!/usr/bin/env python3

"""Materialize Canonical Layer 0 v1.1 from the repository's v1.0 JSON.

This script reproduces the already-sealed v1.1 artifact exactly. It makes one
user-authorized compiler correction at canonical line 119 and rebuilds the
v1.1 metadata/validation envelope. It does not infer or normalize history.
"""

from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "jesse-james-and-the-widow-whipple-canonical.json"
V10_ARCHIVE = ROOT / "jesse-james-and-the-widow-whipple-canonical-v1.0.json"
V11 = ROOT / "jesse-james-and-the-widow-whipple-canonical-v1.1.json"
LATEST = SOURCE

OLD_TEXT = "Monday June 16, 1827"
NEW_TEXT = "Monday June 18, 1827"
OLD_SHA = "735edd6b4b60fdf1d019ac9baa0644ed21ce71bdf48018ef42634e38eef9fba7"
NEW_SHA = "106274914ba9c0cc1afd4418d6e8a8dbfa62a5f2d04c9089d87aa0a406147a8e"


def reconstruct(chunks: list[dict]) -> list[str]:
    lines: list[str] = []
    for chunk in chunks:
        for block in chunk["blocks"]:
            block_type = block["type"]
            if block_type == "dated_entry":
                lines.append(block["date_text"])
                lines.extend(block["lines"])
            elif block_type == "section":
                lines.append(block["heading"])
                lines.extend(block["lines"])
            else:
                lines.extend(block["lines"])
    return lines


def line_sha(lines: list[str]) -> str:
    return hashlib.sha256("\n".join(lines).encode("utf-8")).hexdigest()


def main() -> None:
    source = json.loads(SOURCE.read_text(encoding="utf-8"))
    if source.get("format_version") != "1.0-canonical-layer-0":
        raise SystemExit(
            "Refusing reseal: expected repository source to be canonical v1.0."
        )

    prior_lines = reconstruct(source["chunks"])
    if len(prior_lines) != 2069 or line_sha(prior_lines) != OLD_SHA:
        raise SystemExit("Refusing reseal: canonical v1.0 line sequence does not match sealed input.")
    if prior_lines[118] != OLD_TEXT:
        raise SystemExit("Refusing reseal: canonical line 119 is not the expected v1.0 heading.")

    chunks = copy.deepcopy(source["chunks"])
    matches: list[tuple[int, int]] = []
    for chunk_index, chunk in enumerate(chunks):
        for block_index, block in enumerate(chunk["blocks"]):
            if block.get("type") == "dated_entry" and block.get("date_text") == OLD_TEXT:
                matches.append((chunk_index, block_index))

    if matches != [(1, 0)]:
        raise SystemExit(f"Refusing reseal: expected one exact heading target, found {matches!r}.")

    chunk_index, block_index = matches[0]
    chunks[chunk_index]["blocks"][block_index]["date_text"] = NEW_TEXT

    current_lines = reconstruct(chunks)
    if len(current_lines) != 2069:
        raise SystemExit("Refusing reseal: line count changed.")
    if current_lines[118] != NEW_TEXT:
        raise SystemExit("Refusing reseal: line 119 correction failed.")
    if line_sha(current_lines) != NEW_SHA:
        raise SystemExit("Refusing reseal: v1.1 line sequence SHA does not match sealed canonical.")

    artifact = {
        "format_version": "1.1-canonical-layer-0",
        "title": source["title"],
        "source_file": source["source_file"],
        "source_extraction": {
            "basis": "canonical Layer 0 v1.0 plus one explicit user-authorized compiler correction",
            "original_extraction_tool": "pandoc",
            "original_target": "plain",
            "original_wrap": "none",
            "updated_source_file_reingested_in_this_step": False,
            "note": "The user reports that the manuscript heading has been corrected to Monday June 18, 1827. This reseal applies that exact one-line correction to canonical v1.0. No fresh extraction of the user's locally edited RTF was available in this step.",
        },
        "principle": "Immutable Layer 0 canonical capture after an explicit compiler correction. Version 1.1 differs from v1.0 only at line 119: 'Monday June 16, 1827' was corrected to 'Monday June 18, 1827'. No historical interpretation, normalization, or other textual alteration has been added.",
        "chunks": chunks,
        "validation": {
            "canonical_version": "1.1",
            "canonical_line_count": 2069,
            "prior_line_count": 2069,
            "changed_line_count": 1,
            "inserted_line_count": 0,
            "deleted_line_count": 0,
            "line_number_map_identity": True,
            "changed_lines": [
                {
                    "line": 119,
                    "old": OLD_TEXT,
                    "new": NEW_TEXT,
                }
            ],
            "prior_line_sequence_sha256": OLD_SHA,
            "line_sequence_sha256": NEW_SHA,
            "calendar_check": {
                "date": "1827-06-18",
                "weekday_as_written": "Monday",
                "actual_weekday": "Monday",
                "match": True,
            },
            "reseal_basis": "user-authorized compiler correction",
            "updated_source_file_reingested": False,
            "status": "PASS",
        },
        "canonical_version": "1.1",
        "supersedes": {
            "canonical_version": "1.0",
            "line_sequence_sha256": OLD_SHA,
            "artifact_name": "jesse-james-and-the-widow-whipple-canonical-layer-0-v1.0",
        },
    }

    rendered = json.dumps(artifact, ensure_ascii=False, indent=2) + "\n"

    # Preserve the prior canonical instead of silently destroying it.
    if not V10_ARCHIVE.exists():
        V10_ARCHIVE.write_text(
            json.dumps(source, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    V11.write_text(rendered, encoding="utf-8")
    LATEST.write_text(rendered, encoding="utf-8")

    print(f"Wrote {V11.name}")
    print(f"Updated latest alias {LATEST.name}")
    print(f"Archived prior canonical as {V10_ARCHIVE.name}")
    print(f"Layer 0 v1.1 SHA: {NEW_SHA}")


if __name__ == "__main__":
    main()
