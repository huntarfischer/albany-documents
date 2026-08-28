import Foundation
import SwiftUI
import Combine
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader

#if DEBUG
@MainActor
public final class PeriodicalStagingLabSession: ObservableObject {
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    public let units: [ReadingUnit]

    @Published public var selectedUnitID: String
    @Published public var draft: PeriodicalStagingProfile
    @Published public var revision: Int = 0
    @Published public var transferText: String = ""

    public init(edition: Edition, materialStore: MaterialProfileStore) {
        self.edition = edition
        self.materialStore = materialStore
        let periodicals = edition.orderedReadingUnits.filter { $0.sourcePresentation?.sourceKind == .periodical }
        self.units = periodicals
        let first = periodicals.first ?? edition.orderedReadingUnits[0]
        self.selectedUnitID = first.id
        self.draft = PeriodicalStagingCatalog.profile(for: first)
    }

    public var selectedUnit: ReadingUnit {
        edition.readingUnit(id: selectedUnitID) ?? units.first ?? edition.orderedReadingUnits[0]
    }

    public func select(_ id: String) {
        guard let unit = edition.readingUnit(id: id) else { return }
        selectedUnitID = id
        draft = PeriodicalStagingCatalog.profile(for: unit)
        revision &+= 1
    }

    public func update(_ edit: (inout PeriodicalStagingProfile) -> Void) {
        var copy = draft
        edit(&copy)
        draft = copy
        PeriodicalStagingTuningRegistry.shared.set(copy)
        revision &+= 1
    }

    public func reset() {
        let base = PeriodicalStagingCatalog.bundledProfile(for: selectedUnit)
        PeriodicalStagingTuningRegistry.shared.remove(id: base.id)
        draft = base
        revision &+= 1
    }

    public func exportJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(draft) {
            transferText = String(decoding: data, as: UTF8.self)
        }
    }
}

public struct PeriodicalStagingLabView: View {
    @StateObject private var session: PeriodicalStagingLabSession

    public init(edition: Edition, materialStore: MaterialProfileStore) {
        _session = StateObject(
            wrappedValue: PeriodicalStagingLabSession(
                edition: edition,
                materialStore: materialStore
            )
        )
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("PAPER STAGING")
                        .font(.headline.bold())
                    Spacer()
                    Button("Reset") { session.reset() }
                }

                Picker("Periodical", selection: Binding(
                    get: { session.selectedUnitID },
                    set: { session.select($0) }
                )) {
                    ForEach(session.units) { unit in
                        Text(unit.sourcePresentation?.displayTitle ?? unit.id).tag(unit.id)
                    }
                }
                .pickerStyle(.menu)

                Text("PRODUCTION STACK")
                    .font(.caption.bold().monospaced())
                    .foregroundStyle(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    ReadingUnitSurface(
                        unit: session.selectedUnit,
                        materialStore: session.materialStore,
                        materialSetting: .full,
                        textScale: .standard,
                        entryContext: .jumpIntoSection,
                        animateOpening: false,
                        snapshotLayoutWidth: 322
                    )
                    .id("staging-\(session.selectedUnitID)-\(session.revision)")
                    .frame(width: 390)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.07))

                GroupBox("Sheet placement") {
                    control("Inset scale", value: binding(\.sheetInsetScale), range: 0.25...1.80)
                    control("Drift scale", value: binding(\.sheetDriftScale), range: 0...2.50)
                    control("Rotation scale", value: binding(\.sheetRotationScale), range: 0...3.00)
                    control("Backing drift", value: binding(\.backingDriftScale), range: 0...2.50)
                    Stepper(
                        "Backing layers: \(session.draft.backingLayerLimit)",
                        value: Binding(
                            get: { session.draft.backingLayerLimit },
                            set: { value in session.update { $0.backingLayerLimit = value } }
                        ),
                        in: 0...3
                    )
                }

                GroupBox("Paper edge + interval") {
                    control("Deckle scale", value: binding(\.deckleScale), range: 0...2.25)
                    control("Interval height", value: binding(\.intervalHeightScale), range: 0.35...2.25)
                    control("Stack padding", value: binding(\.stackVerticalPadding), range: 0...40)
                }

                GroupBox("Contact shadow") {
                    control("Opacity", value: binding(\.contactShadowOpacity), range: 0...0.60)
                    control("Radius", value: binding(\.contactShadowRadius), range: 0...10)
                    control("Y", value: binding(\.contactShadowY), range: 0...12)
                }

                GroupBox("Ambient shadow") {
                    control("Opacity", value: binding(\.ambientShadowOpacity), range: 0...0.65)
                    control("Radius", value: binding(\.ambientShadowRadius), range: 0...24)
                    control("Y", value: binding(\.ambientShadowY), range: 0...20)
                }

                HStack {
                    Button("Export JSON") { session.exportJSON() }
                }
                .buttonStyle(.bordered)

                if !session.transferText.isEmpty {
                    TextEditor(text: $session.transferText)
                        .font(.caption.monospaced())
                        .frame(minHeight: 180)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.secondary.opacity(0.25)))
                }
            }
            .padding(16)
        }
    }

    private func binding(_ keyPath: WritableKeyPath<PeriodicalStagingProfile, Double>) -> Binding<Double> {
        Binding(
            get: { session.draft[keyPath: keyPath] },
            set: { value in session.update { $0[keyPath: keyPath] = value } }
        )
    }

    private func control(
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
