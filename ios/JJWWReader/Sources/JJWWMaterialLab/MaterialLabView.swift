import SwiftUI
import JJWWMaterials

#if DEBUG
public struct MaterialLabView: View {
    @StateObject private var session: MaterialLabSession

    public init(profiles: [MaterialProfileDefinition]) {
        _session = StateObject(wrappedValue: MaterialLabSession(profiles: profiles))
    }

    public var body: some View {
        HStack(spacing: 0) {
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
                .overlay(Color.white.opacity(0.12))
            controls
                .frame(width: 620)
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.16))
        }
        .frame(minWidth: 1100, minHeight: 720)
        .foregroundStyle(Color.white.opacity(0.92))
        .background(Color(red: 0.075, green: 0.07, blue: 0.062))
        .preferredColorScheme(.dark)
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("JJWW MATERIAL LAB")
                        .font(.system(size: 25, weight: .black, design: .serif))
                    Text("Stage 2 · live deterministic tuning")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.58))
                }
                Spacer()
                Text(session.materialState.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.3), in: Capsule())
            }

            MaterialSurfaceView(recipe: session.recipe) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(session.draftProfile.displayName.uppercased())
                        .font(.system(size: 26, weight: .bold, design: .serif))
                    Text(session.draftProfile.id)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .opacity(0.62)
                    Spacer()
                    Text("MATERIAL LAB PROOF")
                        .font(.system(size: 13, weight: .black, design: .serif))
                    Text("The paper should carry atmosphere without carrying the text. Every visible decision should survive export as profile data.")
                        .font(.system(size: 21, design: .serif))
                        .lineSpacing(4)
                    Text("seed \(session.seed) · marks \(session.recipe.decorativeMarkCount)")
                        .font(.system(size: 10, design: .monospaced))
                        .opacity(0.52)
                }
                .foregroundStyle(Color.black.opacity(max(0.45, session.draftProfile.effectiveInk.density)))
                .padding(30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )

            Text("Ink bleed is stored now for Stage 3 Ink Awakening; it is intentionally not faked into body text during Stage 2.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.52))
        }
        .padding(24)
    }

    private var controls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                profileControls
                controlGroup("PAPER") {
                    slider("Warmth", value: Binding(
                        get: { session.draftProfile.effectivePaperTuning.warmth },
                        set: { session.setPaperWarmth($0) }
                    ), range: -0.35...0.35)
                    slider("Brightness", value: Binding(
                        get: { session.draftProfile.effectivePaperTuning.brightness },
                        set: { session.setPaperBrightness($0) }
                    ), range: -0.25...0.25)
                }

                controlGroup("MOTTLING") {
                    slider("Amount", value: profileBinding(\.mottling.amount), range: 0...0.5)
                    slider("Scale", value: profileBinding(\.mottling.scale), range: 0.2...2.0)
                    intStepper("Count", value: profileBinding(\.mottling.count), range: 0...40)
                }

                controlGroup("GRAIN") {
                    slider("Amount", value: profileBinding(\.grain.amount), range: 0...0.4)
                    slider("Scale", value: profileBinding(\.grain.scale), range: 0.25...2.0)
                    intStepper("Resolution", value: profileBinding(\.grain.resolution), range: 64...512, step: 32)
                }

                controlGroup("FIBERS") {
                    slider("Density", value: profileBinding(\.fibers.density), range: 0...1.0)
                    slider("Min length", value: profileBinding(\.fibers.minLength), range: 0.002...0.12)
                    slider("Max length", value: profileBinding(\.fibers.maxLength), range: 0.005...0.16)
                    slider("Opacity", value: profileBinding(\.fibers.opacity), range: 0...0.4)
                    slider("Width", value: profileBinding(\.fibers.width), range: 0.2...1.4)
                }

                controlGroup("FLECKS") {
                    slider("Density", value: profileBinding(\.flecks.density), range: 0...0.6)
                    slider("Min radius", value: profileBinding(\.flecks.minRadius), range: 0.0002...0.01)
                    slider("Max radius", value: profileBinding(\.flecks.maxRadius), range: 0.0005...0.018)
                    slider("Opacity", value: profileBinding(\.flecks.opacity), range: 0...0.4)
                }

                controlGroup("FOXING") {
                    slider("Amount", value: profileBinding(\.foxing.amount), range: 0...0.25)
                    slider("Min radius", value: profileBinding(\.foxing.minRadius), range: 0.002...0.08)
                    slider("Max radius", value: profileBinding(\.foxing.maxRadius), range: 0.004...0.14)
                    intStepper("Count", value: profileBinding(\.foxing.count), range: 0...24)
                }

                controlGroup("EDGES") {
                    slider("Wear", value: profileBinding(\.edgeVariation.amount), range: 0...0.3)
                    slider("Width", value: profileBinding(\.edgeVariation.width), range: 0.01...0.16)
                }

                controlGroup("SCAN SLOT") {
                    slider("Opacity", value: profileBinding(\.scanOverlay.opacity), range: 0...1)
                    slider("Scale / crop", value: profileBinding(\.scanOverlay.scale), range: 0.5...2.5)
                    slider("Offset X", value: profileBinding(\.scanOverlay.offsetX), range: -240...240, decimals: 1)
                    slider("Offset Y", value: profileBinding(\.scanOverlay.offsetY), range: -240...240, decimals: 1)
                }

                controlGroup("CLOTH") {
                    Toggle("Enabled", isOn: profileBinding(\.clothWeave.enabled))
                    slider("Vertical density", value: profileBinding(\.clothWeave.verticalDensity), range: 0...1.5)
                    slider("Horizontal density", value: profileBinding(\.clothWeave.horizontalDensity), range: 0...1.5)
                    slider("Opacity", value: profileBinding(\.clothWeave.opacity), range: 0...0.5)
                    slider("Thread width", value: profileBinding(\.clothWeave.width), range: 0.2...1.4)
                }

                controlGroup("INK · STAGE 3 READY") {
                    slider("Density", value: Binding(
                        get: { session.draftProfile.effectiveInk.density },
                        set: { session.setInkDensity($0) }
                    ), range: 0.45...1.0)
                    slider("Future bleed", value: Binding(
                        get: { session.draftProfile.effectiveInk.bleed },
                        set: { session.setInkBleed($0) }
                    ), range: 0...1.0)
                }

                exportControls
            }
            .padding(20)
        }
        .scrollIndicators(.visible)
    }

    private var profileControls: some View {
        controlGroup("LAB") {
            Picker("Profile", selection: Binding(
                get: { session.selectedProfileID },
                set: { session.selectProfile(id: $0) }
            )) {
                ForEach(session.profiles) { profile in
                    Text(profile.displayName).tag(profile.id)
                }
            }

            Picker("Material", selection: $session.materialState) {
                ForEach(MaterialState.allCases, id: \.self) { state in
                    Text(state.rawValue.capitalized).tag(state)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Text("Seed")
                TextField("Seed", text: Binding(
                    get: { String(session.seed) },
                    set: { if let value = UInt64($0) { session.seed = value } }
                ))
                .textFieldStyle(.roundedBorder)
                Button("+1") { session.seed &+= 1 }
                Button("Reset") { session.resetSelectedProfile() }
            }
        }
    }

    private var exportControls: some View {
        controlGroup("PROFILE DATA") {
            HStack {
                Button("Export Profile") {
                    do { _ = try session.exportProfile() }
                    catch { session.transferText = "EXPORT ERROR: \(error)" }
                }
                Button("Import JSON") {
                    do { try session.importProfile() }
                    catch { session.transferText = "IMPORT ERROR: \(error)" }
                }
                Spacer()
                if let message = session.message {
                    Text(message)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            TextEditor(text: $session.transferText)
                .font(.system(size: 10, design: .monospaced))
                .frame(minHeight: 150)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func controlGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(Color.orange)
            content()
        }
        .padding(12)
        .background(.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
    }

    private func slider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        decimals: Int = 3
    ) -> some View {
        VStack(spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(decimals))))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
            Slider(value: value, in: range)
        }
    }

    private func intStepper(
        _ title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1
    ) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.55))
            }
        }
    }

    private func profileBinding<Value>(
        _ keyPath: WritableKeyPath<MaterialProfileDefinition, Value>
    ) -> Binding<Value> {
        Binding(
            get: { session.draftProfile[keyPath: keyPath] },
            set: { value in
                session.updateProfile { $0[keyPath: keyPath] = value }
            }
        )
    }
}
#endif
