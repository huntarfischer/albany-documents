import SwiftUI
import JJWWReaderCore
import JJWWMaterials

public struct ScrollReaderGateSheet: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore

    public init(edition: Edition, materialStore: MaterialProfileStore) {
        self.edition = edition
        self.materialStore = materialStore
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JJWW · STAGE 4")
                        .font(.system(size: 34, weight: .black, design: .serif))
                    Text("THE SCROLL READER · five-section contact sheet")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .tracking(1.2)
                        .opacity(0.58)
                }
                Spacer()
                HStack(spacing: 8) {
                    Text("SCROLL")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(red: 0.94, green: 0.29, blue: 0.06), in: Capsule())
                    Text("PAGES")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .opacity(0.35)
                }
            }
            .foregroundStyle(.white)

            let units = edition.orderedReadingUnits
            VStack(spacing: 18) {
                gateRow(Array(units.prefix(2)))
                gateRow(Array(units.dropFirst(2).prefix(2)))
                gateRow(Array(units.dropFirst(4).prefix(2)))
            }

            HStack {
                Text("FULL MATERIAL · STANDARD TYPE")
                Spacer()
                Text("same Edition / ReadingUnit model · no source-specific reader views")
            }
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.52))
        }
        .padding(28)
        .frame(width: 1900, height: 1760, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
    }

    @ViewBuilder
    private func gateRow(_ units: [ReadingUnit]) -> some View {
        HStack(spacing: 18) {
            ForEach(units) { unit in
                gateCard(unit)
            }
            if units.count == 1 {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func gateCard(_ unit: ReadingUnit) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(unit.sequence) · \(unit.id)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                    Text("lines \(unit.canonicalAnchor.startLine)–\(unit.canonicalAnchor.endLine)")
                        .font(.system(size: 10, design: .monospaced))
                        .opacity(0.52)
                }
                Spacer()
                Text(unit.materialProfile.id)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.56)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(.black.opacity(0.50))

            ReadingUnitSurface(
                unit: unit,
                materialStore: materialStore,
                materialSetting: .full,
                textScale: .standard,
                entryContext: .jumpIntoSection,
                lineLimit: previewLineCount(for: unit),
                animateOpening: false
            )
            .frame(maxWidth: .infinity, minHeight: 430, maxHeight: 430, alignment: .top)
            .clipped()
        }
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.18))
        .overlay(
            Rectangle().stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private func previewLineCount(for unit: ReadingUnit) -> Int {
        switch unit.kind {
        case .cover: return 5
        case .section:
            switch unit.sourcePresentation?.sourceKind {
            case .periodical: return 12
            case .confessionPamphlet: return 11
            case .trialPamphlet: return 13
            case .literaryArtifact: return 16
            case nil: return 10
            }
        }
    }
}
