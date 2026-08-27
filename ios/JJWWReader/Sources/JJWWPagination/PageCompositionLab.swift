import Foundation
import SwiftUI

@MainActor
public final class PageCompositionLabSession: ObservableObject {
    @Published public var draft: PageCompositionProfile
    public let sourceID: String

    public init(profile: PageCompositionProfile) {
        self.draft = profile
        self.sourceID = profile.id
    }

    public func reset() {
        guard let source = PageCompositionCatalog.profile(id: sourceID) else { return }
        draft = source
    }

    public func exportJSON() throws -> String {
        let data = try PageCompositionProfileCodec.encode(draft)
        return String(decoding: data, as: UTF8.self)
    }

    public func importJSON(_ text: String) throws {
        draft = try PageCompositionProfileCodec.decode(Data(text.utf8))
    }
}

#if DEBUG
public struct PageCompositionLabView: View {
    @StateObject private var session: PageCompositionLabSession
    @State private var exportedJSON = ""

    public init(profile: PageCompositionProfile = PageCompositionCatalog.argus) {
        _session = StateObject(wrappedValue: PageCompositionLabSession(profile: profile))
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("JJWW PAGE COMPOSITION LAB")
                    .font(.system(size: 28, weight: .black, design: .serif))
                Text("Stage 5.5 · opening-page geometry, spacing, rules and print condition")
                    .font(.caption.monospaced())
                    .opacity(0.62)

                GroupBox("Opening margins") {
                    fourSliders(
                        top: binding(\.openingMargins, \.top),
                        leading: binding(\.openingMargins, \.leading),
                        bottom: binding(\.openingMargins, \.bottom),
                        trailing: binding(\.openingMargins, \.trailing),
                        range: 16...140
                    )
                }

                GroupBox("Continuation margins") {
                    fourSliders(
                        top: binding(\.continuationMargins, \.top),
                        leading: binding(\.continuationMargins, \.leading),
                        bottom: binding(\.continuationMargins, \.bottom),
                        trailing: binding(\.continuationMargins, \.trailing),
                        range: 16...120
                    )
                }

                GroupBox("Body rhythm") {
                    slider("Leading multiplier", value: $session.draft.bodyLeadingMultiplier, range: 0.9...1.5)
                    slider("Paragraph indent", value: $session.draft.paragraphIndent, range: 0...30)
                    slider("Paragraph gap", value: $session.draft.paragraphGap, range: 0...14)
                }

                GroupBox("Header architecture") {
                    slider("Header scale", value: $session.draft.headerScale, range: 0.9...1.7)
                    slider("Tracking delta", value: $session.draft.headerTrackingDelta, range: -0.5...2.5)
                    slider("Line spacing multiplier", value: $session.draft.headerLineSpacingMultiplier, range: 0.8...1.6)
                    slider("Space before", value: $session.draft.headerTopSpace, range: 0...80)
                    slider("Space after", value: $session.draft.headerBottomSpace, range: 0...80)
                    slider("Running header size", value: $session.draft.runningHeaderPointSize, range: 7...16)
                }

                GroupBox("Rule") {
                    slider("Thickness", value: $session.draft.ruleThickness, range: 0...2.5)
                    slider("Length", value: $session.draft.ruleLengthFraction, range: 0.2...1)
                    slider("Gap", value: $session.draft.ruleGap, range: 0...30)
                }

                GroupBox("Print condition") {
                    slider("Header wear", value: $session.draft.printWear.headerWear, range: 0...0.4)
                    slider("Body wear", value: $session.draft.printWear.bodyWear, range: 0...0.16)
                    slider("Stroke starvation", value: $session.draft.printWear.strokeStarvation, range: 0...0.5)
                    slider("Edge erosion", value: $session.draft.printWear.edgeErosion, range: 0...0.5)
                    slider("Dark deposit", value: $session.draft.printWear.darkDeposit, range: 0...0.25)
                }

                HStack {
                    Button("Reset") { session.reset() }
                    Button("Export JSON") {
                        exportedJSON = (try? session.exportJSON()) ?? ""
                    }
                }

                if !exportedJSON.isEmpty {
                    TextEditor(text: $exportedJSON)
                        .font(.caption.monospaced())
                        .frame(minHeight: 180)
                }
            }
            .padding(22)
        }
    }

    @ViewBuilder
    private func slider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label).frame(width: 170, alignment: .leading)
            Slider(value: value, in: range)
            Text(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
                .font(.caption.monospaced())
                .frame(width: 54, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func fourSliders(
        top: Binding<Double>,
        leading: Binding<Double>,
        bottom: Binding<Double>,
        trailing: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        slider("Top", value: top, range: range)
        slider("Leading", value: leading, range: range)
        slider("Bottom", value: bottom, range: range)
        slider("Trailing", value: trailing, range: range)
    }

    private func binding(
        _ profileKeyPath: WritableKeyPath<PageCompositionProfile, PageMargins>,
        _ marginKeyPath: KeyPath<PageMargins, Double>
    ) -> Binding<Double> {
        Binding(
            get: { session.draft[keyPath: profileKeyPath][keyPath: marginKeyPath] },
            set: { newValue in
                let old = session.draft[keyPath: profileKeyPath]
                let replacement = PageMargins(
                    top: marginKeyPath == \PageMargins.top ? newValue : old.top,
                    leading: marginKeyPath == \PageMargins.leading ? newValue : old.leading,
                    bottom: marginKeyPath == \PageMargins.bottom ? newValue : old.bottom,
                    trailing: marginKeyPath == \PageMargins.trailing ? newValue : old.trailing
                )
                session.draft[keyPath: profileKeyPath] = replacement
            }
        )
    }
}
#endif
