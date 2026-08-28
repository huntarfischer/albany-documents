import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography

/// A periodical ReadingUnit is allowed to contain several distinct articles.
/// Stage 7.5 gives each block its own sheet so Scroll reads as an authored stack
/// of archival objects rather than a continuous web feed.
public struct PeriodicalStackReadingUnitSurface: View {
    public let unit: ReadingUnit
    public let materialStore: MaterialProfileStore
    public let materialSetting: ReaderMaterialSetting
    public let textScale: ReaderTextScale
    public let entryContext: InkAwakeningEntryContext
    public let animateOpening: Bool
    public let snapshotLayoutWidth: Double?
    public let blockRange: Range<Int>?

    public init(
        unit: ReadingUnit,
        materialStore: MaterialProfileStore,
        materialSetting: ReaderMaterialSetting,
        textScale: ReaderTextScale,
        entryContext: InkAwakeningEntryContext = .naturalSectionEntry,
        animateOpening: Bool = true,
        snapshotLayoutWidth: Double? = nil,
        blockRange: Range<Int>? = nil
    ) {
        self.unit = unit
        self.materialStore = materialStore
        self.materialSetting = materialSetting
        self.textScale = textScale
        self.entryContext = entryContext
        self.animateOpening = animateOpening
        self.snapshotLayoutWidth = snapshotLayoutWidth
        self.blockRange = blockRange
    }

    public var body: some View {
        if let material = materialStore.profile(id: unit.materialProfile.id),
           let typography = TypographyCatalog.profile(id: unit.typographyProfile.id) {
            let composition = ReaderCompositionCatalog.profile(for: unit)
            let staging = PeriodicalStagingCatalog.profile(for: unit)
            let selected = selectedBlocks

            VStack(spacing: 0) {
                ForEach(Array(selected.enumerated()), id: \.element.id) { localIndex, block in
                    let absoluteIndex = absoluteBlockIndex(block)
                    PeriodicalPaperBlockSurface(
                        unit: unit,
                        block: block,
                        blockIndex: absoluteIndex,
                        material: material,
                        typography: typography,
                        composition: composition,
                        staging: staging,
                        materialSetting: materialSetting,
                        textScale: textScale,
                        entryContext: entryContext,
                        animateOpening: animateOpening,
                        snapshotLayoutWidth: snapshotLayoutWidth
                    )
                    .zIndex(2)

                    if localIndex < selected.count - 1,
                       let interval = EditorialIntervalCatalog.articleBoundary(
                           in: unit,
                           boundaryIndex: absoluteIndex
                       ) {
                        EditorialIntervalView(
                            profile: interval,
                            seed: MaterialSeed.derive(
                                base: 1827,
                                salt: "article.interval.\(unit.id).\(absoluteIndex)"
                            )
                        )
                        .frame(height: CGFloat(max(1, interval.height * staging.intervalHeightScale)))
                        .padding(.top, -CGFloat(interval.overlapDepth * staging.intervalHeightScale))
                        .padding(.bottom, -CGFloat(interval.overlapDepth * 0.58 * staging.intervalHeightScale))
                        .zIndex(1)
                    }
                }
            }
            .padding(.vertical, CGFloat(staging.stackVerticalPadding))
            .background(JJWWCoverClothTexture(seed: 0x4A4A5757))
            .dynamicTypeSize(textScale.dynamicTypeSize)
            .accessibilityElement(children: .contain)
        } else {
            Text("Reader profile missing for \(unit.id)")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.14))
        }
    }

    private var selectedBlocks: [DocumentBlock] {
        guard let blockRange else { return unit.blocks }
        return blockRange.compactMap { index in
            unit.blocks.indices.contains(index) ? unit.blocks[index] : nil
        }
    }

    private func absoluteBlockIndex(_ block: DocumentBlock) -> Int {
        unit.blocks.firstIndex(where: { $0.id == block.id }) ?? 0
    }
}

private struct PeriodicalPaperBlockSurface: View {
    let unit: ReadingUnit
    let block: DocumentBlock
    let blockIndex: Int
    let material: MaterialProfileDefinition
    let typography: TypographyProfileDefinition
    let composition: ReaderCompositionProfile
    let staging: PeriodicalStagingProfile
    let materialSetting: ReaderMaterialSetting
    let textScale: ReaderTextScale
    let entryContext: InkAwakeningEntryContext
    let animateOpening: Bool
    let snapshotLayoutWidth: Double?

    private let engine = MaterialEngine()

    var body: some View {
        let seed = MaterialSeed.derive(base: 1827, salt: "article.sheet.\(unit.id).\(block.id)")
        let recipe = engine.resolve(
            profile: material,
            state: materialSetting.materialState,
            seed: seed
        )
        let presentations = ReaderLineRoleResolver.presentations(for: block, in: unit)
        let openingIDs = presentations.filter(\.usesInkAwakening).map(\.id)

        MaterialSurfaceView(recipe: recipe) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(presentations) { presentation in
                    VStack(spacing: 0) {
                        blockLine(
                            presentation,
                            openingIDs: openingIDs,
                            seed: seed
                        )
                        .id(presentation.id)

                        if composition.ruleThickness > 0,
                           openingIDs.last == presentation.id {
                            articleRule
                        }
                    }
                }
            }
            .frame(maxWidth: 690, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.leading, CGFloat(composition.openingInsets.leading))
            .padding(.trailing, CGFloat(composition.openingInsets.trailing))
            .padding(.top, blockIndex == 0 ? CGFloat(composition.openingInsets.top) : 54)
            .padding(.bottom, 50)
            .foregroundStyle(Color.black.opacity(max(0.60, recipe.ink.density)))
        }
        .clipShape(DeckledPaperShape(seed: seed, scale: staging.deckleScale))
        .background {
            PeriodicalBackingPaperStack(
                seed: seed,
                blockIndex: blockIndex,
                layerCount: backingLayerCount,
                staging: staging
            )
        }
        .overlay(
            DeckledPaperShape(seed: seed, scale: staging.deckleScale)
                .stroke(Color(red: 0.20, green: 0.16, blue: 0.10).opacity(0.22), lineWidth: 0.85)
        )
        .shadow(
            color: .black.opacity(staging.contactShadowOpacity),
            radius: CGFloat(staging.contactShadowRadius),
            y: CGFloat(staging.contactShadowY)
        )
        .shadow(
            color: .black.opacity(staging.ambientShadowOpacity),
            radius: CGFloat(staging.ambientShadowRadius),
            y: CGFloat(staging.ambientShadowY)
        )
        .padding(.horizontal, sheetHorizontalInset)
        .offset(x: sheetDrift)
        .rotationEffect(.degrees(sheetRotation))
    }

    @ViewBuilder
    private func blockLine(
        _ presentation: ReaderLinePresentation,
        openingIDs: [String],
        seed: UInt64
    ) -> some View {
        let text = presentation.canonicalLine.text
        if text.isEmpty {
            Color.clear.frame(height: 8).accessibilityHidden(true)
        } else {
            let token = typography.token(presentation.role)
            let openingHeader = presentation.usesInkAwakening && isHeader(presentation.role)
            let lineSeed = MaterialSeed.derive(
                base: seed,
                salt: "line.\(presentation.canonicalLine.number)"
            )
            let scale = pointScale * (openingHeader ? composition.headerScale : 1)
            let tracking = openingHeader ? composition.headerTrackingDelta : 0
            let leading = openingHeader
                ? composition.headerLineSpacingMultiplier
                : composition.bodyLeadingMultiplier

            Group {
                if animateOpening,
                   presentation.usesInkAwakening,
                   let ink = ReaderInkProfileResolver.profile(for: unit) {
                    InkAwakeningText(
                        text,
                        token: token,
                        profile: ink,
                        seed: lineSeed,
                        entryContext: entryContext,
                        explicitlyInstant: snapshotLayoutWidth != nil,
                        printWearProfile: composition.printWear,
                        pointScale: scale,
                        trackingDelta: tracking,
                        lineSpacingMultiplier: leading,
                        snapshotLayoutWidth: token.justified ? snapshotLayoutWidth : nil
                    )
                } else {
                    PrintWearText(
                        text,
                        token: token,
                        profile: composition.printWear,
                        seed: lineSeed,
                        pointScale: scale,
                        trackingDelta: tracking,
                        lineSpacingMultiplier: leading,
                        snapshotLayoutWidth: token.justified ? snapshotLayoutWidth : nil
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: token.centered ? .center : .leading)
            .padding(.top, topSpacing(presentation, openingIDs: openingIDs))
            .padding(.bottom, bottomSpacing(presentation, openingIDs: openingIDs))
        }
    }

    private var articleRule: some View {
        HStack {
            Spacer(minLength: 0)
            Rectangle()
                .fill(Color.black.opacity(0.53))
                .frame(
                    width: max(34, 306 * composition.ruleLengthFraction),
                    height: max(0.5, composition.ruleThickness)
                )
            Spacer(minLength: 0)
        }
        .padding(.top, CGFloat(composition.ruleGap))
        .padding(.bottom, CGFloat(composition.headerBottomSpace * 0.48))
        .accessibilityHidden(true)
    }

    private func isHeader(_ role: TypographyRole) -> Bool {
        role == .dateHeading || role == .sourceHeader || role == .sectionTitle
    }

    private func topSpacing(_ presentation: ReaderLinePresentation, openingIDs: [String]) -> CGFloat {
        if openingIDs.first == presentation.id {
            return CGFloat(composition.headerTopSpace)
        }
        switch presentation.role {
        case .dateHeading: return 8
        case .sourceHeader: return 6
        case .sectionTitle: return 7
        default: return 0
        }
    }

    private func bottomSpacing(_ presentation: ReaderLinePresentation, openingIDs: [String]) -> CGFloat {
        if openingIDs.last == presentation.id {
            return composition.ruleThickness > 0 ? 0 : CGFloat(composition.headerBottomSpace)
        }
        switch presentation.role {
        case .dateHeading: return 5
        case .sourceHeader: return 8
        case .sectionTitle: return 10
        case .body, .firstPersonBody: return CGFloat(composition.paragraphGap)
        default: return 3
        }
    }

    private var pointScale: Double {
        switch textScale {
        case .standard: return 1
        case .large: return 1.18
        case .accessibility: return 1.55
        }
    }

    private var backingLayerCount: Int {
        let values = [1, 2, 1, 2]
        return min(values[blockIndex % values.count], max(0, staging.backingLayerLimit))
    }

    private var sheetHorizontalInset: CGFloat {
        let values: [CGFloat] = [6, 15, 10, 18]
        return values[blockIndex % values.count] * CGFloat(staging.sheetInsetScale)
    }

    private var sheetDrift: CGFloat {
        let values: [CGFloat] = [-4, 6, -5, 4]
        return values[blockIndex % values.count] * CGFloat(staging.sheetDriftScale)
    }

    private var sheetRotation: Double {
        let values = [-0.13, 0.17, -0.09, 0.11]
        return values[blockIndex % values.count] * staging.sheetRotationScale
    }
}

private struct PeriodicalBackingPaperStack: View {
    let seed: UInt64
    let blockIndex: Int
    let layerCount: Int
    let staging: PeriodicalStagingProfile

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array((0..<layerCount).reversed()), id: \.self) { layer in
                    backingLayer(layer, size: geometry.size)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func backingLayer(_ layer: Int, size: CGSize) -> some View {
        let layerSeed = seed ^ UInt64(0x75A0 + blockIndex * 31 + layer * 17)
        let width = max(0, size.width - CGFloat(layer * 3 + 2))
        let height = max(0, size.height - CGFloat(layer * 2 + 1))
        let rotation = backingRotation(layer) * staging.backingDriftScale
        let x = backingX(layer) * CGFloat(staging.backingDriftScale)
        let y = backingY(layer) * CGFloat(staging.backingDriftScale)
        let shadowOpacity = layer == 0 ? 0.17 : 0.11
        let shadowRadius: CGFloat = layer == 0 ? 4.0 : 5.0
        let shadowY: CGFloat = layer == 0 ? 3.5 : 5.0

        return DeckledPaperShape(seed: layerSeed, scale: staging.deckleScale)
            .fill(backingColor(layer))
            .frame(width: width, height: height)
            .overlay(
                DeckledPaperShape(seed: layerSeed, scale: staging.deckleScale)
                    .stroke(Color.black.opacity(layer == 0 ? 0.13 : 0.09), lineWidth: 0.7)
            )
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, y: shadowY)
    }

    private func backingColor(_ layer: Int) -> Color {
        if layer == 0 {
            return Color(red: 0.91, green: 0.87, blue: 0.77)
        }
        return Color(red: 0.86, green: 0.82, blue: 0.71)
    }

    private func backingX(_ layer: Int) -> CGFloat {
        let primary: [CGFloat] = [3.5, 4.0, -3.5, -3.0]
        let secondary: [CGFloat] = [-4.5, -4.0, 4.5, 4.0]
        return layer == 0
            ? primary[blockIndex % primary.count]
            : secondary[blockIndex % secondary.count]
    }

    private func backingY(_ layer: Int) -> CGFloat {
        let stage = blockIndex % 4
        if layer == 0 {
            let primary: [CGFloat] = [7, -5, 6, -4]
            return primary[stage]
        }
        let secondary: [CGFloat] = [13, 9, 12, 10]
        return secondary[stage]
    }

    private func backingRotation(_ layer: Int) -> Double {
        let primary = [0.24, -0.22, 0.20, -0.23]
        let secondary = [-0.29, 0.27, -0.24, 0.26]
        return layer == 0
            ? primary[blockIndex % primary.count]
            : secondary[blockIndex % secondary.count]
    }
}

/// Serial reconstruction of the surviving broadside. The historical left and
/// right columns are shown one after another at a readable phone measure.
public struct FarewellReadingUnitSurface: View {
    public let unit: ReadingUnit
    public let materialStore: MaterialProfileStore
    public let materialSetting: ReaderMaterialSetting
    public let textScale: ReaderTextScale
    public let entryContext: InkAwakeningEntryContext
    public let animateOpening: Bool
    public let snapshotLayoutWidth: Double?

    private let engine = MaterialEngine()

    public init(
        unit: ReadingUnit,
        materialStore: MaterialProfileStore,
        materialSetting: ReaderMaterialSetting,
        textScale: ReaderTextScale,
        entryContext: InkAwakeningEntryContext = .naturalSectionEntry,
        animateOpening: Bool = true,
        snapshotLayoutWidth: Double? = nil
    ) {
        self.unit = unit
        self.materialStore = materialStore
        self.materialSetting = materialSetting
        self.textScale = textScale
        self.entryContext = entryContext
        self.animateOpening = animateOpening
        self.snapshotLayoutWidth = snapshotLayoutWidth
    }

    public var body: some View {
        if let material = materialStore.profile(id: unit.materialProfile.id),
           let typography = TypographyCatalog.profile(id: unit.typographyProfile.id) {
            let composition = ReaderCompositionCatalog.profile(for: unit)
            let seed = MaterialSeed.derive(base: 1827, salt: "farewell.broadside.serial")
            let recipe = engine.resolve(
                profile: material,
                state: materialSetting.materialState,
                seed: seed
            )
            let all = unit.blocks.flatMap { ReaderLineRoleResolver.presentations(for: $0, in: unit) }

            MaterialSurfaceView(recipe: recipe) {
                VStack(spacing: 0) {
                    header(
                        Array(all.filter { FarewellArtifactLayout.headerRange.contains($0.canonicalLine.number) }),
                        typography: typography,
                        composition: composition,
                        seed: seed
                    )

                    farewellColumn(
                        Array(all.filter { FarewellArtifactLayout.firstColumnRange.contains($0.canonicalLine.number) }),
                        side: .trailing,
                        typography: typography,
                        composition: composition,
                        seed: seed
                    )

                    columnTurn

                    farewellColumn(
                        Array(all.filter { FarewellArtifactLayout.secondColumnRange.contains($0.canonicalLine.number) }),
                        side: .leading,
                        typography: typography,
                        composition: composition,
                        seed: seed ^ 0x75_02
                    )
                }
                .frame(maxWidth: 610)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.leading, CGFloat(composition.openingInsets.leading))
                .padding(.trailing, CGFloat(composition.openingInsets.trailing))
                .padding(.top, CGFloat(composition.openingInsets.top))
                .padding(.bottom, CGFloat(composition.openingInsets.bottom))
                .foregroundStyle(Color.black.opacity(max(0.60, recipe.ink.density)))
            }
            .overlay(Rectangle().stroke(Color.black.opacity(0.08), lineWidth: 0.5))
            .dynamicTypeSize(textScale.dynamicTypeSize)
            .accessibilityElement(children: .contain)
        } else {
            Text("Reader profile missing for \(unit.id)")
                .padding()
        }
    }

    @ViewBuilder
    private func header(
        _ presentations: [ReaderLinePresentation],
        typography: TypographyProfileDefinition,
        composition: ReaderCompositionProfile,
        seed: UInt64
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(presentations) { presentation in
                let line = presentation.canonicalLine.number
                let token: TypographyToken = {
                    if line == 1893 { return typography.token(.sourceHeader) }
                    if line == 1894 { return typography.token(.dateHeading) }
                    return typography.token(.sectionTitle)
                }()
                let scale: Double = {
                    if line == 1892 { return pointScale * composition.headerScale }
                    if line == 1893 { return pointScale * 0.98 }
                    return pointScale * 0.90
                }()
                let lineSeed = MaterialSeed.derive(base: seed, salt: "header.\(line)")

                Group {
                    if animateOpening,
                       line == 1892,
                       let ink = ReaderInkProfileResolver.profile(for: unit) {
                        InkAwakeningText(
                            presentation.canonicalLine.text,
                            token: token,
                            profile: ink,
                            seed: lineSeed,
                            entryContext: entryContext,
                            explicitlyInstant: snapshotLayoutWidth != nil,
                            printWearProfile: composition.printWear,
                            pointScale: scale,
                            trackingDelta: line == 1892 ? composition.headerTrackingDelta : 0,
                            lineSpacingMultiplier: composition.headerLineSpacingMultiplier
                        )
                    } else {
                        PrintWearText(
                            presentation.canonicalLine.text,
                            token: token,
                            profile: composition.printWear,
                            seed: lineSeed,
                            pointScale: scale,
                            trackingDelta: line == 1892 ? composition.headerTrackingDelta : 0,
                            lineSpacingMultiplier: composition.headerLineSpacingMultiplier
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .id(presentation.id)
                .padding(.top, line == 1892 ? CGFloat(composition.headerTopSpace) : 4)
                .padding(.bottom, line == 1892 ? 14 : (line == 1894 ? CGFloat(composition.headerBottomSpace) : 5))
            }
        }
    }

    private func farewellColumn(
        _ presentations: [ReaderLinePresentation],
        side: FarewellColumnSide,
        typography: TypographyProfileDefinition,
        composition: ReaderCompositionProfile,
        seed: UInt64
    ) -> some View {
        HStack(alignment: .top, spacing: 13) {
            if side == .leading {
                FarewellColumnOrnament(side: side, seed: seed)
            }

            VStack(alignment: .leading, spacing: 0) {
                ForEach(presentations) { presentation in
                    let line = presentation.canonicalLine.number
                    PrintWearText(
                        presentation.canonicalLine.text,
                        token: typography.token(.verse),
                        profile: composition.printWear,
                        seed: MaterialSeed.derive(base: seed, salt: "verse.\(line)"),
                        pointScale: pointScale,
                        lineSpacingMultiplier: composition.bodyLeadingMultiplier,
                        snapshotLayoutWidth: snapshotLayoutWidth
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(presentation.id)
                    .padding(.bottom, FarewellArtifactLayout.isStanzaEnd(line) ? 13 : 1.5)
                }
            }

            if side == .trailing {
                FarewellColumnOrnament(side: side, seed: seed)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var columnTurn: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 36)
            HStack(spacing: 7) {
                Rectangle().fill(Color.black.opacity(0.24)).frame(width: 22, height: 0.5)
                DiamondMark().fill(Color.black.opacity(0.36)).frame(width: 5, height: 5)
                Rectangle().fill(Color.black.opacity(0.24)).frame(width: 22, height: 0.5)
            }
            Spacer().frame(height: 34)
        }
        .accessibilityHidden(true)
    }

    private var pointScale: Double {
        switch textScale {
        case .standard: return 1
        case .large: return 1.18
        case .accessibility: return 1.55
        }
    }
}

private struct DeckledPaperShape: Shape {
    let seed: UInt64
    let scale: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let horizontalSteps = max(30, Int(rect.width / 10))
        let verticalSteps = max(22, Int(rect.height / 20))
        let inset: CGFloat = 4.6
        let roughness = CGFloat(max(0, scale))

        func hash01(_ index: Int, salt: UInt64) -> CGFloat {
            var value = seed &+ salt &+ (UInt64(index) &* 0x9E3779B97F4A7C15)
            value ^= value >> 30
            value = value &* 0xBF58476D1CE4E5B9
            value ^= value >> 27
            value = value &* 0x94D049BB133111EB
            value ^= value >> 31
            return CGFloat(Double(value & 0xFFFF) / 65535.0)
        }

        func signed(_ index: Int, salt: UInt64) -> CGFloat {
            (hash01(index, salt: salt) * 2 - 1) * roughness
        }

        func tear(_ index: Int, salt: UInt64, threshold: CGFloat, maximum: CGFloat) -> CGFloat {
            let value = hash01(index, salt: salt)
            guard value > threshold else { return 0 }
            return (1.2 + ((value - threshold) / (1 - threshold)) * maximum) * roughness
        }

        path.move(to: CGPoint(x: inset, y: inset + signed(0, salt: 0x10) * 1.3))

        for i in 0...horizontalSteps {
            let progress = CGFloat(i) / CGFloat(horizontalSteps)
            let x = inset + (rect.width - inset * 2) * progress
            let bite = tear(i, salt: 0x20, threshold: 0.94, maximum: 1.6)
            let rawY = inset
                + signed(i, salt: 0x21) * 1.45
                + CGFloat(sin(Double(i) * 0.67 + Double(seed % 23))) * 0.45 * roughness
                + bite
            let y = min(rect.maxY - inset, max(1.2, rawY))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        for i in 1...verticalSteps {
            let progress = CGFloat(i) / CGFloat(verticalSteps)
            let y = inset + (rect.height - inset * 2) * progress
            let bite = tear(i, salt: 0x30, threshold: 0.95, maximum: 1.8)
            let rawX = rect.maxX - inset + signed(i, salt: 0x31) * 1.35 - bite
            let x = min(rect.maxX - 1.1, max(rect.midX, rawX))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        for i in stride(from: horizontalSteps, through: 0, by: -1) {
            let progress = CGFloat(i) / CGFloat(horizontalSteps)
            let x = inset + (rect.width - inset * 2) * progress
            let deepTear = tear(i, salt: 0x40, threshold: 0.84, maximum: 5.4)
            let smallTear = tear(i, salt: 0x41, threshold: 0.91, maximum: 2.2)
            let rawY = rect.maxY - inset
                + signed(i, salt: 0x42) * 2.25
                + CGFloat(sin(Double(i) * 0.39 + Double(seed % 29))) * 0.8 * roughness
                - deepTear
                - smallTear
            let y = min(rect.maxY - 1.0, max(rect.midY, rawY))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        for i in stride(from: verticalSteps, through: 1, by: -1) {
            let progress = CGFloat(i) / CGFloat(verticalSteps)
            let y = inset + (rect.height - inset * 2) * progress
            let bite = tear(i, salt: 0x50, threshold: 0.94, maximum: 1.9)
            let rawX = inset + signed(i, salt: 0x51) * 1.45 + bite
            let x = max(1.1, min(rect.midX, rawX))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.closeSubpath()
        return path
    }
}

private struct DiamondMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
