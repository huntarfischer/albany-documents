import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader
import JJWWPagination
import JJWWPagesReader

/// Stage 7.5a reviews only production renderers. The two Scroll phones are crops
/// of the live periodical stack, not hand-built mockups; the Farewell phones are
/// real paginated leaves from the Pages reader.
public struct Stage75GateSheet: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    public let pagination: PaginationResult

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        pagination: PaginationResult
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.pagination = pagination
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JJWW · STAGE 7.5A")
                        .font(.system(size: 32, weight: .black, design: .serif))
                    Text("CLOTH TABLE · OVERLAPPING PAPERS · FAREWELL BROADSIDE")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.0)
                        .opacity(0.58)
                }
                Spacer()
                Text("390 × 844 · PRODUCTION RENDERERS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.54)
            }
            .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 18) {
                phone(label: "ARGUS · MAY 8 → MAY 9") {
                    articleCrop(offset: -430)
                }

                phone(label: "ARGUS · ARTICLE → FUNERAL") {
                    articleCrop(offset: -1900)
                }

                phone(label: "FAREWELL · OPENING") {
                    farewellOpening
                }

                phone(label: "FAREWELL · HISTORICAL COLUMN II") {
                    farewellSecondColumn
                }
            }

            HStack {
                Text("CLOTH IS THE TABLE · SPACE IS PUNCTUATION · PAPERS REMAIN DISTINCT OBJECTS")
                Spacer()
                Text("Farewell columns are serialized for phone reading; ornament remains subordinate to text")
            }
            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.50))

            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(width: 1726, height: 1010, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
    }

    @ViewBuilder
    private func phone<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(label)
                Spacer()
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.62))
            .frame(width: 390)

            ZStack(alignment: .top) {
                content()
                Stage75StaticChrome(title: chromeTitle(for: label))
            }
            .frame(width: 390, height: 844, alignment: .top)
            .clipped()
            .overlay(Rectangle().stroke(.white.opacity(0.18), lineWidth: 1))
        }
    }

    @ViewBuilder
    private func articleCrop(offset: CGFloat) -> some View {
        if let argus = edition.readingUnit(id: "argus-may-8-9-1827") {
            ZStack(alignment: .top) {
                JJWWCoverClothTexture(seed: 0x4A4A5757)
                PeriodicalStackReadingUnitSurface(
                    unit: argus,
                    materialStore: materialStore,
                    materialSetting: .full,
                    textScale: .standard,
                    entryContext: .jumpIntoSection,
                    animateOpening: false,
                    snapshotLayoutWidth: 320
                )
                .offset(y: offset + 54)
            }
        } else {
            Color.red.opacity(0.2)
        }
    }

    @ViewBuilder
    private var farewellOpening: some View {
        if let page = pagination.pages(representing: FarewellArtifactLayout.unitID).first {
            PagesLeafView(page: page, edition: edition, materialStore: materialStore)
        } else {
            Color.red.opacity(0.2)
        }
    }

    @ViewBuilder
    private var farewellSecondColumn: some View {
        if let page = pagination.pages.first(where: { page in
            page.fragments.contains(where: { $0.canonicalLine == FarewellArtifactLayout.secondColumnStart })
        }) {
            PagesLeafView(page: page, edition: edition, materialStore: materialStore)
        } else if let page = pagination.pages(representing: FarewellArtifactLayout.unitID).last {
            PagesLeafView(page: page, edition: edition, materialStore: materialStore)
        } else {
            Color.red.opacity(0.2)
        }
    }

    private func chromeTitle(for label: String) -> String {
        label.hasPrefix("FAREWELL") ? "Farewell Address" : "The Albany Argus & City Gazette"
    }
}

private struct Stage75StaticChrome: View {
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("JJWW")
                    .font(.system(size: 10, weight: .black, design: .serif))
                Rectangle()
                    .fill(JJWWEditorialPalette.orange)
                    .frame(width: 2, height: 18)
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .lineLimit(1)
                    .foregroundStyle(JJWWEditorialPalette.cream.opacity(0.80))
                Spacer()
                Text("Aa")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(JJWWEditorialPalette.cream)
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(JJWWEditorialPalette.ink.opacity(0.97))

            HStack(spacing: 0) {
                Rectangle().fill(JJWWEditorialPalette.orange).frame(width: 116, height: 3)
                Rectangle().fill(JJWWEditorialPalette.cream.opacity(0.16)).frame(height: 3)
            }
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
    }
}
