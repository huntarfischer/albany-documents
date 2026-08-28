import Foundation
import SwiftUI
import Combine
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography
import JJWWScrollReader

#if DEBUG
@MainActor
public final class ReaderWorkshopSession: ObservableObject {
    public let edition: Edition
    public let materialStore: MaterialProfileStore

    @Published public var selectedUnitID: String
    @Published public var draftMaterial: MaterialProfileDefinition
    @Published public var draftTypography: TypographyProfileDefinition
    @Published public var draftComposition: ReaderCompositionProfile
    @Published public var selectedRole: TypographyRole
    @Published public var revision: Int = 0
    @Published public var transferText: String = ""

    public init(edition: Edition, materialStore: MaterialProfileStore) {
        precondition(!edition.orderedReadingUnits.isEmpty, "ReaderWorkshopSession requires a non-empty edition")
        self.edition = edition
        self.materialStore = materialStore

        let initial = edition.orderedReadingUnits.first(where: { $0.kind != .cover }) ?? edition.orderedReadingUnits[0]
        selectedUnitID = initial.id
        draftMaterial = materialStore.profile(id: initial.materialProfile.id) ?? materialStore.profiles[0]
        draftTypography = TypographyCatalog.profile(id: initial.typographyProfile.id) ?? TypographyCatalog.editorial
        draftComposition = ReaderCompositionCatalog.profile(for: initial)
        selectedRole = draftTypography.tokens.first?.role ?? .body
    }

    public var selectedUnit: ReadingUnit {
        edition.readingUnit(id: selectedUnitID) ?? edition.orderedReadingUnits[0]
    }

    public var availableUnits: [ReadingUnit] {
        edition.orderedReadingUnits.filter { $0.kind != .cover }
    }

    public func selectUnit(_ id: String) {
        guard let unit = edition.readingUnit(id: id) else { return }
        selectedUnitID = id
        draftMaterial = materialStore.profile(id: unit.materialProfile.id) ?? materialStore.profiles[0]
        draftTypography = TypographyCatalog.profile(id: unit.typographyProfile.id) ?? TypographyCatalog.editorial
        draftComposition = ReaderCompositionCatalog.profile(for: unit)
        selectedRole = draftTypography.tokens.first?.role ?? .body
        revision &+= 1
    }

    public func updateMaterial(_ edit: (inout MaterialProfileDefinition) -> Void) {
        var copy = draftMaterial
        edit(&copy)
        draftMaterial = copy
        MaterialTuningRegistry.shared.set(copy)
        revision &+= 1
    }

    public func updateTypography(_ edit: (inout TypographyProfileDefinition) -> Void) {
        var copy = draftTypography
        edit(&copy)
        draftTypography = copy
        TypographyTuningRegistry.shared.set(copy)
        revision &+= 1
    }

    public func updateSelectedToken(_ edit: (inout TypographyToken) -> Void) {
        updateTypography { profile in
            guard let index = profile.tokens.firstIndex(where: { $0.role == self.selectedRole }) else { return }
            edit(&profile.tokens[index])
        }
    }

    public func updateComposition(_ edit: (inout ReaderCompositionProfile) -> Void) {
        var copy = draftComposition
        edit(&copy)
        draftComposition = copy
        ReaderCompositionTuningRegistry.shared.set(copy)
        revision &+= 1
    }

    public func resetSelected() {
        let unit = selectedUnit
        MaterialTuningRegistry.shared.remove(id: unit.materialProfile.id)
        TypographyTuningRegistry.shared.remove(id: unit.typographyProfile.id)
        let baseComposition = ReaderCompositionCatalog.bundledProfile(for: unit)
        ReaderCompositionTuningRegistry.shared.remove(id: baseComposition.id)

        draftMaterial = materialStore.bundledProfile(id: unit.materialProfile.id) ?? draftMaterial
        draftTypography = TypographyCatalog.bundledProfile(id: unit.typographyProfile.id) ?? draftTypography
        draftComposition = baseComposition
        selectedRole = draftTypography.tokens.first?.role ?? .body
        revision &+= 1
    }

    public func resetAll() {
        MaterialTuningRegistry.shared.removeAll()
        TypographyTuningRegistry.shared.removeAll()
        ReaderCompositionTuningRegistry.shared.removeAll()
        selectUnit(selectedUnitID)
    }

    public func exportCurrent() {
        let payload = ReaderWorkshopExport(
            version: "stage7.75-v0.1",
            unitID: selectedUnit.id,
            material: draftMaterial,
            typography: draftTypography,
            composition: draftComposition
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(payload) {
            transferText = String(decoding: data, as: UTF8.self)
        }
    }
}

public struct ReaderWorkshopExport: Codable, Sendable {
    public let version: String
    public let unitID: String
    public let material: MaterialProfileDefinition
    public let typography: TypographyProfileDefinition
    public let composition: ReaderCompositionProfile
}

public struct ReaderWorkshopView: View {
    private enum Pane: String, CaseIterable {
        case preview = "Preview"
        case material = "Material"
        case type = "Type"
        case composition = "Composition"
        case export = "Export"
    }

    @StateObject private var session: ReaderWorkshopSession
    @State private var pane: Pane = .preview

    public init(edition: Edition, materialStore: MaterialProfileStore) {
        _session = StateObject(
            wrappedValue: ReaderWorkshopSession(
                edition: edition,
                materialStore: materialStore
            )
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("READER WORKSHOP")
                    .font(.headline.bold())
                Spacer()
                Button("Reset") { session.resetSelected() }
                Button("Reset All") { session.resetAll() }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)

            Picker("Reading unit", selection: Binding(
                get: { session.selectedUnitID },
                set: { session.selectUnit($0) }
            )) {
                ForEach(session.availableUnits) { unit in
                    Text(unit.sourcePresentation?.displayTitle ?? unit.id)
                        .tag(unit.id)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Picker("Workshop pane", selection: $pane) {
                ForEach(Pane.allCases, id: \.self) { pane in
                    Text(pane.rawValue).tag(pane)
                }
            }
            .pickerStyle(.segmented)
            .padding(12)

            Divider()

            switch pane {
            case .preview:
                productionPreview
            case .material:
                materialControls
            case .type:
                typographyControls
            case .composition:
                compositionControls
            case .export:
                exportPane
            }
        }
    }

    private var productionPreview: some View {
        ScrollView {
            ReadingUnitSurface(
                unit: session.selectedUnit,
                materialStore: session.materialStore,
                materialSetting: .full,
                textScale: .standard,
                entryContext: .jumpIntoSection,
                animateOpening: false,
                snapshotLayoutWidth: 322
            )
            .id("\(session.selectedUnitID)-\(session.revision)")
            .frame(width: 390)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black.opacity(0.16), lineWidth: 0.5))
            .shadow(radius: 12, y: 6)
            .padding(.vertical, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondary.opacity(0.08))
    }

    private var materialControls: some View {
        Form {
            Section("Paper") {
                workshopSlider("Warmth", value: materialBinding(
                    get: { $0.effectivePaperTuning.warmth },
                    set: { profile, value in
                        var tuning = profile.effectivePaperTuning
                        tuning.warmth = value
                        profile.paperTuning = tuning
                    }
                ), range: -0.30...0.30)
                workshopSlider("Brightness", value: materialBinding(
                    get: { $0.effectivePaperTuning.brightness },
                    set: { profile, value in
                        var tuning = profile.effectivePaperTuning
                        tuning.brightness = value
                        profile.paperTuning = tuning
                    }
                ), range: -0.30...0.30)
                workshopSlider("Mottling", value: materialBinding(
                    get: { $0.mottling.amount },
                    set: { profile, value in profile.mottling.amount = value }
                ), range: 0...0.60)
                workshopSlider("Grain", value: materialBinding(
                    get: { $0.grain.amount },
                    set: { profile, value in profile.grain.amount = value }
                ), range: 0...0.50)
                workshopSlider("Fibers", value: materialBinding(
                    get: { $0.fibers.density },
                    set: { profile, value in profile.fibers.density = value }
                ), range: 0...0.80)
                workshopSlider("Edge wear", value: materialBinding(
                    get: { $0.edgeVariation.amount },
                    set: { profile, value in profile.edgeVariation.amount = value }
                ), range: 0...0.60)
            }

            Section("Ink") {
                workshopSlider("Density", value: materialBinding(
                    get: { $0.effectiveInk.density },
                    set: { profile, value in
                        var ink = profile.effectiveInk
                        ink.density = value
                        profile.ink = ink
                    }
                ), range: 0.45...1.0)
                workshopSlider("Bleed", value: materialBinding(
                    get: { $0.effectiveInk.bleed },
                    set: { profile, value in
                        var ink = profile.effectiveInk
                        ink.bleed = value
                        profile.ink = ink
                    }
                ), range: 0...0.40)
            }

            Section {
                Button("See this on the production reader") { pane = .preview }
            }
        }
    }

    private var typographyControls: some View {
        Form {
            Section("Role") {
                Picker("Role", selection: $session.selectedRole) {
                    ForEach(session.draftTypography.tokens.map(\.role), id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
            }

            if let token = selectedToken {
                Section("Face") {
                    TextField("Font family", text: Binding(
                        get: { token.fontFamily ?? "" },
                        set: { value in
                            session.updateSelectedToken { $0.fontFamily = value.isEmpty ? nil : value }
                        }
                    ))

                    Picker("Text style", selection: Binding(
                        get: { token.textStyle },
                        set: { value in session.updateSelectedToken { $0.textStyle = value } }
                    )) {
                        ForEach(TypographyDynamicTextStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }

                    Picker("Weight", selection: Binding(
                        get: { token.weight },
                        set: { value in session.updateSelectedToken { $0.weight = value } }
                    )) {
                        ForEach(TypographyWeight.allCases, id: \.self) { weight in
                            Text(weight.rawValue).tag(weight)
                        }
                    }
                }

                Section("Rhythm") {
                    workshopSlider("Tracking", value: tokenBinding(\.tracking), range: -2.5...4.0)
                    workshopSlider("Line spacing", value: tokenBinding(\.lineSpacing), range: -3...12)
                    workshopSlider("Hyphenation", value: tokenBinding(\.hyphenationFactor), range: 0...1)

                    Picker("Alignment", selection: Binding(
                        get: { token.paragraphAlignment },
                        set: { value in session.updateSelectedToken { $0.paragraphAlignment = value } }
                    )) {
                        ForEach(TypographyParagraphAlignment.allCases, id: \.self) { alignment in
                            Text(alignment.rawValue).tag(alignment)
                        }
                    }

                    Toggle("Uppercase", isOn: Binding(
                        get: { token.uppercase },
                        set: { value in session.updateSelectedToken { $0.uppercase = value } }
                    ))
                }
            }

            Section {
                Button("See this on the production reader") { pane = .preview }
            }
        }
    }

    private var compositionControls: some View {
        Form {
            Section("Header architecture") {
                workshopSlider("Header scale", value: compositionBinding(\.headerScale), range: 0.65...1.70)
                workshopSlider("Tracking delta", value: compositionBinding(\.headerTrackingDelta), range: -1.5...2.5)
                workshopSlider("Line spacing", value: compositionBinding(\.headerLineSpacingMultiplier), range: 0.70...1.50)
                workshopSlider("Space before", value: compositionBinding(\.headerTopSpace), range: 0...80)
                workshopSlider("Space after", value: compositionBinding(\.headerBottomSpace), range: 0...80)
            }

            Section("Role-specific print sizing") {
                optionalWearSlider("Date scale", keyPath: \.datePointScale, fallback: 1.0, range: 0.35...1.25)
                optionalWearSlider("Masthead scale", keyPath: \.sourceHeaderPointScale, fallback: 1.0, range: 0.65...1.35)
                optionalWearSlider("Title scale", keyPath: \.sectionTitlePointScale, fallback: 1.0, range: 0.55...1.35)
                optionalWearSlider("Date tracking adjust", keyPath: \.dateTrackingAdjustment, fallback: 0, range: -2...2)
                optionalWearSlider("Masthead tracking adjust", keyPath: \.sourceHeaderTrackingAdjustment, fallback: 0, range: -2...2)
                optionalWearSlider("Masthead line spacing", keyPath: \.sourceHeaderLineSpacingOverride, fallback: 0, range: -5...8)
            }

            Section("Body") {
                workshopSlider("Leading multiplier", value: compositionBinding(\.bodyLeadingMultiplier), range: 0.85...1.45)
                workshopSlider("Paragraph gap", value: compositionBinding(\.paragraphGap), range: 0...18)
                workshopSlider("Paragraph indent", value: compositionBinding(\.paragraphIndent), range: 0...32)
            }

            Section("Rule") {
                workshopSlider("Thickness", value: compositionBinding(\.ruleThickness), range: 0...2.5)
                workshopSlider("Length", value: compositionBinding(\.ruleLengthFraction), range: 0.15...1)
                workshopSlider("Gap", value: compositionBinding(\.ruleGap), range: 0...30)
            }

            Section("Print impression") {
                workshopSlider("Header wear", value: wearBinding(\.headerWear), range: 0...0.40)
                workshopSlider("Body wear", value: wearBinding(\.bodyWear), range: 0...0.18)
                workshopSlider("Starvation", value: wearBinding(\.strokeStarvation), range: 0...0.50)
                workshopSlider("Edge erosion", value: wearBinding(\.edgeErosion), range: 0...0.50)
                workshopSlider("Dark deposit", value: wearBinding(\.darkDeposit), range: 0...0.25)
                optionalWearSlider("Ink opacity", keyPath: \.inkOpacity, fallback: 1.0, range: 0.55...1)
                Toggle("Multiply into paper", isOn: Binding(
                    get: { session.draftComposition.printWear.usesMultiplyBlend ?? false },
                    set: { value in
                        session.updateComposition { $0.printWear.usesMultiplyBlend = value }
                    }
                ))
            }

            Section("Opening insets") {
                workshopSlider("Top", value: insetBinding(\.top), range: 10...140)
                workshopSlider("Leading", value: insetBinding(\.leading), range: 10...80)
                workshopSlider("Bottom", value: insetBinding(\.bottom), range: 10...120)
                workshopSlider("Trailing", value: insetBinding(\.trailing), range: 10...80)
            }

            Section {
                Button("See this on the production reader") { pane = .preview }
            }
        }
    }

    private var exportPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Export current profile bundle") { session.exportCurrent() }
                    .buttonStyle(.borderedProminent)
                Spacer()
            }

            Text("Drafting data only. Canonical text is never edited by the Workshop. Approved values can be checked into the normal profile catalogs.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            TextEditor(text: $session.transferText)
                .font(.system(.caption, design: .monospaced))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.25)))
        }
        .padding(16)
    }

    private var selectedToken: TypographyToken? {
        session.draftTypography.tokens.first(where: { $0.role == session.selectedRole })
    }

    private func materialBinding(
        get: @escaping (MaterialProfileDefinition) -> Double,
        set: @escaping (inout MaterialProfileDefinition, Double) -> Void
    ) -> Binding<Double> {
        Binding(
            get: { get(session.draftMaterial) },
            set: { value in
                session.updateMaterial { profile in
                    set(&profile, value)
                }
            }
        )
    }

    private func compositionBinding(_ keyPath: WritableKeyPath<ReaderCompositionProfile, Double>) -> Binding<Double> {
        Binding(
            get: { session.draftComposition[keyPath: keyPath] },
            set: { value in session.updateComposition { $0[keyPath: keyPath] = value } }
        )
    }

    private func wearBinding(_ keyPath: WritableKeyPath<PrintWearProfile, Double>) -> Binding<Double> {
        Binding(
            get: { session.draftComposition.printWear[keyPath: keyPath] },
            set: { value in session.updateComposition { $0.printWear[keyPath: keyPath] = value } }
        )
    }

    private func optionalWearSlider(
        _ label: String,
        keyPath: WritableKeyPath<PrintWearProfile, Double?>,
        fallback: Double,
        range: ClosedRange<Double>
    ) -> some View {
        workshopSlider(
            label,
            value: Binding(
                get: { session.draftComposition.printWear[keyPath: keyPath] ?? fallback },
                set: { value in session.updateComposition { $0.printWear[keyPath: keyPath] = value } }
            ),
            range: range
        )
    }

    private func tokenBinding(_ keyPath: WritableKeyPath<TypographyToken, Double>) -> Binding<Double> {
        Binding(
            get: { selectedToken?[keyPath: keyPath] ?? 0 },
            set: { value in session.updateSelectedToken { $0[keyPath: keyPath] = value } }
        )
    }

    private func insetBinding(_ keyPath: WritableKeyPath<ReaderCompositionInsets, Double>) -> Binding<Double> {
        Binding(
            get: { session.draftComposition.openingInsets[keyPath: keyPath] },
            set: { value in session.updateComposition { $0.openingInsets[keyPath: keyPath] = value } }
        )
    }

    private func workshopSlider(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
        }
    }
}
#endif
