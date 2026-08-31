import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWPagination

#if DEBUG
public struct ReaderLabView: View {
    @Environment(\.dismiss) private var dismiss

    private let profiles: [MaterialProfileDefinition]
    private let edition: Edition?
    private let materialStore: MaterialProfileStore?

    public init(
        profiles: [MaterialProfileDefinition],
        edition: Edition? = nil,
        materialStore: MaterialProfileStore? = nil
    ) {
        self.profiles = profiles
        self.edition = edition
        self.materialStore = materialStore
    }

    public var body: some View {
        TabView {
            if let edition, let materialStore {
                ReaderWorkshopView(edition: edition, materialStore: materialStore)
                    .tabItem { Label("Workshop", systemImage: "slider.horizontal.3") }

                PeriodicalStagingLabView(edition: edition, materialStore: materialStore)
                    .tabItem { Label("Staging", systemImage: "square.stack.3d.up") }
            }

            MaterialLabView(profiles: profiles)
                .tabItem { Label("Material", systemImage: "square.3.layers.3d") }

            InkLabView()
                .tabItem { Label("Ink", systemImage: "drop.fill") }

            PageCompositionLabView()
                .tabItem { Label("Pages", systemImage: "doc.text.image") }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 12) {
                Text("READER LAB")
                    .font(.caption.bold())
                    .tracking(0.7)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Label("Back to Reader", systemImage: "xmark")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("Close Reader Lab and return to the reader")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}
#endif
