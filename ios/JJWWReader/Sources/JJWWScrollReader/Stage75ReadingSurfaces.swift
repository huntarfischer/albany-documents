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
                        .padding(.top, -CGFloat(interval.overlapDepth))
                        .padding(.bottom, -CGFloat(interval.overlapDepth * 0.58))
                        .zIndex(1)
                    }
                }
            }
            .padding(.vertical, 12)
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
        .clipShape(DeckledPaperShape(seed: seed))
        .background {
            PeriodicalBackingPaperStack(
                seed: seed,
                blockIndex: blockIndex,
                layerCount: backingLayerCount
            )
        }
        .overlay(
            DeckledPaperShape(seed: seed)
                .stroke(Color(red: 0.20, green: 0.16, blue: 0.10).opacity(0.22), lineWidth: 0.85)
        )
        .shadow(color: .black.opacity(0.22), radius: 2.2, y: 2.4)
        .shadow(color: .black.opacity(0.34), radius: 9.5, y: 6.5)
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
        return values[blockIndex % values.count]
    }

    private var sheetHorizontalInset: CGFloat {
        let values: [CGFloat] = [6, 15, 10, 18]
        return values[blockIndex % values.count]
    }

    private var sheetDrift: CGFloat {
        let values: [CGFloat] = [-4, 6, -5, 4]
        return values[blockIndex % values.count]
    }

    private var sheetRotation: Double {
        let values = [-0.13, 0.17, -0.09, 0.11]
        return values[blockIndex % values.count]
    }
}

private struct PeriodicalBackingPaperStack: View {
    let seed: UInt64
    let blockIndex: Int
    let layerCount: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array((0..<layerCount).reversed()), id: \.self) { layer in
                    let layerSeed = seed ^ UInt64(0x75A0 + blockIndex * 31 + layer * 17)
                    DeckledPaperShape(seed: layerSeed)
                        .fill(backingColor(layer))
                        .frame(
                            width: max(0, geometry.size.width - CGFloat(layer * 3 + 2)),
                            height: max(0, geometry.size.height - CGFloat(layer * 2 + 1))
                        )
                        .overlay(
                            DeckledPaperShape(seed: layerSeed)
                                .stroke(Color.black.opacity(layer == 0 ? 0.14 : 0.10), lineWidth: 0.7)
                        )
                        .rotationEffect(.degrees(backingRotation(layer)))
                        .offset(x: backingX(layer), y: backingY(layer))
                        .shadow(
                            color: .black.opacity(layer == 0 ? 0.18 : 0.12),
                            radius: layer == 0 ? 4.5 : 5.5,
                            y: layer == 0 ? 4.5 : 6
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func backingColor(_ layer: Int) -> Color {
        if layer == 0 {
            return Color(red: 0.88, green: 0.84, blue: 0.73)
        }
        return Color(red: 0.82, green: 0.78, blue: 0.66)
    }

    private func backingX(_ layer: Int) -> CGFloat {
        let primary: [CGFloat] = [3.5, -3.0, 4.0, -2.5]
        let secondary: [CGFloat] = [-4.5, 5.0, -3.5, 4.5]
        return layer == 0
            ? primary[blockIndex % primary.count]
            : secondary[blockIndex % secondary.count]
    }

    private func backingY(_ layer: Int) -> CGFloat {
        layer == 0 ? 8 : 14
    }

    private func backingRotation(_ layer: Int) -> Double {
        let primary = [0.26, -0.20, 0.22, -0.24]
        let secondary = [-0.31, 0.29, -0.25, 0.27]
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

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let horizontalSteps = max(26, Int(rect.width / 12))
        let verticalSteps = max(20, Int(rect.height / 22))
        let inset: CGFloat = 4.5

        func noise(_ index: Int, salt: UInt64, primary: Double, secondary: Double) -> CGFloat {
            let phase = Double((seed ^ salt) % 997) * 0.017
            let x = Double(index)
            return CGFloat(
                sin(x * 1.37 + phase) * primary
                + sin(x * 0.53 + phase * 1.71) * secondary
            )
        }

        func periodicBite(_ index: Int, modulus: Int, depth: CGFloat, salt: UInt64) -> CGFloat {
            let offset = Int((seed ^ salt) % UInt64(modulus))
            return (index + offset).isMultiple(of: modulus) ? depth : 0
        }

        let startY = inset + noise(0, salt: 0x11, primary: 1.35, secondary: 0.75)
        path.move(to: CGPoint(x: inset, y: startY))

        // Quiet top edge: hand-cut, but not theatrically torn.
        for i in 0...horizontalSteps {
            let progress = CGFloat(i) / CGFloat(horizontalSteps)
            let x = inset + (rect.width - inset * 2) * progress
            let rawY = inset + noise(i, salt: 0x21, primary: 1.45, secondary: 0.85)
            let y = min(rect.maxY - inset, max(1.3, rawY))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Side edges retain visible fiber variation while staying readable.
        for i in 1...verticalSteps {
            let progress = CGFloat(i) / CGFloat(verticalSteps)
            let y = inset + (rect.height - inset * 2) * progress
            let bite = periodicBite(i, modulus: 17, depth: 1.4, salt: 0x31)
            let rawX = rect.maxX - inset + noise(i, salt: 0x32, primary: 1.25, secondary: 0.70) - bite
            let x = min(rect.maxX - 1.2, max(rect.midX, rawX))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Bottom edge carries the strongest tears and occasional deeper bites.
        for i in stride(from: horizontalSteps, through: 0, by: -1) {
            let progress = CGFloat(i) / CGFloat(horizontalSteps)
            let x = inset + (rect.width - inset * 2) * progress
            let bite = periodicBite(i, modulus: 11, depth: 4.2, salt: 0x41)
                + periodicBite(i, modulus: 19, depth: 2.6, salt: 0x42)
            let rawY = rect.maxY - inset
                + noise(i, salt: 0x43, primary: 2.65, secondary: 1.55)
                - bite
            let y = min(rect.maxY - 1.1, max(rect.midY, rawY))
            path.addLine(to: CGPoint(x: x, y: y))
        }

        for i in stride(from: verticalSteps, through: 1, by: -1) {
            let progress = CGFloat(i) / CGFloat(verticalSteps)
            let y = inset + (rect.height - inset * 2) * progress
            let bite = periodicBite(i, modulus: 13, depth: 1.6, salt: 0x51)
            let rawX = inset + noise(i, salt: 0x52, primary: 1.35, secondary: 0.75) + bite
            let x = max(1.2, min(rect.midX, rawX))
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
