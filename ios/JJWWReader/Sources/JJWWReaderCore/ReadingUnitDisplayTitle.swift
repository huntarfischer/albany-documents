import Foundation

public extension ReadingUnit {
    /// Human-readable identity for reader navigation and Workshop selection.
    ///
    /// Source-authored titles remain authoritative for grouped documentary works.
    /// Ordinary ReadingUnits use their canonical opening heading/date. When the
    /// canonical opening is an image placeholder, fall through to the existing
    /// Layer 1 structural label rather than surfacing a filename or debug ID.
    var displayTitle: String {
        if let sourceTitle = navigationLabel(sourcePresentation?.displayTitle) {
            return sourceTitle
        }

        if let opening = blocks.first?.lines.first,
           let canonicalLabel = navigationLabel(opening.text) {
            return canonicalLabel
        }

        let structuralCandidates = blocks
            .flatMap(\.semanticSpans)
            .filter { navigationSemanticTypes.contains($0.type) }
            .sorted { lhs, rhs in
                if lhs.canonicalAnchor.startLine == rhs.canonicalAnchor.startLine {
                    return lhs.canonicalAnchor.endLine < rhs.canonicalAnchor.endLine
                }
                return lhs.canonicalAnchor.startLine < rhs.canonicalAnchor.startLine
            }

        if let semanticLabel = structuralCandidates.lazy
            .compactMap({ navigationLabel($0.labelAsWritten) })
            .first {
            return semanticLabel
        }

        if let firstCanonicalLabel = blocks.lazy
            .flatMap({ $0.lines })
            .compactMap({ navigationLabel($0.text) })
            .first {
            return firstCanonicalLabel
        }

        return id
    }
}

private let navigationSemanticTypes: Set<String> = [
    "front_matter_title_block",
    "dated_item",
    "section_item",
    "confession_document",
    "trial_source_section",
    "historical_work_section",
    "official_examination_document",
    "newspaper_item",
    "periodical_item",
    "broadside_document",
    "poem_document",
    "letter_document",
    "advertisement_document",
    "will_document",
    "genealogical_section",
    "legal_notice_document",
    "testimony_document",
    "farewell_document",
    "appendix_section",
    "appendix_people_index",
    "appendix_timeline",
    "bibliography_section",
    "acknowledgments_section",
    "copyright_section",
    "back_matter_title",
    "request_document",
    "registration_document",
    "museum_card",
    "uppercase_display_line"
]

private func navigationLabel(_ raw: String?) -> String? {
    guard let raw else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    let lowered = trimmed.lowercased()
    guard !lowered.hasPrefix("[ image:") && !lowered.hasPrefix("[image:") else {
        return nil
    }

    return trimmed
}
