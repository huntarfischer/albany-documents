import SwiftUI
import JJWWMaterials

#if DEBUG
public struct MaterialLabGateSheet: View {
    private let profile: MaterialProfileDefinition
    private let profiles: [MaterialProfileDefinition]
    private let seed: UInt64
    private let recipe: MaterialResolvedRecipe

    public init(
        profiles: [MaterialProfileDefinition],
        selectedProfileID: String = "jjwwEditorial",
        seed: UInt64 = 0x4A4A57574D41544C
    ) {
        precondition(!profiles.isEmpty)
        let selected = profiles.first(where: { $0.id == selectedProfileID }) ?? profiles[0]
        self.profiles = profiles
        self.profile = selected
        self.seed = seed
        self.recipe = MaterialEngine().resolve(profile: selected, state: .full, seed: seed)
    }

    public var body: some View {
        HStack(spacing: 0) {
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1)
            controlMap
                .frame(width: 620)
                .frame(maxHeight: .infinity)
                .background(Color.black.opacity(0.14))
        }
        .foregroundStyle(Color.white.opacity(0.92))
        .background(Color(red: 0.075, green: 0.07, blue: 0.062))
    }

    private var preview: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("JJWW MATERIAL LAB")
                    .font(.system(size: 25, weight: .black, design: .serif))
                Text("Stage 2 · CI gate sheet")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.58))
            }

            MaterialSurfaceView(recipe: recipe) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(profile.displayName.uppercased())
                        .font(.system(size: 26, weight: .bold, design: .serif))
                    Text(profile.id)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .opacity(0.62)
                    Spacer()
                    Text("LIVE MATERIAL PREVIEW")
                        .font(.system(size: 13, weight: .black, design: .serif))
                    Text("This surface is generated from the same deterministic profile data edited by MaterialLabView.")
                        .font(.system(size: 21, design: .serif))
                        .lineSpacing(4)
                    Text("seed \(seed) · marks \(recipe.decorativeMarkCount)")
                        .font(.system(size: 10, design: .monospaced))
                        .opacity(0.52)
                }
                .foregroundStyle(Color.black.opacity(max(0.45, profile.effectiveInk.density)))
                .padding(30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )

            Text("Native sliders/pickers are exercised by the live DEBUG MaterialLabView. This static CI sheet intentionally prints their data contract instead of pretending ImageRenderer captured AppKit controls.")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.50))
        }
        .padding(24)
    }

    private var controlMap: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CONTROL MAP")
                .font(.system(size: 22, weight: .black, design: .serif))
            Text("\(profiles.count) profiles · FULL / REDUCED / CLEAN · deterministic UInt64 seed")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.55))

            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 10) {
                    group("PAPER", [
                        value("warmth", profile.effectivePaperTuning.warmth),
                        value("brightness", profile.effectivePaperTuning.brightness)
                    ])
                    group("MOTLING", [
                        value("amount", profile.mottling.amount),
                        value("scale", profile.mottling.scale),
                        "count  \(profile.mottling.count)"
                    ])
                    group("GRAIN", [
                        value("amount", profile.grain.amount),
                        value("scale", profile.grain.scale),
                        "resolution  \(profile.grain.resolution)"
                    ])
                    group("EDGES", [
                        value("wear", profile.edgeVariation.amount),
                        value("width", profile.edgeVariation.width)
                    ])
                    group("INK", [
                        value("density", profile.effectiveInk.density),
                        value("future bleed", profile.effectiveInk.bleed)
                    ])
                }

                VStack(spacing: 10) {
                    group("FIBERS", [
                        value("density", profile.fibers.density),
                        value("min length", profile.fibers.minLength),
                        value("max length", profile.fibers.maxLength),
                        value("opacity", profile.fibers.opacity),
                        value("width", profile.fibers.width)
                    ])
                    group("FLECKS / FOXING", [
                        value("fleck density", profile.flecks.density),
                        value("fleck opacity", profile.flecks.opacity),
                        value("foxing", profile.foxing.amount),
                        "foxing count  \(profile.foxing.count)"
                    ])
                    group("CLOTH", [
                        "enabled  \(profile.clothWeave.enabled ? "YES" : "NO")",
                        value("vertical", profile.clothWeave.verticalDensity),
                        value("horizontal", profile.clothWeave.horizontalDensity),
                        value("opacity", profile.clothWeave.opacity),
                        value("width", profile.clothWeave.width)
                    ])
                    group("SCAN SLOT", [
                        "asset  \(profile.scanOverlay.assetName ?? "NONE")",
                        value("opacity", profile.scanOverlay.opacity),
                        value("scale", profile.scanOverlay.scale),
                        value("offset X", profile.scanOverlay.offsetX),
                        value("offset Y", profile.scanOverlay.offsetY)
                    ])
                }
            }

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text("EXPORT CONTRACT")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.orange)
                Text("0.2-material-profile · deterministic JSON · full profile round-trip")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.62))
                Text("Stage 2 does not alter historical content and does not apply Ink Awakening yet.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.50))
            }
        }
        .padding(20)
    }

    private func group(_ title: String, _ rows: [String]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(Color.orange)
            ForEach(rows, id: \.self) { row in
                Text(row)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 7))
    }

    private func value(_ label: String, _ number: Double) -> String {
        "\(label)  \(number.formatted(.number.precision(.fractionLength(3))))"
    }
}
#endif
