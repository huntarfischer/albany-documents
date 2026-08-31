import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography

public struct ScrollReaderView: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore

    @StateObject private var session: ScrollReaderSession
    private let pagesEnabled: Bool
    private let onRequestPages: (() -> Void)?
    private let showsChrome: Bool

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        persistence: ReaderLocationPersistence = UserDefaultsReaderLocationPersistence(),
        pagesEnabled: Bool = false,
        onRequestPages: (() -> Void)? = nil,
        showsChrome: Bool = true
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.pagesEnabled = pagesEnabled
        self.onRequestPages = onRequestPages
        self.showsChrome = showsChrome
        _session = StateObject(
            wrappedValue: ScrollReaderSession(
                edition: edition,
                persistence: persistence
            )
        )
    }

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        session: ScrollReaderSession,
        pagesEnabled: Bool = false,
        onRequestPages: (() -> Void)? = nil,
        showsChrome: Bool = true
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.pagesEnabled = pagesEnabled
        self.onRequestPages = onRequestPages
        self.showsChrome = showsChrome
        _session = StateObject(wrappedValue: session)
    }

    public var body: some View {
        let units = edition.orderedReadingUnits
        ScrollViewReader { proxy in
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(units.enumerated()), id: \.element.id) { index, unit in
                            ReadingUnitSurface(
                                unit: unit,
                                materialStore: materialStore,
                                materialSetting: session.materialSetting,
                                textScale: session.textScale,
                                entryContext: unit.id == session.location.readingUnitID ? .jumpIntoSection : .naturalSectionEntry
                            )
                            .id(unit.id)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: ReaderUnitOffsetPreferenceKey.self,
                                        value: [
                                            unit.id: geometry.frame(in: .named("JJWW_SCROLL_READER")).minY
                                        ]
                                    )
                                }
                            )
                            .zIndex(2)

                            if index + 1 < units.count,
                               let interval = EditorialIntervalCatalog.sourceBoundary(
                                   from: unit,
                                   to: units[index + 1]
                               ) {
                                EditorialIntervalView(
                                    profile: interval,
                                    seed: MaterialSeed.derive(
                                        base: 1827,
                                        salt: "source.interval.\(unit.id).\(units[index + 1].id)"
                                    )
                                )
                                .padding(.top, -CGFloat(interval.overlapDepth))
                                .padding(.bottom, -CGFloat(interval.overlapDepth * 0.48))
                                .zIndex(1)
                            }
                        }
                    }
                    .padding(.bottom, 90)
                }
                .coordinateSpace(name: "JJWW_SCROLL_READER")
                .background(Color(red: 0.08, green: 0.072, blue: 0.058))
                .dynamicTypeSize(session.textScale.dynamicTypeSize)
                .textSelection(.enabled)
                .onPreferenceChange(ReaderUnitOffsetPreferenceKey.self) { offsets in
                    updateVisibleUnit(from: offsets)
                }
                .onChange(of: session.navigationRevision) { _, _ in
                    scrollToSessionLocation(with: proxy, animated: true)
                }
                .onAppear {
                    DispatchQueue.main.async {
                        scrollToSessionLocation(with: proxy, animated: false)
                    }
                }

                if showsChrome {
                    ReaderChrome(
                        session: session,
                        pagesEnabled: pagesEnabled,
                        onRequestPages: onRequestPages
                    )
                }
            }
        }
    }

    private func scrollToSessionLocation(with proxy: ScrollViewProxy, animated: Bool) {
        let lineID = "\(session.location.blockID).line.\(session.location.canonicalLine)"
        if animated {
            withAnimation(.easeOut(duration: 0.22)) {
                proxy.scrollTo(lineID, anchor: .top)
            }
        } else {
            proxy.scrollTo(lineID, anchor: .top)
        }
    }

    private func updateVisibleUnit(from offsets: [String: CGFloat]) {
        guard let nearest = offsets.min(by: {
            abs($0.value - 72) < abs($1.value - 72)
        }),
        let unit = edition.readingUnit(id: nearest.key) else {
            return
        }
        session.focus(unit: unit)
    }
}

public struct ReadingUnitSurface: View {
    public let unit: ReadingUnit
    public let materialStore: MaterialProfileStore
    public let materialSetting: ReaderMaterialSetting
    public let textScale: ReaderTextScale
    public let entryContext: InkAwakeningEntryContext
    public let lineLimit: Int?
    public let animateOpening: Bool
    public let snapshotLayoutWidth: Double?

    private let engine = MaterialEngine()

    public init(
        unit: ReadingUnit,
        materialStore: MaterialProfileStore,
        materialSetting: ReaderMaterialSetting,
        textScale: ReaderTextScale,
        entryContext: InkAwakeningEntryContext = .naturalSectionEntry,
        lineLimit: Int? = nil,
        animateOpening: Bool = true,
        snapshotLayoutWidth: Double? = nil
    ) {
        self.unit = unit
        self.materialStore = materialStore
        self.materialSetting = materialSetting
        self.textScale = textScale
        self.entryContext = entryContext
        self.lineLimit = lineLimit
        self.animateOpening = animateOpening
        self.snapshotLayoutWidth = snapshotLayoutWidth
    }

    @ViewBuilder
    public var body: some View {
        if lineLimit == nil,
           unit.sourcePresentation?.sourceKind == .periodical,
           unit.blocks.count > 1 {
            PeriodicalStackReadingUnitSurface(
                unit: unit,
                materialStore: materialStore,
                materialSetting: materialSetting,
                textScale: textScale,
                entryContext: entryContext,
                animateOpening: animateOpening,
                snapshotLayoutWidth: snapshotLayoutWidth
            )
        } else if lineLimit == nil,
                  unit.id == FarewellArtifactLayout.unitID {
            FarewellReadingUnitSurface(
                unit: unit,
                materialStore: materialStore,
                materialSetting: materialSetting,
                textScale: textScale,
                entryContext: entryContext,
                animateOpening: animateOpening,
                snapshotLayoutWidth: snapshotLayoutWidth
            )
        } else if let materialProfile = materialStore.profile(id: unit.materialProfile.id),
                  let typographyProfile = TypographyCatalog.profile(id: unit.typographyProfile.id) {
            let seed = MaterialSeed.derive(base: 1827, salt: "scroll.\(unit.id)")
            let recipe = engine.resolve(
                profile: materialProfile,
                state: materialSetting.materialState,
                seed: seed
            )
            let composition = unit.kind == .cover ? nil : ReaderCompositionCatalog.profile(for: unit)

            MaterialSurfaceView(recipe: recipe) {
                VStack(alignment: contentAlignment(for: typographyProfile), spacing: 0) {
                    ForEach(visiblePresentations) { presentation in
                        VStack(spacing: 0) {
                            lineView(
                                presentation,
                                typographyProfile: typographyProfile,
                                composition: composition,
                                seed: seed
                            )
                            if let composition,
                               shouldDrawRule(after: presentation, composition: composition) {
                                compositionRule(composition)
                            }
                        }
                        .id(presentation.id)
                    }
                }
                .frame(maxWidth: readingMeasure(for: unit), alignment: unit.kind == .cover ? .center : .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.leading, leadingPadding(composition: composition))
                .padding(.trailing, trailingPadding(composition: composition))
                .padding(.top, topPadding(composition: composition))
                .padding(.bottom, bottomPadding(composition: composition))
                .foregroundStyle(inkColor(recipe: recipe))
            }
            .frame(minHeight: unit.kind == .cover ? 430 : nil)
            .overlay(alignment: .bottom) {
                PaperSeam(seed: seed)
                    .offset(y: 8)
            }
            .dynamicTypeSize(textScale.dynamicTypeSize)
            .accessibilityElement(children: .contain)
        } else {
            Text("Reader profile missing for \(unit.id)")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.14))
        }
    }

    private var visiblePresentations: [ReaderLinePresentation] {
        let all = unit.blocks.flatMap { ReaderLineRoleResolver.presentations(for: $0, in: unit) }
        if let lineLimit {
            return Array(all.prefix(max(0, lineLimit)))
        }
        return all
    }

    private var openingPresentationIDs: [String] {
        visiblePresentations
            .filter(\.usesInkAwakening)
            .map(\.id)
    }

    @ViewBuilder
    private func lineView(
        _ presentation: ReaderLinePresentation,
        typographyProfile: TypographyProfileDefinition,
        composition: ReaderCompositionProfile?,
        seed: UInt64
    ) -> some View {
        let text = presentation.canonicalLine.text
        if text.isEmpty {
            Color.clear
                .frame(height: blankLineHeight(for: presentation.role))
                .accessibilityHidden(true)
        } else {
            let token = typographyProfile.token(presentation.role)
            let lineSeed = MaterialSeed.derive(
                base: seed,
                salt: "line.\(presentation.canonicalLine.number)"
            )
            let openingHeader = presentation.usesInkAwakening && isHeader(presentation.role)
            let headerScale = openingHeader ? (composition?.headerScale ?? 1) : 1
            let trackingDelta = openingHeader ? (composition?.headerTrackingDelta ?? 0) : 0
            let lineSpacingMultiplier = openingHeader
                ? (composition?.headerLineSpacingMultiplier ?? 1)
                : (composition?.bodyLeadingMultiplier ?? 1)

            Group {
                if animateOpening,
                   presentation.usesInkAwakening,
                   let inkProfile = ReaderInkProfileResolver.profile(for: unit),
                   let composition {
                    InkAwakeningText(
                        text,
                        token: token,
                        profile: inkProfile,
                        seed: lineSeed,
                        entryContext: entryContext,
                        explicitlyInstant: lineLimit != nil,
                        printWearProfile: composition.printWear,
                        pointScale: pointScale * headerScale,
                        trackingDelta: trackingDelta,
                        lineSpacingMultiplier: lineSpacingMultiplier,
                        snapshotLayoutWidth: snapshotLayoutWidth
                    )
                } else if let composition {
                    PrintWearText(
                        text,
                        token: token,
                        profile: composition.printWear,
                        seed: lineSeed,
                        pointScale: pointScale * headerScale,
                        trackingDelta: trackingDelta,
                        lineSpacingMultiplier: lineSpacingMultiplier,
                        snapshotLayoutWidth: snapshotLayoutWidth
                    )
                } else {
                    TypographicText(text, token: token)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: token.centered ? .center : .leading
            )
            .padding(.top, topSpacing(for: presentation, composition: composition))
            .padding(.bottom, bottomSpacing(for: presentation, composition: composition))
        }
    }

    private var pointScale: Double {
        switch textScale {
        case .standard: return 1.0
        case .large: return 1.18
        case .accessibility: return 1.55
        }
    }

    private func isHeader(_ role: TypographyRole) -> Bool {
        role == .dateHeading || role == .sourceHeader || role == .sectionTitle
    }

    private func isFirstOpeningHeader(_ presentation: ReaderLinePresentation) -> Bool {
        openingPresentationIDs.first == presentation.id
    }

    private func isLastOpeningHeader(_ presentation: ReaderLinePresentation) -> Bool {
        openingPresentationIDs.last == presentation.id
    }

    private func shouldDrawRule(
        after presentation: ReaderLinePresentation,
        composition: ReaderCompositionProfile
    ) -> Bool {
        composition.ruleThickness > 0 && isLastOpeningHeader(presentation)
    }

    private func compositionRule(_ composition: ReaderCompositionProfile) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Rectangle()
                    .fill(Color.black.opacity(0.55))
                    .frame(
                        width: max(24, geometry.size.width * composition.ruleLengthFraction),
                        height: max(0.5, composition.ruleThickness)
                    )
                Spacer(minLength: 0)
            }
        }
        .frame(height: max(1, composition.ruleThickness))
        .padding(.top, CGFloat(composition.ruleGap))
        .padding(.bottom, CGFloat(composition.headerBottomSpace * 0.45))
        .accessibilityHidden(true)
    }

    private func contentAlignment(for profile: TypographyProfileDefinition) -> HorizontalAlignment {
        unit.kind == .cover ? .center : .leading
    }

    private func readingMeasure(for unit: ReadingUnit) -> CGFloat {
        switch unit.sourcePresentation?.sourceKind {
        case .periodical: return 690
        case .confessionPamphlet: return 650
        case .trialPamphlet: return 720
        case .literaryArtifact: return 610
        case nil: return 660
        }
    }

    private func leadingPadding(composition: ReaderCompositionProfile?) -> CGFloat {
        if unit.kind == .cover { return 38 }
        return CGFloat(composition?.openingInsets.leading ?? 32)
    }

    private func trailingPadding(composition: ReaderCompositionProfile?) -> CGFloat {
        if unit.kind == .cover { return 38 }
        return CGFloat(composition?.openingInsets.trailing ?? 32)
    }

    private func topPadding(composition: ReaderCompositionProfile?) -> CGFloat {
        if unit.kind == .cover { return 72 }
        return CGFloat(composition?.openingInsets.top ?? 54)
    }

    private func bottomPadding(composition: ReaderCompositionProfile?) -> CGFloat {
        if unit.kind == .cover { return 64 }
        return CGFloat(composition?.openingInsets.bottom ?? 64)
    }

    private func blankLineHeight(for role: TypographyRole) -> CGFloat {
        role == .verse ? 10 : 8
    }

    private func topSpacing(
        for presentation: ReaderLinePresentation,
        composition: ReaderCompositionProfile?
    ) -> CGFloat {
        if let composition,
           presentation.usesInkAwakening,
           isFirstOpeningHeader(presentation) {
            return CGFloat(composition.headerTopSpace)
        }

        switch presentation.role {
        case .dateHeading: return 8
        case .sourceHeader: return 6
        case .sectionTitle: return 7
        case .witnessLabel, .courtLabel: return 15
        case .counselLabel: return 9
        case .verse: return 2
        default: return 0
        }
    }

    private func bottomSpacing(
        for presentation: ReaderLinePresentation,
        composition: ReaderCompositionProfile?
    ) -> CGFloat {
        if let composition,
           presentation.usesInkAwakening,
           isLastOpeningHeader(presentation) {
            return composition.ruleThickness > 0 ? 0 : CGFloat(composition.headerBottomSpace)
        }

        switch presentation.role {
        case .dateHeading: return 5
        case .sourceHeader: return 8
        case .sectionTitle: return 10
        case .witnessLabel, .courtLabel: return 5
        case .counselLabel: return 4
        case .verse: return 3
        case .body, .firstPersonBody:
            return CGFloat(composition?.paragraphGap ?? 7)
        default: return 4
        }
    }

    private func inkColor(recipe: MaterialResolvedRecipe) -> Color {
        if unit.kind == .cover {
            return Color(red: 0.99, green: 0.93, blue: 0.79).opacity(max(0.72, recipe.ink.density))
        }
        return Color.black.opacity(max(0.58, recipe.ink.density))
    }
}

private struct ReaderChrome: View {
    @ObservedObject var session: ScrollReaderSession
    let pagesEnabled: Bool
    let onRequestPages: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(value: session.progress)
                .progressViewStyle(.linear)
                .tint(Color(red: 0.94, green: 0.29, blue: 0.06))
                .scaleEffect(x: 1, y: 0.55, anchor: .center)

            HStack(spacing: 14) {
                Text("\(Int((session.progress * 100).rounded()))%")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.72))

                Spacer()

                Menu {
                    ForEach(ReaderTextScale.allCases, id: \.self) { scale in
                        Button(scale.rawValue.capitalized) {
                            session.changingTextScale(to: scale)
                        }
                    }
                } label: {
                    Text("Aa")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                }

                Menu {
                    ForEach(ReaderMaterialSetting.allCases, id: \.self) { setting in
                        Button(setting.rawValue.capitalized) {
                            session.changingMaterial(to: setting)
                        }
                    }
                } label: {
                    Label(session.materialSetting.rawValue.capitalized, systemImage: "circle.lefthalf.filled")
                        .labelStyle(.titleOnly)
                        .font(.system(size: 12, weight: .semibold))
                }

                HStack(spacing: 4) {
                    Text("SCROLL")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Color(red: 0.94, green: 0.29, blue: 0.06),
                            in: Capsule()
                        )
                    Button("PAGES") {
                        if let onRequestPages {
                            onRequestPages()
                        } else {
                            session.requestPagesMode()
                        }
                    }
                    .disabled(!pagesEnabled)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .opacity(pagesEnabled ? 1 : 0.36)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.black.opacity(0.78))
            .foregroundStyle(.white)
        }
    }
}

private struct PaperSeam: View {
    let seed: UInt64

    var body: some View {
        Canvas { context, size in
            var state = seed
            func unit() -> Double {
                state &+= 0x9E3779B97F4A7C15
                var z = state
                z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
                z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
                let value = z ^ (z >> 31)
                return Double(value >> 11) / Double(1 << 53)
            }

            var path = Path()
            let segments = max(12, Int(size.width / 32))
            for index in 0...segments {
                let x = size.width * CGFloat(index) / CGFloat(segments)
                let jitter = CGFloat((unit() - 0.5) * 7)
                let y = size.height / 2 + jitter
                if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(path, with: .color(.black.opacity(0.18)), lineWidth: 1)
        }
        .frame(height: 18)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ReaderUnitOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}