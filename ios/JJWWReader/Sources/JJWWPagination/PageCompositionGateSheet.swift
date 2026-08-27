import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography

public struct PageCompositionGateSheet: View {
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
                    Text("JJWW · STAGE 5.5")
                        .font(.system(size: 32, weight: .black, design: .serif))
                    Text("PAGE COMPOSITION · opening ceremony vs. continuation reading")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.1)
                        .opacity(0.58)
                }
                Spacer()
                Text("4 OPENINGS / 4 CONTINUATIONS")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.54)
            }
            .foregroundStyle(.white)

            Text("OPENING LEAVES")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.52))
            phoneRow(openingPages)

            Text("CONTINUATION LEAVES")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.52))
            phoneRow(continuationPages)

            HStack {
                Text("HEADER SCALE · NEGATIVE SPACE · RULES · PRINT WEAR")
                Spacer()
                Text("provisional values remain tunable in Page Composition Lab")
            }
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.50))
        }
        .padding(28)
        .frame(width: 1726, height: 1866, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
    }

    private var reviewUnitIDs: [String] {
        [
            "may-8-9-albany-argus",
            "confession-of-jesse-james-strang",
            "trial-of-jesse-james-strang",
            "farewell-address"
        ]
    }

    private var openingPages: [PageSlice] {
        reviewUnitIDs.compactMap { result.pages(representing: $0).first }
    }

    private var continuationPages: [PageSlice] {
        reviewUnitIDs.compactMap { id in
            let pages = result.pages(representing: id)
            guard pages.count > 1 else { return pages.first }
            return pages[min(1, pages.count - 1)]
        }
    }

    @ViewBuilder
    private func phoneRow(_ pages: [PageSlice]) -> some View {
        HStack(alignment: .top, spacing: 18) {
            ForEach(pages) { page in
                VStack(spacing: 7) {
                    HStack {
                        Text(label(for: page)).lineLimit(1)
                        Spacer()
                        Text("P\(page.pageNumber) · \(page.compositionKind.rawValue.uppercased())")
                    }
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.62))
                    .frame(width: 390)

                    ComposedPageLeafView(page: page, edition: edition, materialStore: materialStore)
                        .frame(width: 390, height: 844)
                        .clipped()
                        .overlay(Rectangle().stroke(.white.opacity(0.18), lineWidth: 1))
                }
            }
        }
    }

    private func label(for page: PageSlice) -> String {
        guard let id = page.readingUnitIDs.first,
              let unit = edition.readingUnit(id: id) else { return page.id }
        return unit.sourcePresentation?.displayTitle ?? unit.id
    }
}

public struct ComposedPageLeafView: View {
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
        if let materialProfile = materialStore.profile(id: page.materialProfile.id),
           let composition = PageCompositionCatalog.profile(id: page.compositionProfileID) {
            let seed = MaterialSeed.derive(base: 1827, salt: "page.\(page.pageIndex).\(page.layoutSegmentID)")
            let recipe = engine.resolve(profile: materialProfile, state: .full, seed: seed)

            MaterialSurfaceView(recipe: recipe) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(page.fragments) { fragment in
                        fragmentView(fragment, composition: composition, seed: seed.rawValue)
                        if shouldDrawRule(after: fragment, composition: composition) {
                            pageRule(composition)
                        }
                    }
                }
                .padding(.top, CGFloat(page.resolvedMargins.top))
                .padding(.bottom, CGFloat(page.resolvedMargins.bottom))
                .padding(.leading, CGFloat(page.resolvedMargins.leading))
                .padding(.trailing, CGFloat(page.resolvedMargins.trailing))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .foregroundStyle(Color.black.opacity(0.84))
            }
            .overlay(alignment: .top) {
                if page.compositionKind == .continuation {
                    runningHeader(composition).padding(.top, 16)
                }
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

    @ViewBuilder
    private func fragmentView(_ fragment: PageTextFragment, composition: PageCompositionProfile, seed: UInt64) -> some View {
        if fragment.text.isEmpty {
            if fragment.trailingSeparator != .none { Color.clear.frame(height: 8) }
        } else if let unit = edition.readingUnit(id: fragment.readingUnitID),
                  let typography = TypographyCatalog.profile(id: unit.typographyProfile.id) {
            let token = typography.token(fragment.role)
            let openingHeader = page.beginsSectionTransition && isHeader(fragment.role)
            PrintWearText(
                fragment.text,
                token: token,
                profile: composition.printWear,
                seed: seed ^ UInt64(fragment.canonicalLine),
                pointScale: openingHeader ? composition.headerScale : 1,
                trackingDelta: openingHeader ? composition.headerTrackingDelta : 0,
                lineSpacingMultiplier: openingHeader ? composition.headerLineSpacingMultiplier : composition.bodyLeadingMultiplier
            )
            .frame(maxWidth: .infinity, alignment: token.centered ? .center : .leading)
            .padding(.top, openingHeader && isFirstOpeningHeader(fragment) ? CGFloat(composition.headerTopSpace) : 0)
            .padding(.bottom, separatorSpacing(for: fragment.role, composition: composition))
        } else {
            Text(fragment.text).font(.body)
        }
    }

    private func isHeader(_ role: TypographyRole) -> Bool {
        role == .dateHeading || role == .sourceHeader || role == .sectionTitle
    }

    private func isFirstOpeningHeader(_ fragment: PageTextFragment) -> Bool {
        page.fragments.first(where: { isHeader($0.role) && !$0.text.isEmpty })?.id == fragment.id
    }

    private func shouldDrawRule(after fragment: PageTextFragment, composition: PageCompositionProfile) -> Bool {
        guard page.beginsSectionTransition, composition.ruleThickness > 0 else { return false }
        return page.fragments.filter { isHeader($0.role) && !$0.text.isEmpty }.last?.id == fragment.id
    }

    private func pageRule(_ composition: PageCompositionProfile) -> some View {
        HStack {
            Spacer(minLength: 0)
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .frame(width: max(24, (390 - composition.openingMargins.leading - composition.openingMargins.trailing) * composition.ruleLengthFraction), height: max(0.5, composition.ruleThickness))
            Spacer(minLength: 0)
        }
        .padding(.top, CGFloat(composition.ruleGap))
        .padding(.bottom, CGFloat(composition.headerBottomSpace * 0.45))
    }

    private func separatorSpacing(for role: TypographyRole, composition: PageCompositionProfile) -> CGFloat {
        switch role {
        case .dateHeading, .sourceHeader: return 7
        case .sectionTitle: return composition.ruleThickness > 0 ? 2 : CGFloat(composition.headerBottomSpace)
        case .verse: return 3
        case .body, .firstPersonBody: return CGFloat(composition.paragraphGap)
        default: return 2
        }
    }

    private func runningHeader(_ composition: PageCompositionProfile) -> some View {
        let title: String = {
            guard let id = page.readingUnitIDs.first,
                  let unit = edition.readingUnit(id: id) else { return "" }
            return unit.sourcePresentation?.displayTitle ?? ""
        }()
        return Text(title.uppercased())
            .font(.system(size: composition.runningHeaderPointSize, weight: .semibold, design: .serif))
            .tracking(0.8)
            .foregroundStyle(Color.black.opacity(0.44))
            .lineLimit(1)
    }
}
