import SwiftUI
import JJWWTypography

#if DEBUG
public struct InkLabView: View {
    @StateObject private var session = InkLabSession()

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < 1000 {
                compactLayout
            } else {
                regularLayout
            }
        }
        .foregroundStyle(Color.white.opacity(0.92))
        .background(Color(red: 0.075, green: 0.07, blue: 0.062))
        .preferredColorScheme(.dark)
    }

    private var compactLayout: some View {
        ScrollView {
            VStack(spacing: 0) {
                preview
                    .frame(height: 500)
                Divider()
                    .overlay(Color.white.opacity(0.12))
                controlStack
                    .padding(16)
                    .background(Color.black.opacity(0.16))
            }
        }
        .scrollIndicators(.visible)
    }

    private var regularLayout: some View {
        HStack(spacing: 0) {
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
                .overlay(Color.white.opacity(0.12))
            controls
                .frame(width: 540)
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.16))
        }
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 3) {
                Text("JJWW INK LAB")
                    .font(.system(size: 25, weight: .black, design: .serif))
                Text("Stage 3 · section-opening ritual only")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.58))
            }

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.88, green: 0.82, blue: 0.67))
                .overlay {
                    VStack(spacing: 18) {
                        InkAwakeningPreviewText(
                            sample.date,
                            token: typography.token(.dateHeading),
                            profile: session.draftProfile,
                            seed: session.seed,
                            progress: session.previewProgress
                        )
                        InkAwakeningPreviewText(
                            sample.source,
                            token: typography.token(.sourceHeader),
                            profile: session.draftProfile,
                            seed: session.seed &+ 1,
                            progress: session.previewProgress
                        )
                        InkAwakeningPreviewText(
                            sample.title,
                            token: typography.token(.sectionTitle),
                            profile: session.draftProfile,
                            seed: session.seed &+ 2,
                            progress: session.previewProgress
                        )
                    }
                    .foregroundStyle(Color.black.opacity(0.84))
                    .padding(34)
                }
                .frame(minHeight: 300)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Preview")
                    Spacer()
                    Text(session.previewProgress.formatted(.number.precision(.fractionLength(2))))
                        .font(.system(size: 10, design: .monospaced))
                }
                Slider(value: $session.previewProgress, in: 0...1)
            }

            Text("At 1.00 the text is ordinary semantic SwiftUI text. The mask never changes the string, reading order, or accessibility label.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.5))
        }
        .padding(24)
    }

    private var controls: some View {
        ScrollView {
            controlStack
                .padding(20)
        }
        .scrollIndicators(.visible)
    }

    private var controlStack: some View {
        VStack(alignment: .leading, spacing: 18) {
            group("INK PROFILE") {
                Picker("Section", selection: Binding(
                    get: { session.selectedProfileID },
                    set: { session.selectProfile(id: $0) }
                )) {
                    ForEach(session.profiles) { profile in
                        Text(profile.id.replacingOccurrences(of: "ink.", with: "")).tag(profile.id)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Seed")
                        Spacer()
                        Button("+1") { session.seed &+= 1 }
                    }
                    TextField("Seed", text: Binding(
                        get: { String(session.seed) },
                        set: { if let value = UInt64($0) { session.seed = value } }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                }
            }

            group("AWAKENING") {
                slider("Duration", value: binding(\.duration), range: 0.15...2.5)
                slider("Irregularity", value: binding(\.irregularity), range: 0...1)
                slider("Blot scale", value: binding(\.blotScale), range: 0.25...1.5)
                slider("Reveal threshold", value: binding(\.revealThreshold), range: 0...0.5)
                slider("Feather / bleed", value: binding(\.feather), range: 0...0.8)
                Stepper(value: binding(\.traceCount), in: 12...140, step: 2) {
                    HStack {
                        Text("Trace count")
                        Spacer()
                        Text("\(session.draftProfile.traceCount)")
                            .font(.system(size: 10, design: .monospaced))
                    }
                }
                Picker("Opacity curve", selection: binding(\.opacityCurve)) {
                    ForEach(InkOpacityCurve.allCases, id: \.self) { curve in
                        Text(curve.rawValue).tag(curve)
                    }
                }
            }

            group("PROFILE DATA") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Button("Export Ink") {
                            do { _ = try session.exportProfile() }
                            catch { session.transferText = "EXPORT ERROR: \(error)" }
                        }
                        Button("Import Ink") {
                            do { try session.importProfile() }
                            catch { session.transferText = "IMPORT ERROR: \(error)" }
                        }
                    }
                    if let message = session.message {
                        Text(message)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                TextEditor(text: $session.transferText)
                    .font(.system(size: 10, design: .monospaced))
                    .frame(minHeight: 180)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var typography: TypographyProfileDefinition {
        switch session.draftProfile.id {
        case InkAwakeningCatalog.argus.id, InkAwakeningCatalog.dailyAdvertiser.id:
            return TypographyCatalog.newspaper
        case InkAwakeningCatalog.confession.id:
            return TypographyCatalog.confession
        case InkAwakeningCatalog.trial.id:
            return TypographyCatalog.trial
        default:
            return TypographyCatalog.farewell
        }
    }

    private var sample: (date: String, source: String, title: String) {
        switch session.draftProfile.id {
        case InkAwakeningCatalog.argus.id:
            return ("Tuesday May 8, 1827", "The Albany Argus & City Gazette", "PROCLAMATION")
        case InkAwakeningCatalog.dailyAdvertiser.id:
            return ("Monday June 18, 1827", "The Albany Daily Advertiser", "THE LATE MURDER")
        case InkAwakeningCatalog.confession.id:
            return ("1827", "The Confession Of Jesse James Strang", "CONFESSION")
        case InkAwakeningCatalog.trial.id:
            return ("July 1827", "The Trial of Jesse James Strang", "MATILDA BECKER, sworn.")
        default:
            return ("August 24, 1827", "Farewell Address", "THE FINAL WORDS OF JESSE JAMES STRANG")
        }
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(Color.orange)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(3))))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            Slider(value: value, in: range)
        }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<InkAwakeningProfile, Value>) -> Binding<Value> {
        Binding(
            get: { session.draftProfile[keyPath: keyPath] },
            set: { newValue in session.update { $0[keyPath: keyPath] = newValue } }
        )
    }
}
#endif
