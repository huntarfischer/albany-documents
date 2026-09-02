import Foundation

public extension ReadingUnit {
    /// Human-readable identity for reader navigation and Workshop selection.
    ///
    /// Explicit grouped source titles remain authoritative. Ordinary ReadingUnits
    /// prefer their authored structural header, then direct source attribution,
    /// then date/opening text. Debug IDs remain the last-resort fallback only.
    var displayTitle: String {
        if let sourceTitle = navigationLabel(sourcePresentation?.displayTitle) {
            return sourceTitle
        }

        let structuralCandidates = blocks
            .flatMap(\.semanticSpans)
            .filter { navigationTitleSemanticPriorities[$0.type] != nil }
            .sorted { lhs, rhs in
                let lhsPriority = navigationTitleSemanticPriorities[lhs.type] ?? Int.max
                let rhsPriority = navigationTitleSemanticPriorities[rhs.type] ?? Int.max
                if lhsPriority != rhsPriority {
                    return lhsPriority < rhsPriority
                }
                if lhs.canonicalAnchor.startLine == rhs.canonicalAnchor.startLine {
                    return lhs.canonicalAnchor.endLine < rhs.canonicalAnchor.endLine
                }
                return lhs.canonicalAnchor.startLine < rhs.canonicalAnchor.startLine
            }

        if let structuralTitle = structuralCandidates.lazy
            .compactMap({ navigationLabel($0.labelAsWritten) })
            .first {
            return structuralTitle
        }

        let directSourceTitles = blocks
            .flatMap(\.sourceOccurrences)
            .filter { $0.role == "direct_attribution" }
            .sorted { lhs, rhs in
                lhs.attributionAnchor.startLine < rhs.attributionAnchor.startLine
            }

        if let directSourceTitle = directSourceTitles.lazy
            .compactMap({ navigationLabel($0.source.titleAsWritten) })
            .first {
            return directSourceTitle
        }

        let datedCandidates = blocks
            .flatMap(\.semanticSpans)
            .filter { $0.type == "dated_item" }
            .sorted { lhs, rhs in
                lhs.canonicalAnchor.startLine < rhs.canonicalAnchor.startLine
            }

        if let dateTitle = datedCandidates.lazy
            .compactMap({ navigationLabel($0.labelAsWritten) })
            .first {
            return dateTitle
        }

        if let opening = blocks.first?.lines.first,
           let canonicalLabel = navigationLabel(opening.text) {
            return canonicalLabel
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

/// Typed documentary titles are stronger identity than a generic typographic
/// display line. A display line is still stronger than a date, which is handled
/// only after structural and direct-source identity have been exhausted.
private let navigationTitleSemanticPriorities: [String: Int] = [
    "front_matter_title_block": 0,
    "section_item": 0,
    "confession_document": 0,
    "trial_source_section": 0,
    "historical_work_section": 0,
    "official_examination_document": 0,
    "newspaper_item": 0,
    "periodical_item": 0,
    "broadside_document": 0,
    "poem_document": 0,
    "letter_document": 0,
    "advertisement_document": 0,
    "will_document": 0,
    "genealogical_section": 0,
    "legal_notice_document": 0,
    "testimony_document": 0,
    "farewell_document": 0,
    "appendix_section": 0,
    "appendix_people_index": 0,
    "appendix_timeline": 0,
    "bibliography_section": 0,
    "acknowledgments_section": 0,
    "copyright_section": 0,
    "back_matter_title": 0,
    "request_document": 0,
    "registration_document": 0,
    "museum_card": 0,
    "uppercase_display_line": 1
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
