import SwiftUI
import JJWWReaderCore
import JJWWMaterials

public struct ScrollReaderGateSheet: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore

    private let phoneWidth: CGFloat = 390
    private let phoneHeight: CGFloat = 844

    public init(edition: Edition, materialStore: MaterialProfileStore) {
        self.edition = edition
        self.materialStore = materialStore
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JJWW · STAGE 4")
                        .font(.system(size: 34, weight: .black, design: .serif))
                    Text("THE SCROLL READER · portrait iPhone review gate")
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
            VStack(alignment: .leading, spacing: 28) {
                phoneRow(Array(units.prefix(4)))
                phoneRow(Array(units.dropFirst(4).prefix(4)))
            }

            HStack {
                Text("FULL MATERIAL · STANDARD TYPE · 390 × 844 PT VIEWPORT")
                Spacer()
                Text("same Edition / ReadingUnit model · no source-specific reader views")
            }
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.52))
        }
        .padding(32)
        .frame(width: 1760, height: 1960, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
    }

    @ViewBuilder
    private func phoneRow(_ units: [ReadingUnit]) -> some View {
        HStack(alignment: .top, spacing: 28) {
            ForEach(units) { unit in
                phonePreview(unit)
            }
            if units.count < 4 {
                ForEach(0..<(4 - units.count), id: \.self) { _ in
                    Color.clear
                        .frame(width: phoneWidth)
                }
            }
        }
    }

    private func phonePreview(_ unit: ReadingUnit) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .fill(Color.black)

                ReadingUnitSurface(
                    unit: unit,
                    materialStore: materialStore,
                    materialSetting: .full,
                    textScale: .standard,
                    entryContext: .jumpIntoSection,
                    lineLimit: previewLineCount(for: unit),
                    animateOpening: false
                )
                .frame(width: phoneWidth - 16, height: phoneHeight - 16, alignment: .top)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                .padding(8)
            }
            .frame(width: phoneWidth, height: phoneHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text("\(unit.sequence) · \(unit.id)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                Text("\(unit.materialProfile.id) · lines \(unit.canonicalAnchor.startLine)–\(unit.canonicalAnchor.endLine)")
                    .font(.system(size: 9, design: .monospaced))
                    .opacity(0.52)
            }
            .foregroundStyle(.white)
            .frame(width: phoneWidth, alignment: .leading)
        }
    }

    private func previewLineCount(for unit: ReadingUnit) -> Int {
        switch unit.kind {
        case .cover: return 10
        case .section:
            switch unit.sourcePresentation?.sourceKind {
            case .periodical: return 24
            case .confessionPamphlet: return 24
            case .trialPamphlet: return 28
            case .literaryArtifact: return 32
            case nil: return 22
            }
        }
    }
}
