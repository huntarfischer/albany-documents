import SwiftUI
import JJWWReaderCore
import JJWWMaterials

public struct ScrollReaderRibbonSheet: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore

    public init(edition: Edition, materialStore: MaterialProfileStore) {
        self.edition = edition
        self.materialStore = materialStore
    }

    public var body: some View {
        VStack(spacing: 0) {
            ribbonChrome

            VStack(spacing: -12) {
                ForEach(edition.orderedReadingUnits) { unit in
                    ReadingUnitSurface(
                        unit: unit,
                        materialStore: materialStore,
                        materialSetting: .full,
                        textScale: .standard,
                        entryContext: .jumpIntoSection,
                        lineLimit: previewLineCount(for: unit),
                        animateOpening: false
                    )
                    .frame(height: previewHeight(for: unit), alignment: .top)
                    .clipped()
                }
            }
        }
        .frame(width: 900, height: 3170, alignment: .top)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
        .clipped()
    }

    private var ribbonChrome: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(red: 0.94, green: 0.29, blue: 0.06))
                .frame(height: 3)
            HStack(spacing: 14) {
                Text("JJWW")
                    .font(.system(size: 16, weight: .black, design: .serif))
                Text("0%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .opacity(0.56)
                Spacer()
                Text("Aa")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                Text("FULL")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                Text("SCROLL")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.94, green: 0.29, blue: 0.06), in: Capsule())
                Text("PAGES")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .opacity(0.32)
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .foregroundStyle(.white)
            .background(.black.opacity(0.88))
        }
    }

    private func previewLineCount(for unit: ReadingUnit) -> Int {
        if unit.kind == .cover { return 5 }
        switch unit.sourcePresentation?.sourceKind {
        case .periodical: return 10
        case .confessionPamphlet: return 12
        case .trialPamphlet: return 13
        case .literaryArtifact: return 17
        case nil: return 10
        }
    }

    private func previewHeight(for unit: ReadingUnit) -> CGFloat {
        if unit.kind == .cover { return 430 }
        switch unit.sourcePresentation?.sourceKind {
        case .periodical: return 455
        case .confessionPamphlet: return 505
        case .trialPamphlet: return 555
        case .literaryArtifact: return 610
        case nil: return 450
        }
    }
}
