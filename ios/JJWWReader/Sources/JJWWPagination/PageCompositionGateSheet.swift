import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography
import JJWWScrollReader

public struct PageCompositionGateSheet: View {
    public let edition: Edition
    public let result: PaginationResult
    public let materialStore: MaterialProfileStore

    public init(
        edition: Edition,
        result: PaginationResult,
        materialStore: MaterialProfileStore
    ) {
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
        let materialIDs = [
            MaterialProfile.argus1827.id,
            MaterialProfile.confessionPamphlet1827.id,
            MaterialProfile.trialRecord1827.id,
            MaterialProfile.farewell1827.id
        ]
        return materialIDs.compactMap { materialID in
            edition.orderedReadingUnits.first(
                where: { $0.materialProfile.id == materialID }
            )?.id
        }
    }

    private var openingPages: [PageSlice] {
        reviewUnitIDs.compactMap {
            result.pages(representing: $0).first
        }
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

                    ComposedPageLeafView(
                        page: page,
                        edition: edition,
                        materialStore: materialStore
                    )
                    .frame(width: 390, height: 844)
                    .clipped()
                    .overlay(
                        Rectangle().stroke(
                            .white.opacity(0.18),
                            lineWidth: 1
                        )
                    )
                }
            }
        }
    }

    private func label(for page: PageSlice) -> String {
        guard let id = page.readingUnitIDs.first,
              let unit = edition.readingUnit(id: id) else {
            return page.id
        }
        return unit.sourcePresentation?.displayTitle ?? unit.id
    }
}

public struct ComposedPageLeafView: View {
    public let page: PageSlice
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    public let materialState: MaterialState

    private let engine = MaterialEngine()

    public init(
        page: PageSlice,
        edition: Edition,
        materialStore: MaterialProfileStore,
        materialState: MaterialState = .full
    ) {
        self.page = page
        self.edition = edition
        self.materialStore = materialStore
        self.materialState = materialState
    }

    public var body: some View {
        if let materialProfile = materialStore.profile(
            id: page.materialProfile.id
        ),
           let composition = PageCompositionCatalog.profile(
            id: page.compositionProfileID
           ) {
            let seed = MaterialSeed.derive(
                base: 1827,
                salt: "page.\(page.pageIndex).\(page.layoutSegmentID)"
            )
            let recipe = engine.resolve(
                profile: materialProfile,
                state: materialState,
                seed: seed
            )

            MaterialSurfaceView(recipe: recipe) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(page.fragments) { fragment in
                        fragmentView(
                            fragment,
                            composition: composition,
                            seed: seed
                        )
                        if shouldDrawRule(
                            after: fragment,
                            composition: composition
                        ) {
                            pageRule(composition)
                        }
                    }
                }
                .padding(.top, CGFloat(page.resolvedMargins.top))
                .padding(.bottom, CGFloat(page.resolvedMargins.bottom))
                .padding(.leading, CGFloat(page.resolvedMargins.leading))
                .padding(.trailing, CGFloat(page.resolvedMargins.trailing))
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .foregroundStyle(Color.black.opacity(0.84))
            }
            .overlay(alignment: .top) {
                if page.compositionKind == .continuation {
                    runningHeader(composition)
                        .padding(.top, 16)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Text("\(page.pageNumber)")
                    .font(
                        .system(
                            size: 10,
                            weight: .medium,
                            design: .serif
                        )
                    )
                    .foregroundStyle(Color.black.opacity(0.42))
                    .padding(.trailing, 18)
                    .padding(.bottom, 14)
            }
        } else {
            Color(red: 0.88, green: 0.84, blue: 0.72)
        }
    }

    @ViewBuilder
    private func fragmentView(
        _ fragment: PageTextFragment,
        composition: PageCompositionProfile,
        seed: UInt64
    ) -> some View {
        if fragment.text.isEmpty {
            if fragment.trailingSeparator != .none {
                Color.clear.frame(height: 8)
            }
        } else if let unit = edition.readingUnit(
            id: fragment.readingUnitID
        ),
                  let resolved = PageTypographyResolver.resolve(
                    text: fragment.text,
                    canonicalLine: fragment.canonicalLine,
                    role: fragment.role,
                    unit: unit,
                    textScale: page.textScale,
                    isOpeningHeader: fragment.isOpeningHeader,
                    isFirstOpeningHeader: fragment.isFirstOpeningHeader,
                    isLastOpeningHeader: fragment.isLastOpeningHeader
                  ) {
            if unit.id == FarewellArtifactLayout.unitID {
                farewellFragment(
                    fragment,
                    resolved: resolved,
                    composition: composition,
                    seed: seed
                )
            } else {
                ResolvedPrintWearText(
                    fragment.text,
                    resolved: resolved,
                    profile: composition.printWear,
                    seed: seed ^ UInt64(fragment.canonicalLine),
                    snapshotLayoutWidth: resolved.token.justified
                        ? page.contentWidth
                        : nil
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: resolved.token.centered
                        ? .center
                        : .leading
                )
                .padding(
                    .top,
                    CGFloat(resolved.paragraphSpacingBefore)
                )
                .padding(
                    .bottom,
                    CGFloat(resolved.paragraphSpacingAfter)
                )
            }
        } else {
            Text(fragment.text).font(.body)
        }
    }

    @ViewBuilder
    private func farewellFragment(
        _ fragment: PageTextFragment,
        resolved: ResolvedReaderTypography,
        composition: PageCompositionProfile,
        seed: UInt64
    ) -> some View {
        let line = fragment.canonicalLine

        if FarewellArtifactLayout.headerRange.contains(line) {
            ResolvedPrintWearText(
                fragment.text,
                resolved: resolved,
                profile: composition.printWear,
                seed: seed ^ UInt64(line)
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(
                .top,
                CGFloat(resolved.paragraphSpacingBefore)
            )
            .padding(
                .bottom,
                CGFloat(resolved.paragraphSpacingAfter)
            )
        } else if let side = FarewellArtifactLayout.columnSide(
            for: line
        ) {
            let ornamentWidth = 24.0
            let contentWidth = max(
                1,
                page.contentWidth - ornamentWidth
            )

            HStack(alignment: .top, spacing: 10) {
                if side == .leading {
                    FarewellColumnOrnament(
                        side: side,
                        seed: seed ^ UInt64(line)
                    )
                    .frame(minHeight: 24)
                }

                ResolvedPrintWearText(
                    fragment.text,
                    resolved: resolved,
                    profile: composition.printWear,
                    seed: seed ^ UInt64(line),
                    snapshotLayoutWidth: contentWidth
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                if side == .trailing {
                    FarewellColumnOrnament(
                        side: side,
                        seed: seed ^ UInt64(line)
                    )
                    .frame(minHeight: 24)
                }
            }
            .padding(
                .top,
                CGFloat(resolved.paragraphSpacingBefore)
            )
            .padding(
                .bottom,
                CGFloat(resolved.paragraphSpacingAfter)
            )
        } else {
            ResolvedPrintWearText(
                fragment.text,
                resolved: resolved,
                profile: composition.printWear,
                seed: seed ^ UInt64(line)
            )
            .padding(
                .top,
                CGFloat(resolved.paragraphSpacingBefore)
            )
            .padding(
                .bottom,
                CGFloat(resolved.paragraphSpacingAfter)
            )
        }
    }

    private func shouldDrawRule(
        after fragment: PageTextFragment,
        composition: PageCompositionProfile
    ) -> Bool {
        fragment.isLastOpeningHeader &&
        composition.ruleThickness > 0
    }

    private func pageRule(
        _ composition: PageCompositionProfile
    ) -> some View {
        let scale = PageTypographyResolver.pointScale(
            for: page.textScale
        )
        return HStack {
            Spacer(minLength: 0)
            Rectangle()
                .fill(Color.black.opacity(0.55))
                .frame(
                    width: max(
                        24,
                        page.contentWidth
                            * composition.ruleLengthFraction
                    ),
                    height: max(
                        0.5,
                        composition.ruleThickness
                    ) * scale
                )
            Spacer(minLength: 0)
        }
        .padding(
            .top,
            CGFloat(composition.ruleGap * scale)
        )
        .padding(
            .bottom,
            CGFloat(
                composition.headerBottomSpace * 0.45 * scale
            )
        )
    }

    private func runningHeader(
        _ composition: PageCompositionProfile
    ) -> some View {
        let title: String = {
            guard let id = page.readingUnitIDs.first,
                  let unit = edition.readingUnit(id: id) else {
                return ""
            }
            return unit.sourcePresentation?.displayTitle ?? ""
        }()
        return Text(title.uppercased())
            .font(
                .system(
                    size: composition.runningHeaderPointSize,
                    weight: .semibold,
                    design: .serif
                )
            )
            .tracking(0.8)
            .foregroundStyle(Color.black.opacity(0.44))
            .lineLimit(1)
    }
}
