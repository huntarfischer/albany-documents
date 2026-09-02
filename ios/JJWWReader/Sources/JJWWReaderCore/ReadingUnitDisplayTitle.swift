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

private let navigationTitleSemanticPriorities: [String: Int] = [
    "uppercase_display_line": 0,
    "front_matter_title_block": 1,
    "section_item": 1,
    "confession_document": 1,
    "trial_source_section": 1,
    "historical_work_section": 1,
    "official_examination_document": 1,
    "newspaper_item": 1,
    "periodical_item": 1,
    "broadside_document": 1,
    "poem_document": 1,
    "letter_document": 1,
    "advertisement_document": 1,
    "will_document": 1,
    "genealogical_section": 1,
    "legal_notice_document": 1,
    "testimony_document": 1,
    "farewell_document": 1,
    "appendix_section": 1,
    "appendix_people_index": 1,
    "appendix_timeline": 1,
    "bibliography_section": 1,
    "acknowledgments_section": 1,
    "copyright_section": 1,
    "back_matter_title": 1,
    "request_document": 1,
    "registration_document": 1,
    "museum_card": 1
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
