import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography

public struct PaginationGateSheet: View {
    public let edition: Edition
    public let result: PaginationResult
    public let materialStore: MaterialProfileStore

    public init(edition: Edition, result: PaginationResult, materialStore: MaterialProfileStore) {
        self.edition = edition
        self.result = result
        self.materialStore = materialStore
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JJWW · STAGE 5")
                        .font(.system(size: 32, weight: .black, design: .serif))
                    Text("PAGINATION ENGINE · source transitions as portrait iPhone leaves")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.1)
                        .opacity(0.58)
                }
                Spacer()
                Text("390 × 844 · STANDARD TYPE")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.54)
            }
            .foregroundStyle(.white)

            let samples = transitionSamples
            VStack(spacing: 22) {
                phoneRow(Array(samples.prefix(4)))
                phoneRow(Array(samples.dropFirst(4).prefix(4)))
            }

            HStack {
                Text("STATIC LEAVES · NO PAGE CURL YET")
                Spacer()
                Text("each pair = final leaf of source A → first leaf of source B")
            }
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.50))
        }
        .padding(28)
        .frame(width: 1726, height: 1866, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
    }

    private var contentUnits: [ReadingUnit] {
        edition.orderedReadingUnits.filter { $0.kind != .cover }
    }

    private var transitionSamples: [PageSlice] {
        let units = contentUnits
        guard units.count >= 2 else { return Array(result.pages.prefix(8)) }
        var samples: [PageSlice] = []
        for index in 0..<(units.count - 1) {
            let left = result.pages(representing: units[index].id).last
            let right = result.pages(representing: units[index + 1].id).first
            if let left { samples.append(left) }
            if let right { samples.append(right) }
        }
        return Array(samples.prefix(8))
    }

    @ViewBuilder
    private func phoneRow(_ pages: [PageSlice]) -> some View {
        HStack(alignment: .top, spacing: 18) {
            ForEach(pages) { page in
                VStack(spacing: 7) {
                    HStack {
                        Text(label(for: page))
                            .lineLimit(1)
                        Spacer()
                        Text("P\(page.pageNumber) · \(page.side.rawValue.uppercased())")
                    }
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(width: 390)

                    PageLeafView(
                        page: page,
                        edition: edition,
                        materialStore: materialStore
                    )
                    .frame(width: 390, height: 844)
                    .clipped()
                    .overlay(Rectangle().stroke(.white.opacity(0.18), lineWidth: 1))
                }
            }
            if pages.count < 4 {
                ForEach(0..<(4 - pages.count), id: \.self) { _ in
                    Color.clear.frame(width: 390, height: 870)
                }
            }
        }
    }

    private func label(for page: PageSlice) -> String {
        let ids = page.readingUnitIDs
        if ids.count == 1, let unit = edition.readingUnit(id: ids[0]) {
            return unit.sourcePresentation?.displayTitle ?? unit.id
        }
        return ids.joined(separator: " + ")
    }
}

public struct PageLeafView: View {
    public let page: PageSlice
    public let edition: Edition
    public let materialStore: MaterialProfileStore

    private let engine = MaterialEngine()

    public init(page: PageSlice, edition: Edition, materialStore: MaterialProfileStore) {
        self.page = page
        self.edition = edition
        self.materialStore = materialStore
    }

    public var body: some View {
        if let profile = materialStore.profile(id: page.materialProfile.id) {
            let seed = MaterialSeed.derive(base: 1827, salt: "page.\(page.pageIndex).\(page.layoutSegmentID)")
            let recipe = engine.resolve(profile: profile, state: .full, seed: seed)

            MaterialSurfaceView(recipe: recipe) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(page.fragments) { fragment in
                        fragmentView(fragment)
                    }
                }
                .padding(.top, CGFloat(pageMargins.top))
                .padding(.bottom, CGFloat(pageMargins.bottom))
                .padding(.leading, CGFloat(pageMargins.leading))
                .padding(.trailing, CGFloat(pageMargins.trailing))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .foregroundStyle(Color.black.opacity(0.82))
            }
            .overlay(alignment: .bottomTrailing) {
                Text("\(page.pageNumber)")
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundStyle(Color.black.opacity(0.42))
                    .padding(.trailing, 18)
                    .padding(.bottom, 14)
            }
        } else {
            Color(red: 0.88, green: 0.84, blue: 0.72)
        }
    }

    private var pageMargins: PageMargins {
        .phonePortrait
    }

    @ViewBuilder
    private func fragmentView(_ fragment: PageTextFragment) -> some View {
        if fragment.text.isEmpty {
            if fragment.trailingSeparator != .none {
                Color.clear.frame(height: 8)
            }
        } else if let unit = edition.readingUnit(id: fragment.readingUnitID),
                  let profile = TypographyCatalog.profile(id: unit.typographyProfile.id) {
            let token = profile.token(fragment.role)
            TypographicText(fragment.text, token: token)
                .frame(maxWidth: .infinity, alignment: token.centered ? .center : .leading)
                .padding(.bottom, fragment.trailingSeparator == .none ? 0 : separatorSpacing(for: fragment.role))
        } else {
            Text(fragment.text)
                .font(.body)
        }
    }

    private func separatorSpacing(for role: TypographyRole) -> CGFloat {
        switch role {
        case .dateHeading, .sourceHeader: return 4
        case .sectionTitle: return 7
        case .verse: return 2
        default: return 1
        }
    }
}
