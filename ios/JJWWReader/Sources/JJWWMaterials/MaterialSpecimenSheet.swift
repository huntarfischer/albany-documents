import SwiftUI

public struct MaterialSpecimenSheet: View {
    public let profiles: [MaterialProfileDefinition]
    public let state: MaterialState
    public let baseSeed: UInt64

    private let engine = MaterialEngine()

    public init(
        profiles: [MaterialProfileDefinition],
        state: MaterialState,
        baseSeed: UInt64 = 0x4A4A57574D41544C
    ) {
        self.profiles = profiles
        self.state = state
        self.baseSeed = baseSeed
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("JJWW MATERIAL ENGINE")
                    .font(.system(size: 28, weight: .black, design: .serif))
                Text("Stage 1 specimen sheet · \(state.rawValue.uppercased())")
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
            }

            Grid(horizontalSpacing: 22, verticalSpacing: 22) {
                ForEach(Array(profiles.enumerated()), id: \.element.id) { index, profile in
                    if index.isMultiple(of: 2) {
                        GridRow {
                            specimen(profile)
                            if profiles.indices.contains(index + 1) {
                                specimen(profiles[index + 1])
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            }
        }
        .padding(32)
        .background(Color(red: 0.08, green: 0.075, blue: 0.065))
    }

    @ViewBuilder
    private func specimen(_ profile: MaterialProfileDefinition) -> some View {
        let seed = MaterialSeed.derive(base: baseSeed, salt: profile.id)
        let recipe = engine.resolve(profile: profile, state: state, seed: seed)

        MaterialSurfaceView(recipe: recipe) {
            VStack(alignment: .leading, spacing: 10) {
                Text(profile.displayName.uppercased())
                    .font(.system(size: 22, weight: .bold, design: .serif))
                Text(profile.id)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .opacity(0.72)
                Spacer()
                Text("MATERIAL SPECIMEN")
                    .font(.system(size: 13, weight: .black, design: .serif))
                Text("Paper should carry atmosphere without carrying the text. Texture is binding, not evidence.")
                    .font(.system(size: 18, design: .serif))
                    .lineSpacing(3)
                Text("seed \(String(seed, radix: 16)) · marks \(recipe.decorativeMarkCount)")
                    .font(.system(size: 10, design: .monospaced))
                    .opacity(0.55)
            }
            .foregroundStyle(Color.black.opacity(0.86))
            .padding(24)
        }
        .frame(width: 520, height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        )
    }
}
